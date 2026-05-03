import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../models/recipe.dart';

/// Service for IBM watsonx integration
/// 
/// Provides AI-powered features including:
/// - Natural Language Processing for recipe suggestions
/// - Visual Recognition for product identification
/// - Smart recommendations based on pantry items
class WatsonService {
  final String _apiKey;
  final String _apiUrl;
  final String _modelId;
  final String _visualRecognitionUrl;
  
  // HTTP client for API calls
  final http.Client _client;

  WatsonService({
    required String apiKey,
    required String apiUrl,
    String modelId = 'ibm/granite-13b-chat-v2',
    String? visualRecognitionUrl,
    http.Client? client,
  })  : _apiKey = apiKey,
        _apiUrl = apiUrl,
        _modelId = modelId,
        _visualRecognitionUrl = visualRecognitionUrl ?? 
            'https://api.us-south.visual-recognition.watson.cloud.ibm.com/instances/YOUR_INSTANCE_ID/v4/analyze',
        _client = client ?? http.Client();

  /// Identifies grocery items from an image using IBM watsonx Visual Recognition
  /// 
  /// Sends image as base64 to Watson Visual Recognition API and returns
  /// a list of identified grocery items with confidence scores.
  /// 
  /// [imageBytes] - Image data as bytes (from camera or file)
  /// [threshold] - Minimum confidence threshold (0.0 to 1.0), default 0.5
  /// 
  /// Returns List<Map<String, dynamic>> with format:
  /// ```dart
  /// [
  ///   {
  ///     'name': 'Apple',
  ///     'category': 'Fruit',
  ///     'confidence': 0.95,
  ///     'class': 'food/fruit/apple'
  ///   },
  ///   {
  ///     'name': 'Milk',
  ///     'category': 'Dairy',
  ///     'confidence': 0.87,
  ///     'class': 'food/dairy/milk'
  ///   }
  /// ]
  /// ```
  /// 
  /// Example usage:
  /// ```dart
  /// final watsonService = WatsonService(apiKey: 'your-api-key', apiUrl: 'your-url');
  /// final imageBytes = await File('path/to/image.jpg').readAsBytes();
  /// final items = await watsonService.identifyGroceryItems(imageBytes);
  /// 
  /// for (var item in items) {
  ///   print('${item['name']}: ${(item['confidence'] * 100).toStringAsFixed(1)}%');
  /// }
  /// ```
  Future<List<Map<String, dynamic>>> identifyGroceryItems(
    List<int> imageBytes, {
    double threshold = 0.5,
  }) async {
    try {
      // Convert image bytes to base64
      final base64Image = base64Encode(imageBytes);
      
      // Prepare request body
      final requestBody = {
        'images': [
          {
            'data': base64Image,
          }
        ],
        'features': ['objects', 'food'],
        'threshold': threshold,
      };

      // Make API request
      final response = await _client.post(
        Uri.parse(_visualRecognitionUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return _parseVisualRecognitionResponse(data, threshold);
      } else {
        throw Exception(
          'Watson Visual Recognition API error: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Failed to identify grocery items: $e');
    }
  }

  /// Parses Watson Visual Recognition API response
  /// 
  /// Extracts grocery items with confidence scores from the API response
  List<Map<String, dynamic>> _parseVisualRecognitionResponse(
    Map<String, dynamic> data,
    double threshold,
  ) {
    final List<Map<String, dynamic>> identifiedItems = [];
    
    try {
      // Parse images array from response
      final images = data['images'] as List<dynamic>?;
      if (images == null || images.isEmpty) {
        return identifiedItems;
      }

      final firstImage = images[0] as Map<String, dynamic>;
      
      // Parse objects detected in the image
      final objects = firstImage['objects']?['collections'] as List<dynamic>?;
      if (objects != null) {
        for (var collection in objects) {
          final detectedObjects = collection['objects'] as List<dynamic>?;
          if (detectedObjects != null) {
            for (var obj in detectedObjects) {
              final score = (obj['score'] as num?)?.toDouble() ?? 0.0;
              if (score >= threshold) {
                final className = obj['class'] as String? ?? 'Unknown';
                identifiedItems.add(_createItemFromClass(className, score));
              }
            }
          }
        }
      }

      // Parse food items if available
      final food = firstImage['food'] as Map<String, dynamic>?;
      if (food != null) {
        final foodItems = food['items'] as List<dynamic>?;
        if (foodItems != null) {
          for (var item in foodItems) {
            final score = (item['score'] as num?)?.toDouble() ?? 0.0;
            if (score >= threshold) {
              final foodName = item['name'] as String? ?? 'Unknown';
              identifiedItems.add({
                'name': _formatItemName(foodName),
                'category': _categorizeFood(foodName),
                'confidence': score,
                'class': 'food/$foodName',
              });
            }
          }
        }
      }

      // Remove duplicates and sort by confidence
      final uniqueItems = _removeDuplicates(identifiedItems);
      uniqueItems.sort((a, b) => 
        (b['confidence'] as double).compareTo(a['confidence'] as double)
      );

      return uniqueItems;
    } catch (e) {
      throw Exception('Failed to parse Visual Recognition response: $e');
    }
  }

  /// Creates an item map from Watson class name
  Map<String, dynamic> _createItemFromClass(String className, double score) {
    final parts = className.split('/');
    final itemName = parts.isNotEmpty ? parts.last : className;
    
    return {
      'name': _formatItemName(itemName),
      'category': _categorizeFromClass(className),
      'confidence': score,
      'class': className,
    };
  }

  /// Formats item name for display (capitalize, remove underscores)
  String _formatItemName(String name) {
    return name
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isEmpty ? '' : 
            word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }

  /// Categorizes food item based on name
  String _categorizeFood(String foodName) {
    final name = foodName.toLowerCase();
    
    if (name.contains('fruit') || name.contains('apple') || 
        name.contains('banana') || name.contains('orange')) {
      return 'Fruit';
    } else if (name.contains('vegetable') || name.contains('carrot') || 
               name.contains('tomato') || name.contains('lettuce')) {
      return 'Vegetable';
    } else if (name.contains('milk') || name.contains('cheese') || 
               name.contains('yogurt') || name.contains('dairy')) {
      return 'Dairy';
    } else if (name.contains('meat') || name.contains('chicken') || 
               name.contains('beef') || name.contains('pork')) {
      return 'Meat';
    } else if (name.contains('bread') || name.contains('pasta') || 
               name.contains('rice') || name.contains('grain')) {
      return 'Grain';
    } else if (name.contains('beverage') || name.contains('drink') || 
               name.contains('juice') || name.contains('soda')) {
      return 'Beverage';
    } else {
      return 'Other';
    }
  }

  /// Categorizes item from Watson class path
  String _categorizeFromClass(String className) {
    if (className.contains('fruit')) return 'Fruit';
    if (className.contains('vegetable')) return 'Vegetable';
    if (className.contains('dairy')) return 'Dairy';
    if (className.contains('meat')) return 'Meat';
    if (className.contains('grain') || className.contains('bread')) return 'Grain';
    if (className.contains('beverage')) return 'Beverage';
    return 'Other';
  }

  /// Removes duplicate items based on name
  List<Map<String, dynamic>> _removeDuplicates(List<Map<String, dynamic>> items) {
    final seen = <String>{};
    final unique = <Map<String, dynamic>>[];
    
    for (var item in items) {
      final name = item['name'] as String;
      if (!seen.contains(name)) {
        seen.add(name);
        unique.add(item);
      }
    }
    
    return unique;
  }

  /// Identifies a single product from an image (legacy method)
  /// 
  /// [imageBytes] - Image data as bytes
  /// Returns product name and category
  Future<Map<String, String>> identifyProduct(List<int> imageBytes) async {
    final items = await identifyGroceryItems(imageBytes);
    
    if (items.isEmpty) {
      return {'name': 'Unknown', 'category': 'Other'};
    }
    
    final topItem = items.first;
    return {
      'name': topItem['name'] as String,
      'category': topItem['category'] as String,
    };
  }

  /// Suggests recipes based on available ingredients
  /// 
  /// Uses IBM watsonx NLP to generate recipe suggestions
  /// prioritizing ingredients that are expiring soon.
  /// 
  /// [ingredients] - List of available ingredient names
  /// [expiringIngredients] - List of ingredients expiring soon (optional)
  /// Returns a list of suggested recipes
  Future<List<Recipe>> suggestRecipes({
    required List<String> ingredients,
    List<String>? expiringIngredients,
  }) async {
    // TODO: Implement IBM watsonx NLP API call for recipe suggestions
    // Example implementation:
    // 1. Build prompt with ingredients
    // 2. Call watsonx text generation API
    // 3. Parse response into Recipe objects
    // 4. Return list of recipes
    
    throw UnimplementedError('Watson recipe suggestion not yet implemented');
  }

  /// Generates smart shopping list suggestions
  /// 
  /// Uses NLP to analyze pantry inventory and suggest items to buy
  /// based on usage patterns and preferences.
  /// 
  /// [currentInventory] - List of current pantry items
  /// [recentPurchases] - List of recently purchased items (optional)
  /// Returns list of suggested items to purchase
  Future<List<String>> generateShoppingListSuggestions({
    required List<String> currentInventory,
    List<String>? recentPurchases,
  }) async {
    // TODO: Implement shopping list suggestion logic
    throw UnimplementedError('Shopping list suggestions not yet implemented');
  }

  /// Analyzes text from OCR to extract product information
  /// 
  /// [ocrText] - Raw text extracted from product label
  /// Returns structured product information
  Future<Map<String, dynamic>> parseProductLabel(String ocrText) async {
    // TODO: Implement NLP parsing of product labels
    throw UnimplementedError('Product label parsing not yet implemented');
  }

  /// Gets recipe recommendations based on dietary preferences
  /// 
  /// [ingredients] - Available ingredients
  /// [dietaryRestrictions] - List of dietary restrictions
  /// [allergens] - List of allergens to avoid
  /// Returns filtered recipe suggestions
  Future<List<Recipe>> getPersonalizedRecipes({
    required List<String> ingredients,
    List<String>? dietaryRestrictions,
    List<String>? allergens,
  }) async {
    // TODO: Implement personalized recipe recommendations
    throw UnimplementedError('Personalized recipes not yet implemented');
  }

  /// Estimates expiry date from product information
  /// 
  /// [productName] - Name of the product
  /// [category] - Product category
  /// Returns estimated days until expiry
  Future<int> estimateExpiryDays({
    required String productName,
    required String category,
  }) async {
    // TODO: Implement expiry estimation using watsonx
    throw UnimplementedError('Expiry estimation not yet implemented');
  }

  /// Validates API connection and credentials
  Future<bool> validateConnection() async {
    try {
      // Make a simple test call to verify credentials
      final testImage = Uint8List(100); // Small test image
      await identifyGroceryItems(testImage.toList(), threshold: 0.9);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Disposes resources
  void dispose() {
    _client.close();
  }
}

/// Model for identified grocery item with confidence score
class IdentifiedGroceryItem {
  final String name;
  final String category;
  final double confidence;
  final String className;

  const IdentifiedGroceryItem({
    required this.name,
    required this.category,
    required this.confidence,
    required this.className,
  });

  factory IdentifiedGroceryItem.fromMap(Map<String, dynamic> map) {
    return IdentifiedGroceryItem(
      name: map['name'] as String,
      category: map['category'] as String,
      confidence: map['confidence'] as double,
      className: map['class'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'confidence': confidence,
      'class': className,
    };
  }

  @override
  String toString() {
    return 'IdentifiedGroceryItem(name: $name, category: $category, confidence: ${(confidence * 100).toStringAsFixed(1)}%)';
  }
}

// Made with Bob
