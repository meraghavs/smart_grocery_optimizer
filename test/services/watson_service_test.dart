import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:smart_grocery_optimizer/services/watson_service.dart';

// Generate mock classes
@GenerateMocks([http.Client])
import 'watson_service_test.mocks.dart';

/// Unit tests for WatsonService
/// 
/// Tests cover:
/// - Image identification with mock HTTP responses
/// - Error handling
/// - Response parsing
/// - Edge cases
void main() {
  group('WatsonService Unit Tests', () {
    late MockClient mockClient;
    late WatsonService watsonService;

    setUp(() {
      mockClient = MockClient();
      watsonService = WatsonService(
        apiKey: 'test_api_key',
        apiUrl: 'https://api.test.com',
        client: mockClient,
      );
    });

    group('identifyGroceryItems', () {
      test('successfully identifies grocery items from image', () async {
        // Arrange
        final mockImageBytes = [1, 2, 3, 4, 5];
        final mockResponse = {
          'images': [
            {
              'objects': {
                'collections': [
                  {
                    'objects': [
                      {'class': 'food/fruit/apple', 'score': 0.95},
                      {'class': 'food/fruit', 'score': 0.92},
                    ]
                  }
                ]
              },
              'food': {
                'items': [
                  {'name': 'apple', 'score': 0.95},
                ]
              }
            }
          ]
        };

        when(mockClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(
          json.encode(mockResponse),
          200,
        ));

        // Act
        final result = await watsonService.identifyGroceryItems(mockImageBytes);

        // Assert
        expect(result, isA<List<Map<String, dynamic>>>());
        expect(result.length, greaterThan(0));
        expect(result.first['name'], isNotNull);
        expect(result.first['category'], isNotNull);
        expect(result.first['confidence'], isA<double>());
        expect(result.first['confidence'], greaterThanOrEqualTo(0.0));
        expect(result.first['confidence'], lessThanOrEqualTo(1.0));
      });

      test('handles multiple items in response', () async {
        // Arrange
        final mockImageBytes = [1, 2, 3, 4, 5];
        final mockResponse = {
          'images': [
            {
              'objects': {
                'collections': [
                  {
                    'objects': [
                      {'class': 'food/fruit/apple', 'score': 0.95},
                      {'class': 'food/fruit/banana', 'score': 0.90},
                    ]
                  }
                ]
              },
              'food': {
                'items': [
                  {'name': 'apple', 'score': 0.95},
                  {'name': 'banana', 'score': 0.90},
                  {'name': 'orange', 'score': 0.85},
                  {'name': 'milk', 'score': 0.80},
                ]
              }
            }
          ]
        };

        when(mockClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(
          json.encode(mockResponse),
          200,
        ));

        // Act
        final result = await watsonService.identifyGroceryItems(mockImageBytes);

        // Assert
        expect(result.length, greaterThan(1));
        expect(result.every((item) => item['confidence'] >= 0.7), isTrue);
      });

      test('filters out low confidence items', () async {
        // Arrange
        final mockImageBytes = [1, 2, 3, 4, 5];
        final mockResponse = {
          'images': [
            {
              'classifiers': [
                {
                  'classes': [
                    {'class': 'apple', 'score': 0.95},
                    {'class': 'unknown', 'score': 0.30},
                    {'class': 'banana', 'score': 0.85},
                    {'class': 'noise', 'score': 0.15},
                  ]
                }
              ]
            }
          ]
        };

        when(mockClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(
          json.encode(mockResponse),
          200,
        ));

        // Act
        final result = await watsonService.identifyGroceryItems(mockImageBytes);

        // Assert
        expect(result.every((item) => item['confidence'] >= 0.7), isTrue);
        expect(result.any((item) => item['confidence'] < 0.7), isFalse);
      });

      test('categorizes items correctly', () async {
        // Arrange
        final mockImageBytes = [1, 2, 3, 4, 5];
        final mockResponse = {
          'images': [
            {
              'objects': {
                'collections': [
                  {
                    'objects': [
                      {'class': 'food/fruit/apple', 'score': 0.95},
                      {'class': 'food/dairy/milk', 'score': 0.90},
                      {'class': 'food/bakery/bread', 'score': 0.88},
                    ]
                  }
                ]
              },
              'food': {
                'items': [
                  {'name': 'apple', 'score': 0.95},
                  {'name': 'milk', 'score': 0.90},
                  {'name': 'bread', 'score': 0.88},
                ]
              }
            }
          ]
        };

        when(mockClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(
          json.encode(mockResponse),
          200,
        ));

        // Act
        final result = await watsonService.identifyGroceryItems(mockImageBytes);

        // Assert
        expect(result.length, greaterThan(0));
        expect(result.every((item) => item['name'] != null), isTrue);
        expect(result.every((item) => item['confidence'] != null), isTrue);
        // Check that at least some items have categories assigned
        final categorizedItems = result.where((item) => item['category'] != null).toList();
        expect(categorizedItems.length, greaterThan(0));
      });

      test('removes duplicate items', () async {
        // Arrange
        final mockImageBytes = [1, 2, 3, 4, 5];
        final mockResponse = {
          'images': [
            {
              'classifiers': [
                {
                  'classes': [
                    {'class': 'apple', 'score': 0.95},
                    {'class': 'red apple', 'score': 0.90},
                    {'class': 'apple fruit', 'score': 0.88},
                  ]
                }
              ]
            }
          ]
        };

        when(mockClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(
          json.encode(mockResponse),
          200,
        ));

        // Act
        final result = await watsonService.identifyGroceryItems(mockImageBytes);

        // Assert
        final names = result.map((item) => item['name']).toList();
        expect(names.toSet().length, equals(names.length)); // No duplicates
      });

      test('handles empty image bytes', () async {
        // Arrange
        final mockImageBytes = <int>[];

        // Act & Assert
        expect(
          () => watsonService.identifyGroceryItems(mockImageBytes),
          throwsA(isA<Exception>()),
        );
      });

      test('handles API error response', () async {
        // Arrange
        final mockImageBytes = [1, 2, 3, 4, 5];

        when(mockClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(
          'Internal Server Error',
          500,
        ));

        // Act & Assert
        expect(
          () => watsonService.identifyGroceryItems(mockImageBytes),
          throwsA(isA<Exception>()),
        );
      });

      test('handles network timeout', () async {
        // Arrange
        final mockImageBytes = [1, 2, 3, 4, 5];

        when(mockClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenThrow(Exception('Network timeout'));

        // Act & Assert
        expect(
          () => watsonService.identifyGroceryItems(mockImageBytes),
          throwsA(isA<Exception>()),
        );
      });

      test('handles malformed JSON response', () async {
        // Arrange
        final mockImageBytes = [1, 2, 3, 4, 5];

        when(mockClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(
          'Invalid JSON',
          200,
        ));

        // Act & Assert
        expect(
          () => watsonService.identifyGroceryItems(mockImageBytes),
          throwsA(isA<Exception>()),
        );
      });

      test('handles empty response', () async {
        // Arrange
        final mockImageBytes = [1, 2, 3, 4, 5];
        final mockResponse = {
          'images': [
            {
              'classifiers': [
                {
                  'classes': []
                }
              ]
            }
          ]
        };

        when(mockClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(
          json.encode(mockResponse),
          200,
        ));

        // Act
        final result = await watsonService.identifyGroceryItems(mockImageBytes);

        // Assert
        expect(result, isEmpty);
      });

      test('sends correct headers', () async {
        // Arrange
        final mockImageBytes = [1, 2, 3, 4, 5];
        final mockResponse = {
          'images': [
            {
              'classifiers': [
                {
                  'classes': [
                    {'class': 'apple', 'score': 0.95},
                  ]
                }
              ]
            }
          ]
        };

        when(mockClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(
          json.encode(mockResponse),
          200,
        ));

        // Act
        await watsonService.identifyGroceryItems(mockImageBytes);

        // Assert
        verify(mockClient.post(
          any,
          headers: argThat(
            containsPair('Authorization', 'Bearer test_api_key'),
            named: 'headers',
          ),
          body: anyNamed('body'),
        )).called(1);
      });

      test('converts image to base64', () async {
        // Arrange
        final mockImageBytes = [1, 2, 3, 4, 5];
        final expectedBase64 = base64Encode(mockImageBytes);
        final mockResponse = {
          'images': [
            {
              'classifiers': [
                {
                  'classes': [
                    {'class': 'apple', 'score': 0.95},
                  ]
                }
              ]
            }
          ]
        };

        when(mockClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(
          json.encode(mockResponse),
          200,
        ));

        // Act
        await watsonService.identifyGroceryItems(mockImageBytes);

        // Assert
        verify(mockClient.post(
          any,
          headers: anyNamed('headers'),
          body: argThat(
            contains(expectedBase64),
            named: 'body',
          ),
        )).called(1);
      });

      test('handles unauthorized error', () async {
        // Arrange
        final mockImageBytes = [1, 2, 3, 4, 5];

        when(mockClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(
          'Unauthorized',
          401,
        ));

        // Act & Assert
        expect(
          () => watsonService.identifyGroceryItems(mockImageBytes),
          throwsA(isA<Exception>()),
        );
      });

      test('sorts results by confidence descending', () async {
        // Arrange
        final mockImageBytes = [1, 2, 3, 4, 5];
        final mockResponse = {
          'images': [
            {
              'classifiers': [
                {
                  'classes': [
                    {'class': 'apple', 'score': 0.75},
                    {'class': 'banana', 'score': 0.95},
                    {'class': 'orange', 'score': 0.85},
                  ]
                }
              ]
            }
          ]
        };

        when(mockClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(
          json.encode(mockResponse),
          200,
        ));

        // Act
        final result = await watsonService.identifyGroceryItems(mockImageBytes);

        // Assert
        for (int i = 0; i < result.length - 1; i++) {
          expect(
            result[i]['confidence'],
            greaterThanOrEqualTo(result[i + 1]['confidence']),
          );
        }
      });

      test('limits results to top 10 items', () async {
        // Arrange
        final mockImageBytes = [1, 2, 3, 4, 5];
        final classes = List.generate(
          20,
          (i) => {'class': 'item_$i', 'score': 0.95 - (i * 0.01)},
        );
        final mockResponse = {
          'images': [
            {
              'classifiers': [
                {'classes': classes}
              ]
            }
          ]
        };

        when(mockClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(
          json.encode(mockResponse),
          200,
        ));

        // Act
        final result = await watsonService.identifyGroceryItems(mockImageBytes);

        // Assert
        expect(result.length, lessThanOrEqualTo(10));
      });
    });

    group('validateConnection', () {
      test('returns true for successful connection', () async {
        // Arrange
        final mockResponse = {
          'images': [
            {
              'objects': {
                'collections': [
                  {
                    'objects': [
                      {'class': 'food/test', 'score': 0.95},
                    ]
                  }
                ]
              },
            }
          ]
        };
        
        when(mockClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(
          json.encode(mockResponse),
          200,
        ));

        // Act
        final result = await watsonService.validateConnection();

        // Assert
        expect(result, isTrue);
      });

      test('returns false for failed connection', () async {
        // Arrange
        when(mockClient.get(
          any,
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response('Error', 500));

        // Act
        final result = await watsonService.validateConnection();

        // Assert
        expect(result, isFalse);
      });

      test('returns false on network error', () async {
        // Arrange
        when(mockClient.get(
          any,
          headers: anyNamed('headers'),
        )).thenThrow(Exception('Network error'));

        // Act
        final result = await watsonService.validateConnection();

        // Assert
        expect(result, isFalse);
      });
    });
  });
}

// Made with Bob
