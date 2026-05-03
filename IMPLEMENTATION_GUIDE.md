# Smart Grocery Optimizer - Implementation Guide

## Table of Contents
1. [Data Flow & State Management](#data-flow--state-management)
2. [Adding New Features](#adding-new-features)
3. [Naming Conventions](#naming-conventions)
4. [Code Examples](#code-examples)
5. [Best Practices](#best-practices)

---

## Data Flow & State Management

### Riverpod State Management Strategy

#### Provider Types and Usage

```dart
// 1. Provider - For immutable values and services
final firebaseServiceProvider = Provider<FirebaseService>((ref) {
  return FirebaseService();
});

// 2. StateProvider - For simple mutable state
final selectedCategoryProvider = StateProvider<String>((ref) => 'All');

// 3. FutureProvider - For async data fetching
final pantryItemsProvider = FutureProvider<List<GroceryItem>>((ref) async {
  final service = ref.watch(firebaseServiceProvider);
  return await service.getPantryItems();
});

// 4. StreamProvider - For real-time data streams
final pantryStreamProvider = StreamProvider<List<GroceryItem>>((ref) {
  final service = ref.watch(firebaseServiceProvider);
  return service.watchPantryItems();
});

// 5. StateNotifierProvider - For complex state management
final pantryNotifierProvider = 
    StateNotifierProvider<PantryNotifier, List<GroceryItem>>((ref) {
  final service = ref.watch(firebaseServiceProvider);
  return PantryNotifier(service);
});
```

### Data Flow Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    UI Layer (Screens/Widgets)                │
│  - Consumes state via ref.watch()                            │
│  - Triggers actions via ref.read().method()                  │
└─────────────────────────────────────────────────────────────┘
                              ↓↑
┌─────────────────────────────────────────────────────────────┐
│                State Management (Providers)                  │
│  - Manages application state                                 │
│  - Notifies UI of changes                                    │
└─────────────────────────────────────────────────────────────┘
                              ↓↑
┌─────────────────────────────────────────────────────────────┐
│                   Service Layer (Services)                   │
│  - Business logic                                            │
│  - API calls and data operations                             │
└─────────────────────────────────────────────────────────────┘
                              ↓↑
┌─────────────────────────────────────────────────────────────┐
│                    Data Layer (Models)                       │
│  - Data structures                                           │
│  - JSON serialization                                        │
└─────────────────────────────────────────────────────────────┘
                              ↓↑
┌─────────────────────────────────────────────────────────────┐
│                   External Services                          │
│         (Firebase, IBM watsonx, APIs)                        │
└─────────────────────────────────────────────────────────────┘
```

### Complete Example: Adding Pantry Item

```dart
// 1. MODEL (lib/models/grocery_item.dart)
@freezed
class GroceryItem with _$GroceryItem {
  const factory GroceryItem({
    required String id,
    required String name,
    required String category,
    required int quantity,
    required String unit,
    required DateTime expiryDate,
    DateTime? purchaseDate,
    double? price,
    String? imageUrl,
    String? barcode,
  }) = _GroceryItem;
  
  factory GroceryItem.fromJson(Map<String, dynamic> json) =>
      _$GroceryItemFromJson(json);
}

// 2. SERVICE (lib/services/firebase_service.dart)
class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  Future<void> addPantryItem(GroceryItem item) async {
    await _firestore
        .collection('pantry_items')
        .doc(item.id)
        .set(item.toJson());
  }
  
  Future<List<GroceryItem>> getPantryItems() async {
    final snapshot = await _firestore.collection('pantry_items').get();
    return snapshot.docs
        .map((doc) => GroceryItem.fromJson(doc.data()))
        .toList();
  }
  
  Stream<List<GroceryItem>> watchPantryItems() {
    return _firestore.collection('pantry_items').snapshots().map(
      (snapshot) => snapshot.docs
          .map((doc) => GroceryItem.fromJson(doc.data()))
          .toList(),
    );
  }
  
  Future<void> deletePantryItem(String id) async {
    await _firestore.collection('pantry_items').doc(id).delete();
  }
}

// 3. PROVIDER (lib/state/pantry_provider.dart)
class PantryNotifier extends StateNotifier<AsyncValue<List<GroceryItem>>> {
  final FirebaseService _firebaseService;
  
  PantryNotifier(this._firebaseService) : super(const AsyncValue.loading()) {
    loadItems();
  }
  
  Future<void> loadItems() async {
    state = const AsyncValue.loading();
    try {
      final items = await _firebaseService.getPantryItems();
      state = AsyncValue.data(items);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
  
  Future<void> addItem(GroceryItem item) async {
    try {
      await _firebaseService.addPantryItem(item);
      await loadItems(); // Refresh list
    } catch (error) {
      // Handle error
      print('Error adding item: $error');
    }
  }
  
  Future<void> deleteItem(String id) async {
    try {
      await _firebaseService.deletePantryItem(id);
      await loadItems(); // Refresh list
    } catch (error) {
      print('Error deleting item: $error');
    }
  }
}

final pantryProvider = StateNotifierProvider<PantryNotifier, AsyncValue<List<GroceryItem>>>((ref) {
  final firebaseService = ref.watch(firebaseServiceProvider);
  return PantryNotifier(firebaseService);
});

// 4. SCREEN (lib/screens/pantry_screen.dart)
class PantryScreen extends ConsumerWidget {
  const PantryScreen({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pantryState = ref.watch(pantryProvider);
    
    return Scaffold(
      appBar: AppBar(title: const Text('My Pantry')),
      body: pantryState.when(
        data: (items) => items.isEmpty
            ? const EmptyState(message: 'No items in pantry')
            : ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  return GroceryItemCard(
                    item: items[index],
                    onDelete: () {
                      ref.read(pantryProvider.notifier).deleteItem(items[index].id);
                    },
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddItemDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }
  
  void _showAddItemDialog(BuildContext context, WidgetRef ref) {
    // Show dialog to add new item
    showDialog(
      context: context,
      builder: (context) => AddItemDialog(
        onAdd: (item) {
          ref.read(pantryProvider.notifier).addItem(item);
          Navigator.pop(context);
        },
      ),
    );
  }
}

// 5. WIDGET (lib/widgets/grocery_item_card.dart)
class GroceryItemCard extends StatelessWidget {
  final GroceryItem item;
  final VoidCallback onDelete;
  
  const GroceryItemCard({
    Key? key,
    required this.item,
    required this.onDelete,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: item.imageUrl != null
            ? CachedNetworkImage(imageUrl: item.imageUrl!)
            : const Icon(Icons.shopping_basket),
        title: Text(item.name),
        subtitle: Text('Expires: ${DateHelpers.formatDate(item.expiryDate)}'),
        trailing: IconButton(
          icon: const Icon(Icons.delete),
          onPressed: onDelete,
        ),
      ),
    );
  }
}
```

---

## Adding New Features

### Step-by-Step Guide

#### Example: Adding a "Meal Planner" Feature

**Step 1: Create the Model**

```dart
// lib/models/meal_plan.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'recipe.dart';

part 'meal_plan.freezed.dart';
part 'meal_plan.g.dart';

@freezed
class MealPlan with _$MealPlan {
  const factory MealPlan({
    required String id,
    required DateTime date,
    required List<Recipe> meals,
    String? notes,
  }) = _MealPlan;
  
  factory MealPlan.fromJson(Map<String, dynamic> json) =>
      _$MealPlanFromJson(json);
}
```

**Step 2: Create the Service**

```dart
// lib/services/meal_plan_service.dart
import '../models/meal_plan.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MealPlanService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  Future<void> saveMealPlan(MealPlan plan) async {
    await _firestore
        .collection('meal_plans')
        .doc(plan.id)
        .set(plan.toJson());
  }
  
  Future<List<MealPlan>> getMealPlans() async {
    final snapshot = await _firestore.collection('meal_plans').get();
    return snapshot.docs
        .map((doc) => MealPlan.fromJson(doc.data()))
        .toList();
  }
  
  Future<void> deleteMealPlan(String id) async {
    await _firestore.collection('meal_plans').doc(id).delete();
  }
}
```

**Step 3: Create the Provider**

```dart
// lib/state/meal_plan_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/meal_plan.dart';
import '../services/meal_plan_service.dart';

final mealPlanServiceProvider = Provider<MealPlanService>((ref) {
  return MealPlanService();
});

final mealPlansProvider = FutureProvider<List<MealPlan>>((ref) async {
  final service = ref.watch(mealPlanServiceProvider);
  return await service.getMealPlans();
});

class MealPlanNotifier extends StateNotifier<AsyncValue<List<MealPlan>>> {
  final MealPlanService _service;
  
  MealPlanNotifier(this._service) : super(const AsyncValue.loading()) {
    loadPlans();
  }
  
  Future<void> loadPlans() async {
    state = const AsyncValue.loading();
    try {
      final plans = await _service.getMealPlans();
      state = AsyncValue.data(plans);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
  
  Future<void> addPlan(MealPlan plan) async {
    await _service.saveMealPlan(plan);
    await loadPlans();
  }
}

final mealPlanNotifierProvider = 
    StateNotifierProvider<MealPlanNotifier, AsyncValue<List<MealPlan>>>((ref) {
  final service = ref.watch(mealPlanServiceProvider);
  return MealPlanNotifier(service);
});
```

**Step 4: Create the Screen**

```dart
// lib/screens/meal_plan_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/meal_plan_provider.dart';
import '../widgets/meal_plan_card.dart';

class MealPlanScreen extends ConsumerWidget {
  const MealPlanScreen({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plansState = ref.watch(mealPlanNotifierProvider);
    
    return Scaffold(
      appBar: AppBar(title: const Text('Meal Planner')),
      body: plansState.when(
        data: (plans) => ListView.builder(
          itemCount: plans.length,
          itemBuilder: (context, index) {
            return MealPlanCard(plan: plans[index]);
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddPlan(context),
        child: const Icon(Icons.add),
      ),
    );
  }
  
  void _navigateToAddPlan(BuildContext context) {
    // Navigate to add meal plan screen
  }
}
```

**Step 5: Create the Widget**

```dart
// lib/widgets/meal_plan_card.dart
import 'package:flutter/material.dart';
import '../models/meal_plan.dart';
import '../utils/date_helpers.dart';

class MealPlanCard extends StatelessWidget {
  final MealPlan plan;
  
  const MealPlanCard({Key? key, required this.plan}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateHelpers.formatDate(plan.date),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            ...plan.meals.map((meal) => Text('• ${meal.title}')),
            if (plan.notes != null) ...[
              const SizedBox(height: 8),
              Text(plan.notes!, style: const TextStyle(fontStyle: FontStyle.italic)),
            ],
          ],
        ),
      ),
    );
  }
}
```

**Step 6: Add Route**

```dart
// lib/config/routes.dart
import 'package:go_router/go_router.dart';
import '../screens/meal_plan_screen.dart';

final router = GoRouter(
  routes: [
    // ... existing routes
    GoRoute(
      path: '/meal-plan',
      name: 'meal-plan',
      builder: (context, state) => const MealPlanScreen(),
    ),
  ],
);
```

**Step 7: Run Code Generation**

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

---

## Naming Conventions

### File Naming

| Type | Convention | Example |
|------|-----------|---------|
| Models | `snake_case.dart` | `grocery_item.dart` |
| Services | `*_service.dart` | `firebase_service.dart` |
| Screens | `*_screen.dart` | `pantry_screen.dart` |
| Widgets | `snake_case.dart` | `grocery_item_card.dart` |
| Providers | `*_provider.dart` | `pantry_provider.dart` |
| Utils | `*_helpers.dart` or `*.dart` | `date_helpers.dart` |

### Class Naming

| Type | Convention | Example |
|------|-----------|---------|
| Models | `PascalCase` | `GroceryItem` |
| Services | `PascalCase` + `Service` | `FirebaseService` |
| Screens | `PascalCase` + `Screen` | `PantryScreen` |
| Widgets | `PascalCase` | `GroceryItemCard` |
| Providers | `camelCase` + `Provider` | `pantryProvider` |
| Notifiers | `PascalCase` + `Notifier` | `PantryNotifier` |

### Variable Naming

```dart
// Variables - camelCase
String userName = 'John';
int itemCount = 0;
bool isLoading = false;

// Constants - SCREAMING_SNAKE_CASE
const String API_BASE_URL = 'https://api.example.com';
const int MAX_ITEMS = 100;

// Private members - prefix with underscore
String _privateField = 'private';
void _privateMethod() {}

// Classes - PascalCase
class UserProfile {}
class GroceryItem {}

// Enums - PascalCase
enum ItemCategory { fruits, vegetables, dairy, meat }
```

---

## Code Examples

### Watson Service Integration

```dart
// lib/services/watson_service.dart
import 'package:dio/dio.dart';
import '../models/recipe.dart';

class WatsonService {
  final Dio _dio;
  final String _apiKey;
  final String _projectId;
  
  WatsonService({
    required Dio dio,
    required String apiKey,
    required String projectId,
  })  : _dio = dio,
        _apiKey = apiKey,
        _projectId = projectId;

  Future<List<Recipe>> suggestRecipes(List<String> ingredients) async {
    try {
      final response = await _dio.post(
        'https://us-south.ml.cloud.ibm.com/ml/v1/text/generation',
        data: {
          'input': 'Suggest 5 recipes using these ingredients: ${ingredients.join(", ")}. '
                   'Format as JSON array with title, ingredients, and instructions.',
          'parameters': {
            'max_new_tokens': 1000,
            'temperature': 0.7,
          },
          'model_id': 'ibm/granite-13b-chat-v2',
          'project_id': _projectId,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $_apiKey',
            'Content-Type': 'application/json',
          },
        ),
      );
      
      // Parse response and convert to Recipe objects
      final suggestions = response.data['results'][0]['generated_text'];
      return _parseRecipes(suggestions);
    } catch (e) {
      throw Exception('Failed to get recipe suggestions: $e');
    }
  }
  
  List<Recipe> _parseRecipes(String text) {
    // Parse Watson response and create Recipe objects
    // Implementation depends on Watson response format
    return [];
  }
}
```

### OCR Service

```dart
// lib/services/ocr_service.dart
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'dart:io';

class OCRService {
  final TextRecognizer _textRecognizer = TextRecognizer();
  
  Future<String> extractText(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final recognizedText = await _textRecognizer.processImage(inputImage);
    return recognizedText.text;
  }
  
  Future<DateTime?> extractExpiryDate(String text) async {
    // Parse expiry date from text
    // Look for patterns like "EXP: 12/25", "Best Before: 2025-12-31"
    final patterns = [
      RegExp(r'EXP:?\s*(\d{2})/(\d{2})'),
      RegExp(r'Best Before:?\s*(\d{4})-(\d{2})-(\d{2})'),
    ];
    
    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        // Parse and return date
        // Implementation depends on date format
      }
    }
    
    return null;
  }
  
  void dispose() {
    _textRecognizer.close();
  }
}
```

### Recipe API Service

```dart
// lib/services/recipe_api.dart
import 'package:dio/dio.dart';
import '../models/recipe.dart';

class RecipeAPIService {
  final Dio _dio;
  final String _apiKey;
  
  RecipeAPIService({required Dio dio, required String apiKey})
      : _dio = dio,
        _apiKey = apiKey;
  
  Future<List<Recipe>> searchRecipes({
    required List<String> ingredients,
    int number = 10,
  }) async {
    try {
      final response = await _dio.get(
        'https://api.spoonacular.com/recipes/findByIngredients',
        queryParameters: {
          'apiKey': _apiKey,
          'ingredients': ingredients.join(','),
          'number': number,
          'ranking': 2, // Maximize used ingredients
        },
      );
      
      return (response.data as List)
          .map((json) => Recipe.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to search recipes: $e');
    }
  }
  
  Future<Recipe> getRecipeDetails(int id) async {
    try {
      final response = await _dio.get(
        'https://api.spoonacular.com/recipes/$id/information',
        queryParameters: {'apiKey': _apiKey},
      );
      
      return Recipe.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to get recipe details: $e');
    }
  }
}
```

---

## Best Practices

### 1. Error Handling

```dart
// Always handle errors in services
class FirebaseService {
  Future<List<GroceryItem>> getPantryItems() async {
    try {
      final snapshot = await _firestore.collection('pantry_items').get();
      return snapshot.docs
          .map((doc) => GroceryItem.fromJson(doc.data()))
          .toList();
    } on FirebaseException catch (e) {
      throw Exception('Firebase error: ${e.message}');
    } catch (e) {
      throw Exception('Unknown error: $e');
    }
  }
}

// Handle errors in providers
final pantryProvider = FutureProvider<List<GroceryItem>>((ref) async {
  try {
    final service = ref.watch(firebaseServiceProvider);
    return await service.getPantryItems();
  } catch (e) {
    // Log error
    print('Error: $e');
    rethrow;
  }
});
```

### 2. Use Freezed for Models

```dart
@freezed
class GroceryItem with _$GroceryItem {
  const factory GroceryItem({
    required String id,
    required String name,
    // ... other fields
  }) = _GroceryItem;
  
  factory GroceryItem.fromJson(Map<String, dynamic> json) =>
      _$GroceryItemFromJson(json);
}
```

### 3. Dependency Injection with Riverpod

```dart
// Define service providers
final firebaseServiceProvider = Provider<FirebaseService>((ref) {
  return FirebaseService();
});

// Use in other providers
final pantryProvider = FutureProvider<List<GroceryItem>>((ref) async {
  final service = ref.watch(firebaseServiceProvider);
  return await service.getPantryItems();
});
```

### 4. Const Constructors

```dart
// Use const for better performance
const MyWidget({Key? key}) : super(key: key);

// Use const widgets
const Text('Hello');
const SizedBox(height: 16);
const Icon(Icons.add);
```

### 5. Code Documentation

```dart
/// Fetches all pantry items from Firestore.
///
/// Returns a list of [GroceryItem] objects.
/// Throws [Exception] if the fetch fails.
///
/// Example:
/// ```dart
/// final items = await firebaseService.getPantryItems();
/// ```
Future<List<GroceryItem>> getPantryItems() async {
  // Implementation
}
```

### 6. Organize Imports

```dart
// 1. Dart imports
import 'dart:async';

// 2. Flutter imports
import 'package:flutter/material.dart';

// 3. Package imports
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

// 4. Project imports
import '../models/grocery_item.dart';
import '../services/firebase_service.dart';
```

---

## Summary

This implementation guide provides:
- ✅ Clear data flow patterns with Riverpod
- ✅ Step-by-step guide for adding features
- ✅ Comprehensive naming conventions
- ✅ Real-world code examples
- ✅ Best practices for Flutter development

Follow these patterns to maintain consistency and quality throughout the Smart Grocery Optimizer project.