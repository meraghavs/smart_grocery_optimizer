# Smart Grocery Optimizer - Project Summary

## 📋 Overview

**Smart Grocery Optimizer** is a cross-platform Flutter application designed to help users manage their grocery inventory, discover recipes based on expiring items, generate intelligent shopping lists, and track their grocery budget.

## 🎯 Core Features

### 1. 📸 Pantry Scanner
- Camera integration for scanning grocery items
- OCR (Optical Character Recognition) for text extraction from labels
- Barcode scanning for quick product identification
- Manual entry with auto-complete suggestions
- Expiry date tracking and alerts

### 2. 🍳 Expiry-Aware Recipe Finder
- AI-powered recipe suggestions using IBM watsonx
- Prioritizes ingredients nearing expiration
- Ingredient matching algorithm
- Nutritional information display
- Save favorite recipes
- Step-by-step cooking instructions

### 3. 🛒 AI-Powered Shopping List
- Smart list generation based on pantry inventory
- Recurring item suggestions
- Budget-aware recommendations
- Category-based organization
- Price comparison and store suggestions
- Collaborative list sharing

### 4. 💰 Budget Tracker
- Expense tracking and categorization
- Budget goals and alerts
- Spending analytics with charts
- Price history tracking
- Monthly/weekly reports
- Category-wise breakdown

## 🏗️ Architecture

### Hybrid Architecture Approach
- **Feature-First Organization**: Top-level organization by business features
- **Clean Architecture Layers**: Each feature follows presentation → domain → data layers
- **Riverpod State Management**: Centralized, reactive state management
- **Dependency Injection**: Using Riverpod providers throughout

### Technology Stack

#### Core
- **Flutter**: Cross-platform UI framework
- **Dart 3.11+**: Programming language with null safety

#### State Management
- **Riverpod 2.x**: State management and DI
- **Freezed**: Immutable data classes
- **Hooks**: React-like hooks for Flutter

#### Backend & Services
- **Firebase**:
  - Authentication (Email/Password, Google Sign-In)
  - Firestore (NoSQL database)
  - Cloud Storage (Image storage)
  - Analytics & Crashlytics
  - Cloud Messaging (Push notifications)

#### AI & ML
- **IBM watsonx**: NLP for recipe suggestions and smart features
- **Google ML Kit**: On-device OCR and barcode scanning
- **TensorFlow Lite**: Optional on-device ML models

#### Local Storage
- **Hive**: Fast, lightweight local database
- **Secure Storage**: Encrypted credential storage
- **Shared Preferences**: Simple key-value storage

#### UI & UX
- **GoRouter**: Declarative routing
- **Cached Network Image**: Image caching
- **FL Chart**: Data visualization
- **Lottie**: Animations
- **Shimmer**: Loading effects

## 📁 Project Structure

```
smart_grocery_optimizer/
├── lib/
│   ├── main.dart                    # App entry point
│   ├── app.dart                     # Root app widget
│   │
│   ├── core/                        # Core functionality
│   │   ├── config/                  # App configuration
│   │   ├── constants/               # App-wide constants
│   │   ├── theme/                   # Theming
│   │   ├── router/                  # Navigation
│   │   ├── errors/                  # Error handling
│   │   ├── network/                 # Network layer
│   │   ├── storage/                 # Local storage
│   │   ├── utils/                   # Utilities
│   │   └── extensions/              # Dart extensions
│   │
│   ├── shared/                      # Shared components
│   │   ├── widgets/                 # Reusable widgets
│   │   ├── models/                  # Shared models
│   │   └── providers/               # Shared providers
│   │
│   ├── features/                    # Feature modules
│   │   ├── auth/                    # Authentication
│   │   ├── pantry/                  # Pantry Scanner
│   │   ├── recipes/                 # Recipe Finder
│   │   ├── shopping/                # Shopping List
│   │   ├── budget/                  # Budget Tracker
│   │   └── home/                    # Dashboard
│   │
│   └── services/                    # External services
│       ├── firebase/                # Firebase services
│       ├── watsonx/                 # IBM watsonx
│       ├── ml_kit/                  # ML Kit services
│       └── notifications/           # Notifications
│
├── assets/                          # Static assets
│   ├── images/
│   ├── fonts/
│   ├── animations/
│   └── data/
│
├── test/                            # Tests
│   ├── unit/
│   ├── widget/
│   └── fixtures/
│
├── integration_test/                # Integration tests
├── docs/                            # Documentation
└── scripts/                         # Build scripts
```

### Feature Structure (Example: Pantry)

Each feature follows clean architecture:

```
features/pantry/
├── presentation/              # UI Layer
│   ├── screens/              # Full-page screens
│   ├── widgets/              # Feature-specific widgets
│   └── providers/            # State management
│
├── domain/                   # Business Logic Layer
│   ├── entities/             # Business models
│   ├── repositories/         # Repository interfaces
│   └── usecases/             # Business operations
│
└── data/                     # Data Layer
    ├── models/               # DTOs with JSON
    ├── datasources/          # Remote & Local data sources
    └── repositories/         # Repository implementations
```

## 🔄 Data Flow

