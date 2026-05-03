import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/recipe.dart';
import '../models/grocery_item.dart';
import '../models/nutrition.dart';

/// Service for Spoonacular Recipe API integration
/// 
/// Provides access to a large database of recipes with features including:
/// - Recipe search by ingredients
/// - Recipe details and instructions
/// - Nutritional information
/// - Dietary filtering
/// - Expiry-aware recipe recommendations
class RecipeApiService {
  final String _apiKey;
  final String _baseUrl;
  final http.Client _client;

  RecipeApiService({
    required String apiKey,
    String? baseUrl,
    http.Client? client,
  })  : _apiKey = apiKey,
        _baseUrl = baseUrl ?? 'https://api.spoonacular.com',
        _client = client ?? http.Client();

  /// Finds recipes prioritizing ingredients that are about to expire
  /// 
  /// Takes a list of pantry items with expiry dates, sorts them by soonest expiry,
  /// calls Spoonacular API to find recipes, and returns recipes sorted by how many
  /// 'about to expire' ingredients they use.
  /// 
  /// [pantryItems] - List of GroceryItem objects with expiry dates
  /// [expiryThresholdDays] - Days threshold for "about to expire" (default: 7)
  /// [maxRecipes] - Maximum number of recipes to return (default: 20)
  /// 
  /// Returns List<RecipeWithExpiryScore> sorted by:
  /// 1. Number of expiring ingredients used (descending)
  /// 2. Percentage of expiring ingredients used (descending)
  /// 3. Total ingredients matched (descending)
  /// 
  /// Example usage:
  /// ```dart
  /// final recipeService = RecipeApiService(apiKey: 'your-key');
  /// final pantryItems = [
  ///   GroceryItem(name: 'Milk', expiryDate: DateTime.now().add(Duration(days: 2))),
  ///   GroceryItem(name: 'Eggs', expiryDate: DateTime.now().add(Duration(days: 3))),
  ///   GroceryItem(name: 'Cheese', expiryDate: DateTime.now().add(Duration(days: 10))),
  /// ];
  /// 
  /// final recipes = await recipeService.findRecipesByExpiringIngredients(pantryItems);
  /// 
  /// for (var recipe in recipes) {
  ///   print('${recipe.recipe.title}');
  ///   print('  Uses ${recipe.expiringIngredientsCount} expiring ingredients');
  ///   print('  Expiring: ${recipe.expiringIngredientsUsed.join(", ")}');
  /// }
  /// ```
  Future<List<RecipeWithExpiryScore>> findRecipesByExpiringIngredients(
    List<GroceryItem> pantryItems, {
    int expiryThresholdDays = 7,
    int maxRecipes = 20,
  }) async {
    try {
      // Step 1: Sort pantry items by expiry date (soonest first)
      final sortedItems = List<GroceryItem>.from(pantryItems)
        ..sort((a, b) => a.expiryDate.compareTo(b.expiryDate));

      // Step 2: Identify items about to expire
      final now = DateTime.now();
      final expiryThreshold = now.add(Duration(days: expiryThresholdDays));
      
      final expiringItems = sortedItems
          .where((item) => 
              item.expiryDate.isBefore(expiryThreshold) && 
              item.expiryDate.isAfter(now))
          .toList();

      final allIngredientNames = sortedItems.map((item) => item.name).toList();
      final expiringIngredientNames = expiringItems.map((item) => item.name).toList();

      if (allIngredientNames.isEmpty) {
        return [];
      }

      // Step 3: Call Spoonacular API to find recipes by ingredients
      final recipes = await searchByIngredients(
        ingredients: allIngredientNames,
        number: maxRecipes,
        ranking: 1, // Maximize used ingredients
      );

      // Step 4: Score each recipe based on expiring ingredients usage
      final recipesWithScores = <RecipeWithExpiryScore>[];
      
      for (var recipe in recipes) {
        final score = _calculateExpiryScore(
          recipe,
          expiringIngredientNames,
          allIngredientNames,
        );
        recipesWithScores.add(score);
      }

      // Step 5: Sort recipes by expiry score
      recipesWithScores.sort((a, b) {
        // Primary: Number of expiring ingredients used (descending)
        final expiringCompare = b.expiringIngredientsCount.compareTo(a.expiringIngredientsCount);
        if (expiringCompare != 0) return expiringCompare;

        // Secondary: Percentage of expiring ingredients (descending)
        final percentageCompare = b.expiringIngredientsPercentage.compareTo(a.expiringIngredientsPercentage);
        if (percentageCompare != 0) return percentageCompare;

        // Tertiary: Total matched ingredients (descending)
        return b.totalMatchedIngredients.compareTo(a.totalMatchedIngredients);
      });

      return recipesWithScores;
    } catch (e) {
      throw Exception('Failed to find recipes by expiring ingredients: $e');
    }
  }

