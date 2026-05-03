# Smart Grocery Optimizer - Folder Structure

## Root Directory Structure

```
smart_grocery_optimizer/
├── lib/                          # Main application code
├── test/                         # Unit and widget tests
├── integration_test/             # Integration tests
├── assets/                       # Static assets
├── android/                      # Android platform code
├── ios/                          # iOS platform code
├── web/                          # Web platform code
├── linux/                        # Linux platform code
├── macos/                        # macOS platform code
├── windows/                      # Windows platform code
├── pubspec.yaml                  # Dependencies and project config
├── analysis_options.yaml         # Linter rules
└── README.md                     # Project overview
```

## Detailed lib/ Structure

```
lib/
├── main.dart                     # App entry point
│
├── models/                       # Data models
│   ├── grocery_item.dart         # Pantry item model
│   ├── recipe.dart               # Recipe model
│   ├── budget.dart               # Budget/expense model
│   ├── shopping_list.dart        # Shopping list model
│   ├── user.dart                 # User model
│   └── nutrition.dart            # Nutrition information model
│
├── services/                     # External service integrations
│   ├── watson_service.dart       # IBM watsonx NLP + Visual Recognition
│   ├── firebase_service.dart     # Firestore CRUD operations
│   ├── recipe_api.dart           # Spoonacular API integration
│   ├── price_api.dart            # Store price feeds integration
│   ├── auth_service.dart         # Firebase Authentication
│   ├── storage_service.dart      # Firebase Storage for images
│   ├── ocr_service.dart          # OCR text recognition
│   ├── barcode_service.dart      # Barcode scanning
│   └── notification_service.dart # Push notifications
│
├── screens/                      # App screens
│   ├── pantry_screen.dart        # Pantry management screen
│   ├── shopping_list_screen.dart # Shopping list screen
│   ├── recipe_screen.dart        # Recipe discovery screen
│   ├── budget_screen.dart        # Budget tracking screen
│   ├── home_screen.dart          # Dashboard/home screen
│   ├── login_screen.dart         # Login screen
│   ├── register_screen.dart      # Registration screen
│   ├── profile_screen.dart       # User profile screen
│   ├── scanner_screen.dart       # Camera scanner screen
│   └── recipe_detail_screen.dart # Recipe details screen
│
├── widgets/                      # Reusable UI components
│   ├── custom_button.dart        # Custom button widget
│   ├── custom_text_field.dart    # Custom text input
│   ├── grocery_item_card.dart    # Pantry item card
│   ├── recipe_card.dart          # Recipe card widget
│   ├── shopping_item_card.dart   # Shopping list item card
│   ├── budget_chart.dart         # Budget visualization chart
│   ├── expiry_badge.dart         # Expiry date badge
│   ├── loading_indicator.dart    # Loading spinner
│   ├── empty_state.dart          # Empty state widget
│   └── camera_preview.dart       # Camera preview widget
│
├── state/                        # Riverpod providers
│   ├── auth_provider.dart        # Authentication state
│   ├── pantry_provider.dart      # Pantry items state
│   ├── recipe_provider.dart      # Recipes state
│   ├── shopping_provider.dart    # Shopping list state
│   ├── budget_provider.dart      # Budget state
│   └── theme_provider.dart       # Theme state
│
├── utils/                        # Utility functions
│   ├── date_helpers.dart         # Date formatting and calculations
│   ├── formatters.dart           # Currency, number formatters
│   ├── validators.dart           # Input validation
│   ├── constants.dart            # App constants
│   ├── colors.dart               # Color palette
│   ├── text_styles.dart          # Text styles
│   └── logger.dart               # Logging utility
│
└── config/                       # App configuration
    ├── app_config.dart           # Environment configs
    ├── firebase_config.dart      # Firebase initialization
    ├── routes.dart               # App routing
    └── theme.dart                # App theme configuration
```

## Assets Structure

```
assets/
├── images/                       # Image assets
│   ├── logo.png
│   ├── placeholder.png
│   ├── empty_pantry.png
│   ├── empty_recipes.png
│   └── empty_shopping.png
│
├── icons/                        # Icon assets
│   ├── pantry_icon.png
│   ├── recipe_icon.png
│   ├── shopping_icon.png
│   └── budget_icon.png
│
└── fonts/                        # Custom fonts
    ├── Roboto-Regular.ttf
    ├── Roboto-Bold.ttf
    └── Roboto-Medium.ttf
```

## Test Structure

```
test/
├── models/                       # Model tests
│   ├── grocery_item_test.dart
│   ├── recipe_test.dart
│   └── budget_test.dart
│
├── services/                     # Service tests
│   ├── watson_service_test.dart
│   ├── firebase_service_test.dart
│   └── recipe_api_test.dart
│
├── widgets/                      # Widget tests
│   ├── grocery_item_card_test.dart
│   ├── recipe_card_test.dart
│   └── custom_button_test.dart
│
└── utils/                        # Utility tests
    ├── date_helpers_test.dart
    └── validators_test.dart
```

## Integration Test Structure

```
integration_test/
├── app_test.dart                 # Full app integration test
├── pantry_flow_test.dart         # Pantry feature flow
├── recipe_flow_test.dart         # Recipe feature flow
├── shopping_flow_test.dart       # Shopping feature flow
└── budget_flow_test.dart         # Budget feature flow
```

## File Descriptions

### Models (`lib/models/`)

#### `grocery_item.dart`
```dart
class GroceryItem {
  final String id;
  final String name;
  final String category;
  final int quantity;
  final String unit;
  final DateTime expiryDate;
  final DateTime purchaseDate;
  final double price;
  final String? imageUrl;
  final String? barcode;
}
```

