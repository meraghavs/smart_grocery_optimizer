import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:smart_grocery_optimizer/services/recipe_api.dart';
import 'package:smart_grocery_optimizer/models/grocery_item.dart';
import 'package:smart_grocery_optimizer/models/recipe.dart';

// Generate mock classes
@GenerateMocks([http.Client])
import 'recipe_api_test.mocks.dart';

/// Unit tests for RecipeApiService
/// 
/// Tests cover:
/// - Recipe search with mock HTTP responses
/// - Expiry-aware recipe matching
/// - Error handling
/// - Response parsing
void main() {
  group('RecipeApiService Unit Tests', () {
    late MockClient mockClient;
    late RecipeApiService recipeService;

    setUp(() {
      mockClient = MockClient();
      recipeService = RecipeApiService(
        apiKey: 'test_api_key',
        baseUrl: 'https://api.spoonacular.com',
        client: mockClient,
      );
    });

    group('findRecipesByExpiringIngredients', () {
      test('successfully finds recipes for expiring ingredients', () async {
        // Arrange
        final pantryItems = [
          GroceryItem(
            id: '1',
            userId: 'user1',
            name: 'Milk',
            category: 'Dairy',
            quantity: 1,
            unit: 'L',
            expiryDate: DateTime.now().add(const Duration(days: 2)),
            purchaseDate: DateTime.now().subtract(const Duration(days: 5)),
            price: 3.99,
          ),
          GroceryItem(
            id: '2',
            userId: 'user1',
            name: 'Eggs',
            category: 'Dairy',
            quantity: 12,
            unit: 'pcs',
            expiryDate: DateTime.now().add(const Duration(days: 3)),
            purchaseDate: DateTime.now().subtract(const Duration(days: 4)),
            price: 4.99,
          ),
        ];

        // Mock response for findByIngredients endpoint
        final mockSearchResponse = [
          {
            'id': 12345,
            'title': 'Scrambled Eggs with Milk',
            'image': 'https://example.com/image.jpg',
            'usedIngredientCount': 2,
            'missedIngredientCount': 1,
            'usedIngredients': [
              {'name': 'milk'},
              {'name': 'eggs'},
            ],
            'missedIngredients': [
              {'name': 'butter'},
            ],
          },
        ];

        // Mock response for recipe details endpoint
        final mockDetailsResponse = {
          'id': 12345,
          'title': 'Scrambled Eggs with Milk',
          'summary': 'A delicious breakfast recipe',
          'image': 'https://example.com/image.jpg',
          'servings': 2,
          'preparationMinutes': 5,
          'cookingMinutes': 10,
          'extendedIngredients': [
            {'original': 'milk'},
            {'original': 'eggs'},
            {'original': 'butter'},
          ],
          'analyzedInstructions': [
            {
              'steps': [
                {'step': 'Beat eggs'},
                {'step': 'Add milk'},
                {'step': 'Cook in pan'},
              ]
            }
          ],
          'dishTypes': ['breakfast'],
          'diets': [],
        };

        when(mockClient.get(any)).thenAnswer((invocation) async {
          final uri = invocation.positionalArguments[0] as Uri;
          if (uri.path.contains('findByIngredients')) {
            return http.Response(json.encode(mockSearchResponse), 200);
          } else if (uri.path.contains('/information')) {
            return http.Response(json.encode(mockDetailsResponse), 200);
          }
          return http.Response('Not Found', 404);
        });

        // Act
        final result = await recipeService.findRecipesByExpiringIngredients(pantryItems);

        // Assert
        expect(result, isA<List<RecipeWithExpiryScore>>());
        expect(result.isNotEmpty, isTrue);
        expect(result.first.recipe.title, equals('Scrambled Eggs with Milk'));
        expect(result.first.expiringIngredientsCount, greaterThan(0));
      });

      test('sorts recipes by expiring ingredients count', () async {
        // Arrange
        final pantryItems = [
          GroceryItem(
            id: '1',
            userId: 'user1',
            name: 'Milk',
            category: 'Dairy',
            quantity: 1,
            unit: 'L',
            expiryDate: DateTime.now().add(const Duration(days: 2)),
            purchaseDate: DateTime.now(),
            price: 3.99,
          ),
          GroceryItem(
            id: '2',
            userId: 'user1',
            name: 'Eggs',
            category: 'Dairy',
            quantity: 12,
            unit: 'pcs',
            expiryDate: DateTime.now().add(const Duration(days: 3)),
            purchaseDate: DateTime.now(),
            price: 4.99,
          ),
          GroceryItem(
            id: '3',
            userId: 'user1',
            name: 'Butter',
            category: 'Dairy',
            quantity: 1,
            unit: 'lb',
            expiryDate: DateTime.now().add(const Duration(days: 10)),
            purchaseDate: DateTime.now(),
            price: 5.99,
          ),
        ];

        final mockSearchResponse = [
          {
            'id': 1,
            'title': 'Recipe with 1 expiring',
            'usedIngredientCount': 1,
            'missedIngredientCount': 0,
            'usedIngredients': [{'name': 'milk'}],
            'missedIngredients': [],
          },
          {
            'id': 2,
            'title': 'Recipe with 2 expiring',
            'usedIngredientCount': 2,
            'missedIngredientCount': 0,
            'usedIngredients': [{'name': 'milk'}, {'name': 'eggs'}],
            'missedIngredients': [],
          },
        ];

        final mockDetails1 = {
          'id': 1,
          'title': 'Recipe with 1 expiring',
          'summary': 'Recipe description',
          'servings': 2,
          'preparationMinutes': 10,
          'cookingMinutes': 20,
          'extendedIngredients': [{'original': 'milk'}],
          'analyzedInstructions': [{'steps': [{'step': 'Cook'}]}],
          'dishTypes': [],
          'diets': [],
        };

        final mockDetails2 = {
          'id': 2,
          'title': 'Recipe with 2 expiring',
          'summary': 'Recipe description',
          'servings': 2,
          'preparationMinutes': 10,
          'cookingMinutes': 20,
          'extendedIngredients': [{'original': 'milk'}, {'original': 'eggs'}],
          'analyzedInstructions': [{'steps': [{'step': 'Cook'}]}],
          'dishTypes': [],
          'diets': [],
        };

        when(mockClient.get(any)).thenAnswer((invocation) async {
          final uri = invocation.positionalArguments[0] as Uri;
          if (uri.path.contains('findByIngredients')) {
            return http.Response(json.encode(mockSearchResponse), 200);
          } else if (uri.path.contains('/1/information')) {
            return http.Response(json.encode(mockDetails1), 200);
          } else if (uri.path.contains('/2/information')) {
            return http.Response(json.encode(mockDetails2), 200);
          }
          return http.Response('Not Found', 404);
        });

        // Act
        final result = await recipeService.findRecipesByExpiringIngredients(pantryItems);

        // Assert
        expect(result.length, equals(2));
        expect(
          result.first.expiringIngredientsCount,
          greaterThanOrEqualTo(result.last.expiringIngredientsCount),
        );
      });

      test('identifies expiring ingredients correctly', () async {
        // Arrange
        final pantryItems = [
          GroceryItem(
            id: '1',
            userId: 'user1',
            name: 'Milk',
            category: 'Dairy',
            quantity: 1,
            unit: 'L',
            expiryDate: DateTime.now().add(const Duration(days: 2)),
            purchaseDate: DateTime.now(),
            price: 3.99,
          ),
          GroceryItem(
            id: '2',
            userId: 'user1',
            name: 'Cheese',
            category: 'Dairy',
            quantity: 1,
            unit: 'lb',
            expiryDate: DateTime.now().add(const Duration(days: 15)),
            purchaseDate: DateTime.now(),
            price: 6.99,
          ),
        ];

        final mockSearchResponse = [
          {
            'id': 1,
            'title': 'Cheese and Milk Recipe',
            'usedIngredientCount': 2,
            'missedIngredientCount': 0,
            'usedIngredients': [
              {'name': 'milk'},
              {'name': 'cheese'},
            ],
            'missedIngredients': [],
          },
        ];

        final mockDetailsResponse = {
          'id': 1,
          'title': 'Cheese and Milk Recipe',
          'summary': 'A delicious recipe',
          'servings': 2,
          'preparationMinutes': 10,
          'cookingMinutes': 20,
          'extendedIngredients': [
            {'original': 'milk'},
            {'original': 'cheese'},
          ],
          'analyzedInstructions': [{'steps': [{'step': 'Cook'}]}],
          'dishTypes': [],
          'diets': [],
        };

        when(mockClient.get(any)).thenAnswer((invocation) async {
          final uri = invocation.positionalArguments[0] as Uri;
          if (uri.path.contains('findByIngredients')) {
            return http.Response(json.encode(mockSearchResponse), 200);
          } else if (uri.path.contains('/information')) {
            return http.Response(json.encode(mockDetailsResponse), 200);
          }
          return http.Response('Not Found', 404);
        });

        // Act
        final result = await recipeService.findRecipesByExpiringIngredients(
          pantryItems,
          expiryThresholdDays: 7,
        );

        // Assert
        expect(result.first.expiringIngredientsUsed, contains('Milk'));
        expect(result.first.expiringIngredientsUsed, isNot(contains('Cheese')));
      });

      test('calculates expiring percentage correctly', () async {
        // Arrange
        final pantryItems = [
          GroceryItem(
            id: '1',
            userId: 'user1',
            name: 'Milk',
            category: 'Dairy',
            quantity: 1,
            unit: 'L',
            expiryDate: DateTime.now().add(const Duration(days: 2)),
            purchaseDate: DateTime.now(),
            price: 3.99,
          ),
          GroceryItem(
            id: '2',
            userId: 'user1',
            name: 'Eggs',
            category: 'Dairy',
            quantity: 12,
            unit: 'pcs',
            expiryDate: DateTime.now().add(const Duration(days: 3)),
            purchaseDate: DateTime.now(),
            price: 4.99,
          ),
        ];

        final mockSearchResponse = [
          {
            'id': 1,
            'title': 'Recipe using both',
            'usedIngredientCount': 2,
            'missedIngredientCount': 0,
            'usedIngredients': [
              {'name': 'milk'},
              {'name': 'eggs'},
            ],
            'missedIngredients': [],
          },
        ];

        final mockDetailsResponse = {
          'id': 1,
          'title': 'Recipe using both',
          'summary': 'A delicious recipe',
          'servings': 2,
          'preparationMinutes': 10,
          'cookingMinutes': 20,
          'extendedIngredients': [
            {'original': 'milk'},
            {'original': 'eggs'},
          ],
          'analyzedInstructions': [{'steps': [{'step': 'Cook'}]}],
          'dishTypes': [],
          'diets': [],
        };

        when(mockClient.get(
          any,
        )).thenAnswer((invocation) async {
          final uri = invocation.positionalArguments[0] as Uri;
          if (uri.path.contains('findByIngredients')) {
            return http.Response(json.encode(mockSearchResponse), 200);
          } else if (uri.path.contains('/information')) {
            return http.Response(json.encode(mockDetailsResponse), 200);
          }
          return http.Response('Not Found', 404);
        });

        // Act
        final result = await recipeService.findRecipesByExpiringIngredients(pantryItems);

        // Assert
        expect(result.first.expiringIngredientsPercentage, equals(100.0));
      });

      test('handles empty pantry items', () async {
        // Arrange
        final pantryItems = <GroceryItem>[];

        // Act
        final result = await recipeService.findRecipesByExpiringIngredients(pantryItems);

        // Assert
        expect(result, isEmpty);
      });

      test('handles API error response', () async {
        // Arrange
        final pantryItems = [
          GroceryItem(
            id: '1',
            userId: 'user1',
            name: 'Milk',
            category: 'Dairy',
            quantity: 1,
            unit: 'L',
            expiryDate: DateTime.now().add(const Duration(days: 2)),
            purchaseDate: DateTime.now(),
            price: 3.99,
          ),
        ];

        when(mockClient.get(
          any,
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response(
          'Internal Server Error',
          500,
        ));

        // Act & Assert
        expect(
          () => recipeService.findRecipesByExpiringIngredients(pantryItems),
          throwsA(isA<Exception>()),
        );
      });

      test('handles network timeout', () async {
        // Arrange
        final pantryItems = [
          GroceryItem(
            id: '1',
            userId: 'user1',
            name: 'Milk',
            category: 'Dairy',
            quantity: 1,
            unit: 'L',
            expiryDate: DateTime.now().add(const Duration(days: 2)),
            purchaseDate: DateTime.now(),
            price: 3.99,
          ),
        ];

        when(mockClient.get(
          any,
          headers: anyNamed('headers'),
        )).thenThrow(Exception('Network timeout'));

        // Act & Assert
        expect(
          () => recipeService.findRecipesByExpiringIngredients(pantryItems),
          throwsA(isA<Exception>()),
        );
      });

      test('handles malformed JSON response', () async {
        // Arrange
        final pantryItems = [
          GroceryItem(
            id: '1',
            userId: 'user1',
            name: 'Milk',
            category: 'Dairy',
            quantity: 1,
            unit: 'L',
            expiryDate: DateTime.now().add(const Duration(days: 2)),
            purchaseDate: DateTime.now(),
            price: 3.99,
          ),
        ];

        when(mockClient.get(
          any,
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response(
          'Invalid JSON',
          200,
        ));

        // Act & Assert
        expect(
          () => recipeService.findRecipesByExpiringIngredients(pantryItems),
          throwsA(isA<Exception>()),
        );
      });

      test('handles empty API response', () async {
        // Arrange
        final pantryItems = [
          GroceryItem(
            id: '1',
            userId: 'user1',
            name: 'Milk',
            category: 'Dairy',
            quantity: 1,
            unit: 'L',
            expiryDate: DateTime.now().add(const Duration(days: 2)),
            purchaseDate: DateTime.now(),
            price: 3.99,
          ),
        ];

        when(mockClient.get(
          any,
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response(
          json.encode([]),
          200,
        ));

        // Act
        final result = await recipeService.findRecipesByExpiringIngredients(pantryItems);

        // Assert
        expect(result, isEmpty);
      });

      test('sends correct query parameters', () async {
        // Arrange
        final pantryItems = [
          GroceryItem(
            id: '1',
            userId: 'user1',
            name: 'Milk',
            category: 'Dairy',
            quantity: 1,
            unit: 'L',
            expiryDate: DateTime.now().add(const Duration(days: 2)),
            purchaseDate: DateTime.now(),
            price: 3.99,
          ),
        ];

        final mockSearchResponse = [
          {
            'id': 1,
            'title': 'Test Recipe',
            'usedIngredientCount': 1,
            'missedIngredientCount': 0,
            'usedIngredients': [{'name': 'milk'}],
            'missedIngredients': [],
          },
        ];

        final mockDetailsResponse = {
          'id': 1,
          'title': 'Test Recipe',
          'summary': 'Test',
          'servings': 2,
          'preparationMinutes': 10,
          'cookingMinutes': 20,
          'extendedIngredients': [{'original': 'milk'}],
          'analyzedInstructions': [{'steps': [{'step': 'Cook'}]}],
          'dishTypes': [],
          'diets': [],
        };

        when(mockClient.get(any)).thenAnswer((invocation) async {
          final uri = invocation.positionalArguments[0] as Uri;
          if (uri.path.contains('findByIngredients')) {
            return http.Response(json.encode(mockSearchResponse), 200);
          } else if (uri.path.contains('/information')) {
            return http.Response(json.encode(mockDetailsResponse), 200);
          }
          return http.Response('Not Found', 404);
        });

        // Act
        await recipeService.findRecipesByExpiringIngredients(pantryItems);

        // Assert
        final captured = verify(mockClient.get(captureAny)).captured;

        final uri = captured.first as Uri;
        expect(uri.queryParameters['apiKey'], equals('test_api_key'));
        expect(uri.queryParameters['ingredients'], isNotNull);
        expect(uri.queryParameters['number'], isNotNull);
      });

      test('respects custom expiry threshold', () async {
        // Arrange
        final pantryItems = [
          GroceryItem(
            id: '1',
            userId: 'user1',
            name: 'Milk',
            category: 'Dairy',
            quantity: 1,
            unit: 'L',
            expiryDate: DateTime.now().add(const Duration(days: 10)),
            purchaseDate: DateTime.now(),
            price: 3.99,
          ),
        ];

        final mockSearchResponse = [
          {
            'id': 1,
            'title': 'Test Recipe',
            'usedIngredientCount': 1,
            'missedIngredientCount': 0,
            'usedIngredients': [{'name': 'milk'}],
            'missedIngredients': [],
          },
        ];

        final mockDetailsResponse = {
          'id': 1,
          'title': 'Test Recipe',
          'summary': 'Test',
          'servings': 2,
          'preparationMinutes': 10,
          'cookingMinutes': 20,
          'extendedIngredients': [{'original': 'milk'}],
          'analyzedInstructions': [{'steps': [{'step': 'Cook'}]}],
          'dishTypes': [],
          'diets': [],
        };

        when(mockClient.get(any)).thenAnswer((invocation) async {
          final uri = invocation.positionalArguments[0] as Uri;
          if (uri.path.contains('findByIngredients')) {
            return http.Response(json.encode(mockSearchResponse), 200);
          } else if (uri.path.contains('/information')) {
            return http.Response(json.encode(mockDetailsResponse), 200);
          }
          return http.Response('Not Found', 404);
        });

        // Act
        final result = await recipeService.findRecipesByExpiringIngredients(
          pantryItems,
          expiryThresholdDays: 14,
        );

        // Assert
        expect(result.first.expiringIngredientsCount, equals(1));
      });

      test('calculates priority score correctly', () async {
        // Arrange
        final pantryItems = [
          GroceryItem(
            id: '1',
            userId: 'user1',
            name: 'Milk',
            category: 'Dairy',
            quantity: 1,
            unit: 'L',
            expiryDate: DateTime.now().add(const Duration(days: 2)),
            purchaseDate: DateTime.now(),
            price: 3.99,
          ),
        ];

        final mockSearchResponse = [
          {
            'id': 1,
            'title': 'Test Recipe',
            'usedIngredientCount': 1,
            'missedIngredientCount': 0,
            'usedIngredients': [{'name': 'milk'}],
            'missedIngredients': [],
          },
        ];

        final mockDetailsResponse = {
          'id': 1,
          'title': 'Test Recipe',
          'summary': 'Test',
          'servings': 2,
          'preparationMinutes': 10,
          'cookingMinutes': 20,
          'extendedIngredients': [{'original': 'milk'}],
          'analyzedInstructions': [{'steps': [{'step': 'Cook'}]}],
          'dishTypes': [],
          'diets': [],
        };

        when(mockClient.get(any)).thenAnswer((invocation) async {
          final uri = invocation.positionalArguments[0] as Uri;
          if (uri.path.contains('findByIngredients')) {
            return http.Response(json.encode(mockSearchResponse), 200);
          } else if (uri.path.contains('/information')) {
            return http.Response(json.encode(mockDetailsResponse), 200);
          }
          return http.Response('Not Found', 404);
        });

        // Act
        final result = await recipeService.findRecipesByExpiringIngredients(pantryItems);

        // Assert
        expect(result.first.priorityScore, greaterThan(0));
      });

      test('handles unauthorized error', () async {
        // Arrange
        final pantryItems = [
          GroceryItem(
            id: '1',
            userId: 'user1',
            name: 'Milk',
            category: 'Dairy',
            quantity: 1,
            unit: 'L',
            expiryDate: DateTime.now().add(const Duration(days: 2)),
            purchaseDate: DateTime.now(),
            price: 3.99,
          ),
        ];

        when(mockClient.get(any)).thenAnswer((_) async => http.Response(
          'Unauthorized',
          401,
        ));

        // Act & Assert
        expect(
          () => recipeService.findRecipesByExpiringIngredients(pantryItems),
          throwsA(isA<Exception>()),
        );
      });

      test('handles large number of results', () async {
        // Arrange
        final pantryItems = [
          GroceryItem(
            id: '1',
            userId: 'user1',
            name: 'Milk',
            category: 'Dairy',
            quantity: 1,
            unit: 'L',
            expiryDate: DateTime.now().add(const Duration(days: 2)),
            purchaseDate: DateTime.now(),
            price: 3.99,
          ),
        ];

        final mockSearchResponse = List.generate(
          50,
          (i) => {
            'id': i,
            'title': 'Recipe $i',
            'usedIngredientCount': 1,
            'missedIngredientCount': 0,
            'usedIngredients': [{'name': 'milk'}],
            'missedIngredients': [],
          },
        );

        when(mockClient.get(any)).thenAnswer((invocation) async {
          final uri = invocation.positionalArguments[0] as Uri;
          if (uri.path.contains('findByIngredients')) {
            return http.Response(json.encode(mockSearchResponse), 200);
          } else if (uri.path.contains('/information')) {
            // Extract recipe ID from path
            final pathSegments = uri.pathSegments;
            final idIndex = pathSegments.indexOf('information') - 1;
            final id = int.tryParse(pathSegments[idIndex]) ?? 0;
            
            return http.Response(
              json.encode({
                'id': id,
                'title': 'Recipe $id',
                'summary': 'Test',
                'servings': 2,
                'preparationMinutes': 10,
                'cookingMinutes': 20,
                'extendedIngredients': [{'original': 'milk'}],
                'analyzedInstructions': [{'steps': [{'step': 'Cook'}]}],
                'dishTypes': [],
                'diets': [],
              }),
              200,
            );
          }
          return http.Response('Not Found', 404);
        });

        // Act
        final result = await recipeService.findRecipesByExpiringIngredients(
          pantryItems,
        );

        // Assert
        expect(result.length, greaterThan(0));
      });
    });
  });
}

// Made with Bob
