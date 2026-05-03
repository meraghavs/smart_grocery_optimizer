# Smart Grocery Optimizer - Architecture Documentation

## Overview
Smart Grocery Optimizer is a cross-platform Flutter application that helps users manage their grocery inventory, find recipes based on expiring items, generate smart shopping lists, and track their budget.

## Architecture Approach

### Simple, Flat Structure
This project uses a **straightforward, flat folder structure** that prioritizes:
1. **Simplicity**: Easy to navigate and understand
2. **Clarity**: Clear separation between models, services, screens, and widgets
3. **Maintainability**: Quick to locate and modify files
4. **Scalability**: Easy to add new features without restructuring

### Architecture Layers

```
┌─────────────────────────────────────────────────────────────┐
│                     Presentation Layer                       │
│                  (Screens + Widgets)                         │
│  - User interface components                                 │
│  - Screen layouts and navigation                             │
└─────────────────────────────────────────────────────────────┘
                            ↓↑
┌─────────────────────────────────────────────────────────────┐
│                    State Management Layer                    │
│                   (Riverpod Providers)                       │
│  - Application state                                         │
│  - State updates and notifications                           │
└─────────────────────────────────────────────────────────────┘
                            ↓↑
┌─────────────────────────────────────────────────────────────┐
│                      Service Layer                           │
│                      (Services)                              │
│  - Business logic                                            │
│  - External API integrations                                 │
│  - Data operations                                           │
└─────────────────────────────────────────────────────────────┘
                            ↓↑
┌─────────────────────────────────────────────────────────────┐
│                       Data Layer                             │
│                       (Models)                               │
│  - Data structures                                           │
│  - JSON serialization                                        │
└─────────────────────────────────────────────────────────────┘
                            ↓↑
┌─────────────────────────────────────────────────────────────┐
│                    External Services                         │
│        (Firebase, IBM watsonx, APIs, Local Storage)          │
└─────────────────────────────────────────────────────────────┘
```

## Key Features

### 1. Pantry Scanner
- Camera integration for scanning grocery items
- OCR (Optical Character Recognition) for text extraction
- Barcode scanning for product identification
- Manual entry fallback

### 2. Expiry-Aware Recipe Finder
- Recipe search based on available ingredients
- Prioritization of items nearing expiry
- AI-powered recipe suggestions using IBM watsonx
- Nutritional information display

### 3. AI-Powered Shopping List
- Smart list generation based on pantry inventory
- Recurring item suggestions
- Budget-aware recommendations
- Category-based organization

### 4. Budget Tracker
- Expense tracking and categorization
- Budget goals and alerts
- Spending analytics and visualizations
- Price comparison history

## Technology Stack

### Core Framework
- **Flutter**: Cross-platform UI framework
- **Dart**: Programming language

### State Management
- **Riverpod 2.x**: State management and dependency injection
- **Freezed**: Immutable data classes
- **Hooks Riverpod**: React-like hooks for Flutter

### Backend & Services
- **Firebase**:
  - Authentication (email/password, Google Sign-In)
  - Firestore (NoSQL database)
  - Cloud Storage (image storage)
  - Analytics
  - Crashlytics

### AI & ML
- **IBM watsonx**: Natural Language Processing for recipe suggestions and visual recognition
- **Google ML Kit**: On-device OCR and text recognition
- **Spoonacular API**: Recipe database and search

### Local Storage
- **Hive**: Fast, lightweight local database
- **Shared Preferences**: Simple key-value storage
- **Secure Storage**: Encrypted credential storage

### Camera & Image Processing
- **camera**: Camera access
- **image_picker**: Image selection
- **google_mlkit_text_recognition**: OCR capabilities
- **google_mlkit_barcode_scanning**: Barcode scanning

### UI & UX
- **go_router**: Declarative routing
- **cached_network_image**: Image caching
- **fl_chart**: Data visualization

## Data Flow

### State Management Flow (Riverpod)
```
User Action → Screen → Provider → Service → External API/DB
                ↓                                    ↓
            UI Update ← State Change ← Response ← Data
```