  /// Calculates expiry score for a recipe
  RecipeWithExpiryScore _calculateExpiryScore(
    Recipe recipe,
    List<String> expiringIngredients,
    List<String> allAvailableIngredients,
  ) {
    final recipeIngredients = recipe.ingredients.map((i) => i.toLowerCase()).toList();
    
    // Find which expiring ingredients are used in this recipe
    final expiringUsed = <String>[];
    for (var expiring in expiringIngredients) {
      if (_ingredientMatchesAny(expiring, recipeIngredients)) {
        expiringUsed.add(expiring);
      }
    }

    // Find total matched ingredients
    final totalMatched = allAvailableIngredients
        .where((ingredient) => _ingredientMatchesAny(ingredient, recipeIngredients))
        .length;

    // Calculate percentage
    final percentage = expiringIngredients.isEmpty
        ? 0.0
        : (expiringUsed.length / expiringIngredients.length) * 100;

    return RecipeWithExpiryScore(
      recipe: recipe,
      expiringIngredientsUsed: expiringUsed,
      expiringIngredientsCount: expiringUsed.length,
      expiringIngredientsPercentage: percentage,
      totalMatchedIngredients: totalMatched,
      totalAvailableIngredients: allAvailableIngredients.length,
    );
  }

  /// Checks if an ingredient matches any in the recipe ingredients list
  bool _ingredientMatchesAny(String ingredient, List<String> recipeIngredients) {
    final ingredientLower = ingredient.toLowerCase();
    return recipeIngredients.any((recipeIng) =>
        recipeIng.contains(ingredientLower) || ingredientLower.contains(recipeIng));
  }

  /// Searches for recipes by ingredients
  /// 
  /// [ingredients] - List of ingredients to search with
  /// [number] - Number of results to return (default: 10)
  /// [ranking] - Ranking strategy: 1 (maximize used ingredients) or 2 (minimize missing ingredients)
  /// Returns list of matching recipes
  Future<List<Recipe>> searchByIngredients({
    required List<String> ingredients,
    int number = 10,
    int ranking = 1,
  }) async {
    try {
      final ingredientsParam = ingredients.join(',+');
      final url = Uri.parse(
        '$_baseUrl/recipes/findByIngredients?ingredients=$ingredientsParam&number=$number&ranking=$ranking&apiKey=$_apiKey',
      );

      final response = await _client.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final recipes = <Recipe>[];

        for (var item in data) {
          // Get detailed recipe information
          final recipeId = item['id'].toString();
          final detailedRecipe = await getRecipeDetails(
            recipeId: recipeId,
            includeNutrition: true,
          );
          recipes.add(detailedRecipe);
        }

        return recipes;
      } else {
        throw Exception('Spoonacular API error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to search recipes by ingredients: $e');
    }
  }