```
User Action → Widget → Provider (Notifier) → Use Case → Repository → Data Source
                ↓                                                          ↓
            UI Update ← State Change ← Result ← Response ← External API/DB
```

### Example Flow: Adding Pantry Item

1. **User** taps "Add Item" button
2. **Widget** calls `ref.read(pantryControllerProvider.notifier).addItem(item)`
3. **Controller** updates state to loading
4. **Controller** calls `AddPantryItemUseCase`
5. **Use Case** validates business rules
6. **Use Case** calls `PantryRepository.addItem()`
7. **Repository** saves to local database (Hive)
8. **Repository** syncs to Firebase if online
9. **Repository** returns success/failure
10. **Controller** updates state based on result
11. **Widget** rebuilds with new state

## 📦 Key Dependencies

### Production
- `flutter_riverpod: ^2.5.1` - State management
- `firebase_core: ^3.3.0` - Firebase initialization
- `firebase_auth: ^5.1.4` - Authentication
- `cloud_firestore: ^5.2.1` - Database
- `camera: ^0.11.0+2` - Camera access
- `google_mlkit_text_recognition: ^0.13.0` - OCR
- `hive: ^2.2.3` - Local database
- `go_router: ^14.2.0` - Navigation
- `dio: ^5.5.0+1` - HTTP client
- `fl_chart: ^0.68.0` - Charts

### Development
- `build_runner: ^2.4.11` - Code generation
- `freezed: ^2.5.7` - Immutable classes
- `json_serializable: ^6.8.0` - JSON serialization
- `riverpod_generator: ^2.4.3` - Provider generation
- `mocktail: ^1.0.4` - Testing mocks

## 🎨 Design Principles

### 1. Separation of Concerns
- Each layer has a single responsibility
- Business logic isolated in domain layer
- UI logic separated from business logic

### 2. Dependency Rule
- Dependencies point inward (presentation → domain → data)
- Domain layer has no dependencies on outer layers
- Data layer implements domain interfaces

### 3. Testability
- All layers are independently testable
- Use cases contain pure business logic
- Repositories can be mocked for testing

### 4. Scalability
- Feature-first organization allows parallel development
- New features can be added without affecting existing ones
- Modular architecture supports team growth

### 5. Maintainability
- Clear folder structure and naming conventions
- Consistent code patterns across features
- Comprehensive documentation

## 🚀 Getting Started

### Prerequisites
- Flutter SDK 3.11.5 or higher
- Dart SDK 3.11.5 or higher
- Firebase account
- IBM watsonx account
- Android Studio / Xcode (for mobile development)

### Setup Steps

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd smart_grocery_optimizer
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**
   - Create Firebase project
   - Download `google-services.json` (Android)
   - Download `GoogleService-Info.plist` (iOS)
   - Place in respective platform folders

4. **Configure IBM watsonx**
   - Create `.env` file
   - Add watsonx API credentials

5. **Generate code**
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

6. **Run the app**
   ```bash
   flutter run
   ```

## 📚 Documentation

- **[ARCHITECTURE.md](ARCHITECTURE.md)**: Detailed architecture documentation
- **[FOLDER_STRUCTURE.md](FOLDER_STRUCTURE.md)**: Complete folder structure with descriptions
- **[DEPENDENCIES.md](DEPENDENCIES.md)**: All dependencies and setup instructions
- **[IMPLEMENTATION_GUIDE.md](IMPLEMENTATION_GUIDE.md)**: Implementation patterns and best practices

## 🧪 Testing Strategy

### Test Pyramid
- **Unit Tests (70%)**: Use cases, repositories, utilities
- **Widget Tests (20%)**: UI components and screens
- **Integration Tests (10%)**: End-to-end user flows

### Running Tests
```bash
# Unit tests
flutter test

# Integration tests
flutter test integration_test/

# Coverage report
flutter test --coverage
```

## 🔐 Security

- Firebase Authentication for user management
- Secure storage for sensitive data
- HTTPS-only network communication
- Input validation and sanitization
- Permission management (camera, storage)

## 📱 Platform Support

- ✅ Android (API 21+)
- ✅ iOS (13.0+)
- ✅ Web
- ✅ Windows
- ✅ macOS
- ✅ Linux

## 🎯 Development Workflow

1. **Feature Branch**: Create from `develop`
2. **Implementation**: Follow architecture guidelines
3. **Testing**: Write tests alongside code
4. **Code Review**: PR review before merging
5. **CI/CD**: Automated testing and deployment

## 📈 Future Enhancements

- [ ] Meal planning calendar
- [ ] Social features (share recipes, shopping lists)
- [ ] Barcode database integration
- [ ] Voice commands
- [ ] Offline mode improvements
- [ ] Multi-language support
- [ ] Dark mode
- [ ] Widgets for home screen
- [ ] Apple Watch / Wear OS support

## 🤝 Contributing

1. Follow the architecture guidelines
2. Maintain consistent naming conventions
3. Write tests for new features
4. Update documentation
5. Follow the code review process

## 📄 License

[Add your license information here]

## 👥 Team

[Add team information here]

## 📞 Support

[Add support contact information here]

---

**Version**: 1.0.0  
**Last Updated**: 2026-05-02  
**Status**: Planning Phase Complete ✅