### Feature Data Flow Example (Pantry Scanner)
```
1. User captures image → Scanner Screen
2. Image sent to → OCR Service (ML Kit)
3. Text extracted → Parsed by Watson Service
4. Product identified → Firebase Service lookup
5. Item saved → Firebase Service
6. State updated → Pantry Provider
7. UI refreshed → Pantry Screen
```

## Project Structure

```
lib/
├── models/              # Data models (GroceryItem, Recipe, Budget)
├── services/            # Business logic and API integrations
├── screens/             # Full-page UI screens
├── widgets/             # Reusable UI components
├── state/               # Riverpod providers
├── utils/               # Helper functions and utilities
└── config/              # App configuration
```

### Models
Data structures representing app entities:
- `GroceryItem`: Pantry items with expiry dates
- `Recipe`: Recipe information and instructions
- `Budget`: Expense tracking data
- `ShoppingList`: Shopping list and items
- `User`: User profile data

### Services
Business logic and external integrations:
- `watson_service.dart`: IBM watsonx NLP + Visual Recognition
- `firebase_service.dart`: Firestore CRUD operations
- `recipe_api.dart`: Spoonacular API integration
- `price_api.dart`: Store price feeds
- `auth_service.dart`: Firebase Authentication
- `ocr_service.dart`: Text recognition
- `barcode_service.dart`: Barcode scanning

### Screens
Full-page UI components:
- `pantry_screen.dart`: Pantry management
- `shopping_list_screen.dart`: Shopping lists
- `recipe_screen.dart`: Recipe discovery
- `budget_screen.dart`: Budget tracking
- `scanner_screen.dart`: Camera scanning

### Widgets
Reusable UI components:
- Cards (grocery items, recipes, shopping items)
- Custom buttons and inputs
- Charts and visualizations
- Loading and empty states

### State (Riverpod Providers)
Application state management:
- `auth_provider.dart`: Authentication state
- `pantry_provider.dart`: Pantry items state
- `recipe_provider.dart`: Recipes state
- `shopping_provider.dart`: Shopping list state
- `budget_provider.dart`: Budget state

### Utils
Helper functions:
- Date formatting and calculations
- Currency and number formatters
- Input validation
- Constants and colors

## Data Flow Patterns

### 1. Fetching Data
```dart
// Provider fetches data from service
final pantryItemsProvider = FutureProvider<List<GroceryItem>>((ref) async {
  final firebaseService = ref.watch(firebaseServiceProvider);
  return await firebaseService.getPantryItems();
});

// Screen consumes the provider
class PantryScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(pantryItemsProvider);
    
    return itemsAsync.when(
      data: (items) => ListView.builder(...),
      loading: () => CircularProgressIndicator(),
      error: (error, stack) => ErrorWidget(error),
    );
  }
}
```

### 2. Updating Data
```dart
// Provider with state notifier
class PantryNotifier extends StateNotifier<List<GroceryItem>> {
  final FirebaseService _firebaseService;
  
  PantryNotifier(this._firebaseService) : super([]);
  
  Future<void> addItem(GroceryItem item) async {
    await _firebaseService.addPantryItem(item);
    state = [...state, item];
  }
  
  Future<void> deleteItem(String id) async {
    await _firebaseService.deletePantryItem(id);
    state = state.where((item) => item.id != id).toList();
  }
}

final pantryProvider = StateNotifierProvider<PantryNotifier, List<GroceryItem>>((ref) {
  final firebaseService = ref.watch(firebaseServiceProvider);
  return PantryNotifier(firebaseService);
});
```

### 3. AI Integration (Watson)
```dart
// Watson Service for recipe suggestions
class WatsonService {
  Future<List<Recipe>> suggestRecipes(List<String> ingredients) async {
    // Call IBM watsonx API
    final response = await _dio.post(
      'https://us-south.ml.cloud.ibm.com/ml/v1/text/generation',
      data: {
        'input': 'Suggest recipes using: ${ingredients.join(", ")}',
        'parameters': {'max_new_tokens': 500},
        'model_id': 'ibm/granite-13b-chat-v2',
      },
    );
    
    // Parse and return recipes
    return parseRecipes(response.data);
  }
}
```