  /// Gets detailed recipe information
  /// 
  /// [recipeId] - The Spoonacular recipe ID
  /// [includeNutrition] - Whether to include nutritional information
  /// Returns complete recipe details
  Future<Recipe> getRecipeDetails({
    required String recipeId,
    bool includeNutrition = true,
  }) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/recipes/$recipeId/information?includeNutrition=$includeNutrition&apiKey=$_apiKey',
      );

      final response = await _client.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return _parseRecipeFromSpoonacular(data);
      } else {
        throw Exception('Spoonacular API error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to get recipe details: $e');
    }
  }

  /// Parses Spoonacular API response into Recipe model
  Recipe _parseRecipeFromSpoonacular(Map<String, dynamic> data) {
    // Extract ingredients
    final extendedIngredients = data['extendedIngredients'] as List<dynamic>? ?? [];
    final ingredients = extendedIngredients
        .map((ing) => ing['original'] as String? ?? '')
        .where((ing) => ing.isNotEmpty)
        .toList();

    // Extract instructions
    final analyzedInstructions = data['analyzedInstructions'] as List<dynamic>? ?? [];
    final instructions = <String>[];
    if (analyzedInstructions.isNotEmpty) {
      final steps = analyzedInstructions[0]['steps'] as List<dynamic>? ?? [];
      for (var step in steps) {
        instructions.add(step['step'] as String? ?? '');
      }
    }

    // Extract nutrition
    Nutrition? nutrition;
    if (data['nutrition'] != null) {
      final nutritionData = data['nutrition'] as Map<String, dynamic>;
      final nutrients = nutritionData['nutrients'] as List<dynamic>? ?? [];
      
      double getNutrientAmount(String name) {
        final nutrient = nutrients.firstWhere(
          (n) => (n['name'] as String).toLowerCase() == name.toLowerCase(),
          orElse: () => {'amount': 0.0},
        );
        return (nutrient['amount'] as num?)?.toDouble() ?? 0.0;
      }

      nutrition = Nutrition(
        calories: getNutrientAmount('Calories'),
        protein: getNutrientAmount('Protein'),
        carbohydrates: getNutrientAmount('Carbohydrates'),
        fat: getNutrientAmount('Fat'),
        fiber: getNutrientAmount('Fiber'),
        sugar: getNutrientAmount('Sugar'),
        sodium: getNutrientAmount('Sodium'),
        cholesterol: getNutrientAmount('Cholesterol'),
      );
    }

    // Extract tags
    final dishTypes = data['dishTypes'] as List<dynamic>? ?? [];
    final diets = data['diets'] as List<dynamic>? ?? [];
    final tags = [...dishTypes, ...diets].map((t) => t.toString()).toList();

    return Recipe(
      id: data['id'].toString(),
      title: data['title'] as String? ?? 'Unknown Recipe',
      description: data['summary'] as String? ?? '',
      ingredients: ingredients,
      instructions: instructions,
      prepTime: data['preparationMinutes'] as int? ?? 0,
      cookTime: data['cookingMinutes'] as int? ?? 0,
      servings: data['servings'] as int? ?? 1,
      imageUrl: data['image'] as String?,
      nutrition: nutrition,
      tags: tags,
      rating: data['spoonacularScore'] != null 
          ? (data['spoonacularScore'] as num).toDouble() / 20 // Convert to 5-star scale
          : null,
    );
  }

  /// Searches recipes by query string
  Future<List<Recipe>> searchRecipes({
    required String query,
    String? cuisine,
    String? diet,
    List<String>? intolerances,
    int number = 10,
  }) async {
    // TODO: Implement complex search
    throw UnimplementedError('Search recipes not yet implemented');
  }

  /// Gets random recipes
  Future<List<Recipe>> getRandomRecipes({
    int number = 10,
    List<String>? tags,
  }) async {
    // TODO: Implement random recipes
    throw UnimplementedError('Get random recipes not yet implemented');
  }

  /// Gets similar recipes
  Future<List<Recipe>> getSimilarRecipes({
    required String recipeId,
    int number = 10,
  }) async {
    // TODO: Implement similar recipes
    throw UnimplementedError('Get similar recipes not yet implemented');
  }

  /// Validates API key and connection
  Future<bool> validateApiKey() async {
    try {
      await searchByIngredients(ingredients: ['chicken'], number: 1);
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

/// Model representing a recipe with expiry-based scoring
/// 
/// Used to rank recipes based on how many expiring ingredients they use
class RecipeWithExpiryScore {
  final Recipe recipe;
  final List<String> expiringIngredientsUsed;
  final int expiringIngredientsCount;
  final double expiringIngredientsPercentage;
  final int totalMatchedIngredients;
  final int totalAvailableIngredients;

  const RecipeWithExpiryScore({
    required this.recipe,
    required this.expiringIngredientsUsed,
    required this.expiringIngredientsCount,
    required this.expiringIngredientsPercentage,
    required this.totalMatchedIngredients,
    required this.totalAvailableIngredients,
  });

  /// Gets a priority score (higher is better)
  double get priorityScore {
    return (expiringIngredientsCount * 100) + 
           expiringIngredientsPercentage + 
           (totalMatchedIngredients * 0.5);
  }

  @override
  String toString() {
    return 'RecipeWithExpiryScore('
        'recipe: ${recipe.title}, '
        'expiringUsed: $expiringIngredientsCount, '
        'percentage: ${expiringIngredientsPercentage.toStringAsFixed(1)}%, '
        'totalMatched: $totalMatchedIngredients'
        ')';
  }
}

// Made with Bob
