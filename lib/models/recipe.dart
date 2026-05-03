import 'nutrition.dart';

/// Model representing a recipe
/// 
/// Contains recipe information including ingredients, instructions,
/// cooking times, and nutritional information.
class Recipe {
  final String id;
  final String title;
  final String description;
  final List<String> ingredients;
  final List<String> instructions;
  final int prepTime; // in minutes
  final int cookTime; // in minutes
  final int servings;
  final String? imageUrl;
  final Nutrition? nutrition;
  final List<String> tags;
  final double? rating;
  final bool isFavorite;

  const Recipe({
    required this.id,
    required this.title,
    required this.description,
    required this.ingredients,
    required this.instructions,
    required this.prepTime,
    required this.cookTime,
    required this.servings,
    this.imageUrl,
    this.nutrition,
    this.tags = const [],
    this.rating,
    this.isFavorite = false,
  });

  /// Creates a Recipe from JSON data
  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      ingredients: (json['ingredients'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      instructions: (json['instructions'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      prepTime: json['prepTime'] as int,
      cookTime: json['cookTime'] as int,
      servings: json['servings'] as int,
      imageUrl: json['imageUrl'] as String?,
      nutrition: json['nutrition'] != null
          ? Nutrition.fromJson(json['nutrition'] as Map<String, dynamic>)
          : null,
      tags: json['tags'] != null
          ? (json['tags'] as List<dynamic>).map((e) => e as String).toList()
          : [],
      rating: json['rating'] != null ? (json['rating'] as num).toDouble() : null,
      isFavorite: json['isFavorite'] as bool? ?? false,
    );
  }

  /// Converts the Recipe to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'ingredients': ingredients,
      'instructions': instructions,
      'prepTime': prepTime,
      'cookTime': cookTime,
      'servings': servings,
      'imageUrl': imageUrl,
      'nutrition': nutrition?.toJson(),
      'tags': tags,
      'rating': rating,
      'isFavorite': isFavorite,
    };
  }

  /// Creates a copy of this Recipe with updated fields
  Recipe copyWith({
    String? id,
    String? title,
    String? description,
    List<String>? ingredients,
    List<String>? instructions,
    int? prepTime,
    int? cookTime,
    int? servings,
    String? imageUrl,
    Nutrition? nutrition,
    List<String>? tags,
    double? rating,
    bool? isFavorite,
  }) {
    return Recipe(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      ingredients: ingredients ?? this.ingredients,
      instructions: instructions ?? this.instructions,
      prepTime: prepTime ?? this.prepTime,
      cookTime: cookTime ?? this.cookTime,
      servings: servings ?? this.servings,
      imageUrl: imageUrl ?? this.imageUrl,
      nutrition: nutrition ?? this.nutrition,
      tags: tags ?? this.tags,
      rating: rating ?? this.rating,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  /// Gets the total cooking time (prep + cook)
  int get totalTime => prepTime + cookTime;

  /// Checks if the recipe matches a dietary tag
  bool hasDietaryTag(String tag) {
    return tags.any((t) => t.toLowerCase() == tag.toLowerCase());
  }

  @override
  String toString() {
    return 'Recipe(id: $id, title: $title, servings: $servings, totalTime: ${totalTime}min)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Recipe && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// Made with Bob
