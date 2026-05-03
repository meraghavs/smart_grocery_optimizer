/// Model representing nutritional information
/// 
/// Contains detailed nutritional data for recipes or grocery items.
class Nutrition {
  final double calories;
  final double protein; // in grams
  final double carbohydrates; // in grams
  final double fat; // in grams
  final double fiber; // in grams
  final double sugar; // in grams
  final double sodium; // in milligrams
  final double cholesterol; // in milligrams
  final Map<String, double>? vitamins; // vitamin name -> amount
  final Map<String, double>? minerals; // mineral name -> amount

  const Nutrition({
    required this.calories,
    required this.protein,
    required this.carbohydrates,
    required this.fat,
    this.fiber = 0,
    this.sugar = 0,
    this.sodium = 0,
    this.cholesterol = 0,
    this.vitamins,
    this.minerals,
  });

  /// Creates a Nutrition object from JSON data
  factory Nutrition.fromJson(Map<String, dynamic> json) {
    return Nutrition(
      calories: (json['calories'] as num).toDouble(),
      protein: (json['protein'] as num).toDouble(),
      carbohydrates: (json['carbohydrates'] as num).toDouble(),
      fat: (json['fat'] as num).toDouble(),
      fiber: json['fiber'] != null ? (json['fiber'] as num).toDouble() : 0,
      sugar: json['sugar'] != null ? (json['sugar'] as num).toDouble() : 0,
      sodium: json['sodium'] != null ? (json['sodium'] as num).toDouble() : 0,
      cholesterol: json['cholesterol'] != null 
          ? (json['cholesterol'] as num).toDouble() 
          : 0,
      vitamins: json['vitamins'] != null
          ? (json['vitamins'] as Map<String, dynamic>).map(
              (key, value) => MapEntry(key, (value as num).toDouble()),
            )
          : null,
      minerals: json['minerals'] != null
          ? (json['minerals'] as Map<String, dynamic>).map(
              (key, value) => MapEntry(key, (value as num).toDouble()),
            )
          : null,
    );
  }

  /// Converts the Nutrition object to JSON
  Map<String, dynamic> toJson() {
    return {
      'calories': calories,
      'protein': protein,
      'carbohydrates': carbohydrates,
      'fat': fat,
      'fiber': fiber,
      'sugar': sugar,
      'sodium': sodium,
      'cholesterol': cholesterol,
      'vitamins': vitamins,
      'minerals': minerals,
    };
  }

  /// Creates a copy of this Nutrition with updated fields
  Nutrition copyWith({
    double? calories,
    double? protein,
    double? carbohydrates,
    double? fat,
    double? fiber,
    double? sugar,
    double? sodium,
    double? cholesterol,
    Map<String, double>? vitamins,
    Map<String, double>? minerals,
  }) {
    return Nutrition(
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbohydrates: carbohydrates ?? this.carbohydrates,
      fat: fat ?? this.fat,
      fiber: fiber ?? this.fiber,
      sugar: sugar ?? this.sugar,
      sodium: sodium ?? this.sodium,
      cholesterol: cholesterol ?? this.cholesterol,
      vitamins: vitamins ?? this.vitamins,
      minerals: minerals ?? this.minerals,
    );
  }

  /// Calculates the percentage of daily value for a nutrient
  /// Based on a 2000 calorie diet
  double getDailyValuePercentage(String nutrient) {
    switch (nutrient.toLowerCase()) {
      case 'protein':
        return (protein / 50) * 100; // 50g daily value
      case 'carbohydrates':
        return (carbohydrates / 300) * 100; // 300g daily value
      case 'fat':
        return (fat / 65) * 100; // 65g daily value
      case 'fiber':
        return (fiber / 25) * 100; // 25g daily value
      case 'sodium':
        return (sodium / 2300) * 100; // 2300mg daily value
      default:
        return 0;
    }
  }

  @override
  String toString() {
    return 'Nutrition(calories: $calories, protein: ${protein}g, carbs: ${carbohydrates}g, fat: ${fat}g)';
  }
}

// Made with Bob