## Testing Strategy

### Test Pyramid
```
        ┌─────────────┐
        │   E2E Tests │  (10%)
        └─────────────┘
      ┌─────────────────┐
      │ Widget Tests    │  (20%)
      └─────────────────┘
    ┌─────────────────────┐
    │    Unit Tests       │  (70%)
    └─────────────────────┘
```

### Test Coverage Goals
- **Unit Tests**: 70%+ coverage (services, models, utils)
- **Widget Tests**: 20% coverage (screens, widgets)
- **Integration Tests**: 10% coverage (user flows)

## Security Considerations

1. **Authentication**: Firebase Auth with secure token management
2. **Data Encryption**: Sensitive data encrypted at rest
3. **API Keys**: Stored in environment variables, not in code
4. **Network Security**: HTTPS only
5. **Input Validation**: All user inputs sanitized
6. **Permission Management**: Minimal required permissions

## Performance Optimization

1. **Image Optimization**: Compress images before upload
2. **Lazy Loading**: Load data on-demand
3. **Caching Strategy**: Multi-level caching (memory, disk, network)
4. **State Management**: Efficient state updates with Riverpod
5. **Build Optimization**: Tree shaking, minification

## Scalability Considerations

1. **Modular Services**: Each service is independent
2. **Firebase Scaling**: Firestore auto-scales
3. **Caching**: Reduce API calls with local caching
4. **Code Organization**: Easy to add new features
5. **State Management**: Riverpod handles complex state efficiently

## Development Workflow

1. **Feature Development**: Create model → service → provider → screen
2. **Testing**: Write tests alongside implementation
3. **Code Review**: PR review before merging
4. **CI/CD**: Automated testing and deployment

## API Integrations

### IBM watsonx
- **Purpose**: NLP for recipe suggestions, visual recognition
- **Endpoint**: `https://us-south.ml.cloud.ibm.com/ml/v1/text/generation`
- **Authentication**: API key in headers

### Spoonacular API
- **Purpose**: Recipe database and search
- **Endpoint**: `https://api.spoonacular.com/recipes`
- **Authentication**: API key in query params

### Firebase
- **Firestore**: Real-time database for user data
- **Storage**: Image storage for scanned items
- **Auth**: User authentication and management

### Price Feeds
- **Purpose**: Store price comparison
- **Integration**: Custom API or web scraping
- **Caching**: Local cache for price history

## Error Handling

```dart
// Service layer error handling
class FirebaseService {
  Future<List<GroceryItem>> getPantryItems() async {
    try {
      final snapshot = await _firestore.collection('pantry_items').get();
      return snapshot.docs.map((doc) => GroceryItem.fromJson(doc.data())).toList();
    } on FirebaseException catch (e) {
      throw Exception('Firebase error: ${e.message}');
    } catch (e) {
      throw Exception('Unknown error: $e');
    }
  }
}

// Provider error handling
final pantryItemsProvider = FutureProvider<List<GroceryItem>>((ref) async {
  try {
    final service = ref.watch(firebaseServiceProvider);
    return await service.getPantryItems();
  } catch (e) {
    // Log error
    print('Error fetching pantry items: $e');
    rethrow;
  }
});
```

## Next Steps

1. Set up the folder structure
2. Configure dependencies in pubspec.yaml
3. Set up Firebase project and configuration
4. Implement core models
5. Build services for external integrations
6. Create Riverpod providers
7. Build UI screens and widgets
8. Integrate IBM watsonx for AI capabilities
9. Implement comprehensive testing
10. Set up CI/CD pipeline

## Summary

This architecture provides:
- ✅ Simple, flat structure for easy navigation
- ✅ Clear separation of concerns
- ✅ Scalable for future features
- ✅ Efficient state management with Riverpod
- ✅ Multiple external service integrations
- ✅ Comprehensive error handling
- ✅ Performance optimizations
- ✅ Security best practices

The straightforward structure makes it easy for developers to understand the codebase quickly and start contributing effectively.