#### `recipe.dart`
```dart
class Recipe {
  final String id;
  final String title;
  final String description;
  final List<String> ingredients;
  final List<String> instructions;
  final int prepTime;
  final int cookTime;
  final int servings;
  final String? imageUrl;
  final Nutrition? nutrition;
  final List<String> tags;
}
```

#### `budget.dart`
```dart
class Budget {
  final String id;
  final String userId;
  final double amount;
  final String category;
  final DateTime date;
  final String description;
  final String type; // 'expense' or 'income'
}
```

#### `shopping_list.dart`
```dart
class ShoppingList {
  final String id;
  final String name;
  final List<ShoppingItem> items;
  final DateTime createdAt;
  final bool isCompleted;
  final double? estimatedTotal;
}

class ShoppingItem {
  final String id;
  final String name;
  final int quantity;
  final String unit;
  final bool isChecked;
  final double? price;
  final String? category;
}
```

### Services (`lib/services/`)

#### `watson_service.dart`
- IBM watsonx NLP integration
- Recipe suggestions based on ingredients
- Visual recognition for product identification
- Natural language processing for queries

#### `firebase_service.dart`
- Firestore CRUD operations
- Real-time data synchronization
- Batch operations
- Query helpers

#### `recipe_api.dart`
- Spoonacular API integration
- Recipe search and filtering
- Ingredient matching
- Nutritional information retrieval

#### `price_api.dart`
- Store price feeds integration
- Price comparison
- Historical price data
- Store location services

#### `auth_service.dart`
- Firebase Authentication
- Email/password login
- Google Sign-In
- User session management

#### `ocr_service.dart`
- Google ML Kit text recognition
- Extract text from images
- Parse expiry dates
- Product name extraction

#### `barcode_service.dart`
- Barcode/QR code scanning
- Product lookup
- UPC/EAN code processing

### Screens (`lib/screens/`)

#### `pantry_screen.dart`
- Display all pantry items
- Filter by category, expiry date
- Search functionality
- Add/edit/delete items
- Scan new items

#### `shopping_list_screen.dart`
- Create and manage shopping lists
- AI-powered suggestions
- Check off items
- Price estimation
- Share lists

#### `recipe_screen.dart`
- Browse recipes
- Search by ingredients
- Filter by dietary preferences
- AI recipe suggestions
- Save favorites

#### `budget_screen.dart`
- Track expenses
- View spending analytics
- Set budget goals
- Category breakdown
- Monthly reports

#### `scanner_screen.dart`
- Camera preview
- OCR text extraction
- Barcode scanning
- Manual entry option

### Widgets (`lib/widgets/`)

Reusable UI components used across multiple screens:
- Cards for displaying items
- Custom buttons and inputs
- Charts and visualizations
- Loading states
- Empty states

### State (`lib/state/`)

Riverpod providers for state management:
- Authentication state
- Data fetching and caching
- UI state (loading, error)
- User preferences

### Utils (`lib/utils/`)

Helper functions and utilities:
- Date formatting (e.g., "2 days until expiry")
- Currency formatting
- Input validation
- Constants and enums
- Color schemes
- Text styles

## Naming Conventions

### Files
- Use lowercase with underscores: `grocery_item.dart`
- Screens end with `_screen.dart`
- Services end with `_service.dart`
- Providers end with `_provider.dart`
- Widgets are descriptive: `custom_button.dart`

### Classes
- Use PascalCase: `GroceryItem`, `RecipeCard`
- Screens: `PantryScreen`, `RecipeScreen`
- Services: `WatsonService`, `FirebaseService`
- Providers: `authProvider`, `pantryProvider`

### Variables
- Use camelCase: `groceryItem`, `recipeList`
- Constants: `SCREAMING_SNAKE_CASE`
- Private: prefix with `_` (e.g., `_privateMethod`)

## Best Practices

1. **Keep it Simple**: Flat structure for easy navigation
2. **Single Responsibility**: Each file has one clear purpose
3. **Reusability**: Common widgets in `widgets/` folder
4. **Separation**: Business logic in services, UI in screens
5. **State Management**: Centralized with Riverpod providers
6. **Testing**: Mirror lib/ structure in test/ folder

## Adding New Features

### Example: Adding a "Meal Planner" Feature

1. **Create Model**
   ```dart
   // lib/models/meal_plan.dart
   class MealPlan {
     final String id;
     final DateTime date;
     final List<Recipe> meals;
   }
   ```

2. **Create Service**
   ```dart
   // lib/services/meal_plan_service.dart
   class MealPlanService {
     Future<void> saveMealPlan(MealPlan plan) async { }
     Future<List<MealPlan>> getMealPlans() async { }
   }
   ```

3. **Create Screen**
   ```dart
   // lib/screens/meal_plan_screen.dart
   class MealPlanScreen extends StatelessWidget { }
   ```

4. **Create Provider**
   ```dart
   // lib/state/meal_plan_provider.dart
   final mealPlanProvider = StateNotifierProvider<MealPlanNotifier, List<MealPlan>>(...);
   ```

5. **Add Widgets** (if needed)
   ```dart
   // lib/widgets/meal_plan_card.dart
   class MealPlanCard extends StatelessWidget { }
   ```

## Summary

This folder structure provides:
- ✅ Simple, flat organization
- ✅ Easy to navigate and understand
- ✅ Clear separation of concerns
- ✅ Scalable for future features
- ✅ Follows Flutter best practices
- ✅ Easy to test and maintain

The structure is straightforward and perfect for a team of any size, making it easy to find files and understand the codebase quickly.