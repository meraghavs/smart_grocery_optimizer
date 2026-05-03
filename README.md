# 🛒 Smart Grocery Optimizer

> A comprehensive cross-platform Flutter app for intelligent grocery management, recipe discovery, smart shopping, and budget tracking.

[![Flutter](https://img.shields.io/badge/Flutter-3.11.5+-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.11.5+-0175C2?logo=dart)](https://dart.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Latest-FFCA28?logo=firebase)](https://firebase.google.com)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

## 📱 Features

### 🎯 Core Capabilities

| Feature | Description | Technology |
|---------|-------------|------------|
| 📸 **Pantry Scanner** | Scan grocery items with camera, OCR text extraction, barcode scanning | Google ML Kit, Camera |
| 🍳 **Recipe Finder** | AI-powered recipe suggestions prioritizing expiring ingredients | IBM watsonx, NLP |
| 🛒 **Shopping List** | Smart list generation with budget awareness and price comparison | AI Algorithms |
| 💰 **Budget Tracker** | Expense tracking, analytics, and spending insights | FL Chart |

## 🏗️ Architecture

### Hybrid Feature-First + Clean Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Presentation Layer                        │
│              (Screens, Widgets, Providers)                   │
└─────────────────────────────────────────────────────────────┘
                            ↓↑
┌─────────────────────────────────────────────────────────────┐
│                      Domain Layer                            │
│           (Entities, Use Cases, Repositories)                │
└─────────────────────────────────────────────────────────────┘
                            ↓↑
┌─────────────────────────────────────────────────────────────┐
│                       Data Layer                             │
│        (Models, Data Sources, Repository Impl)               │
└─────────────────────────────────────────────────────────────┘
                            ↓↑
┌─────────────────────────────────────────────────────────────┐
│                   External Services                          │
│         (Firebase, IBM watsonx, ML Kit)                      │
└─────────────────────────────────────────────────────────────┘
```

### 📂 Project Structure

```
lib/
├── core/                    # Core functionality (config, theme, router, utils)
├── shared/                  # Shared widgets and providers
├── features/                # Feature modules
│   ├── auth/               # Authentication
│   ├── pantry/             # Pantry Scanner
│   ├── recipes/            # Recipe Finder
│   ├── shopping/           # Shopping List
│   ├── budget/             # Budget Tracker
│   └── home/               # Dashboard
└── services/               # External service integrations
```

Each feature follows clean architecture:
```
feature/
├── presentation/           # UI (screens, widgets, providers)
├── domain/                # Business logic (entities, use cases)
└── data/                  # Data access (models, repositories)
```

## 🚀 Quick Start

### Prerequisites

- Flutter SDK 3.11.5+
- Dart SDK 3.11.5+
- Firebase account
- IBM watsonx account

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/smart_grocery_optimizer.git
   cd smart_grocery_optimizer
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**
   - Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
   - Download configuration files:
     - `google-services.json` → `android/app/`
     - `GoogleService-Info.plist` → `ios/Runner/`
   - Enable Authentication, Firestore, and Storage

4. **Configure IBM watsonx**
   - Create `.env` file in project root:
     ```env
     WATSONX_API_KEY=your_api_key
     WATSONX_PROJECT_ID=your_project_id
     WATSONX_URL=https://us-south.ml.cloud.ibm.com
     ```

5. **Generate code**
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

6. **Run the app**
   ```bash
   flutter run
   ```

## 🛠️ Technology Stack

### Core Framework
- **Flutter** - Cross-platform UI framework
- **Dart 3.11+** - Programming language with null safety

### State Management
- **Riverpod 2.x** - State management and dependency injection
- **Freezed** - Immutable data classes
- **Flutter Hooks** - React-like hooks for Flutter

### Backend & Cloud
- **Firebase**
  - Authentication (Email/Password, Google Sign-In)
  - Firestore (NoSQL database)
  - Cloud Storage (Image storage)
  - Analytics & Crashlytics
  - Cloud Messaging (Push notifications)

### AI & Machine Learning
- **IBM watsonx** - Natural Language Processing for recipe suggestions
- **Google ML Kit** - On-device OCR and barcode scanning
- **TensorFlow Lite** - Optional on-device ML models

### Local Storage
- **Hive** - Fast, lightweight NoSQL database
- **Secure Storage** - Encrypted credential storage
- **Shared Preferences** - Simple key-value storage

### UI & Visualization
- **GoRouter** - Declarative routing
- **FL Chart** - Beautiful charts and graphs
- **Lottie** - Smooth animations
- **Cached Network Image** - Efficient image loading

## 📚 Documentation

| Document | Description |
|----------|-------------|
| [📋 PROJECT_SUMMARY.md](PROJECT_SUMMARY.md) | High-level project overview |
| [🏛️ ARCHITECTURE.md](ARCHITECTURE.md) | Detailed architecture documentation |
| [📁 FOLDER_STRUCTURE.md](FOLDER_STRUCTURE.md) | Complete folder structure guide |
| [📦 DEPENDENCIES.md](DEPENDENCIES.md) | Dependencies and setup instructions |
| [💻 IMPLEMENTATION_GUIDE.md](IMPLEMENTATION_GUIDE.md) | Implementation patterns and best practices |

## 🧪 Testing

### Run Tests

```bash
# Unit tests
flutter test

# Widget tests
flutter test test/widget/

# Integration tests
flutter test integration_test/

# Generate coverage report
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

### Test Structure

```
test/
├── unit/              # Unit tests (70% coverage goal)
├── widget/            # Widget tests (20% coverage goal)
└── integration_test/  # E2E tests (10% coverage goal)
```

## 🔧 Development

### Code Generation

```bash
# Watch mode (recommended during development)
flutter pub run build_runner watch --delete-conflicting-outputs

# One-time generation
flutter pub run build_runner build --delete-conflicting-outputs
```

### Linting

```bash
# Analyze code
flutter analyze

# Format code
dart format .
```

### Build

```bash
# Android
flutter build apk --release
flutter build appbundle --release

# iOS
flutter build ios --release

# Web
flutter build web --release
```

## 📱 Platform Support

| Platform | Minimum Version | Status |
|----------|----------------|--------|
| Android | API 21 (5.0) | ✅ Supported |
| iOS | 13.0 | ✅ Supported |
| Web | Modern browsers | ✅ Supported |
| Windows | Windows 10+ | ✅ Supported |
| macOS | 10.14+ | ✅ Supported |
| Linux | Ubuntu 20.04+ | ✅ Supported |

## 🎨 Design Principles

### Clean Architecture
- **Separation of Concerns**: Each layer has a single responsibility
- **Dependency Rule**: Dependencies point inward
- **Testability**: All layers independently testable

### State Management
- **Riverpod Providers**: Centralized state management
- **Immutable State**: Using Freezed for immutable data classes
- **Reactive Updates**: Automatic UI updates on state changes

### Code Quality
- **Type Safety**: Leveraging Dart's null safety
- **Code Generation**: Reducing boilerplate with build_runner
- **Consistent Patterns**: Following established conventions

## 🔐 Security

- ✅ Firebase Authentication with secure token management
- ✅ Encrypted local storage for sensitive data
- ✅ HTTPS-only network communication
- ✅ Input validation and sanitization
- ✅ Minimal permission requests

## 🤝 Contributing

We welcome contributions! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Follow the architecture guidelines in [IMPLEMENTATION_GUIDE.md](IMPLEMENTATION_GUIDE.md)
4. Write tests for new features
5. Commit your changes (`git commit -m 'Add amazing feature'`)
6. Push to the branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

### Coding Standards

- Follow the [Effective Dart](https://dart.dev/guides/language/effective-dart) style guide
- Use the provided linting rules
- Write meaningful commit messages
- Add documentation for public APIs
- Maintain test coverage above 70%

## 📈 Roadmap

### Phase 1: Foundation (Current)
- [x] Architecture design
- [x] Project structure setup
- [x] Documentation
- [ ] Core utilities implementation
- [ ] Firebase integration
- [ ] Authentication flow

### Phase 2: Core Features
- [ ] Pantry Scanner implementation
- [ ] Recipe Finder with AI
- [ ] Shopping List generator
- [ ] Budget Tracker

### Phase 3: Enhancement
- [ ] Offline mode
- [ ] Multi-language support
- [ ] Dark mode
- [ ] Social features
- [ ] Voice commands

### Phase 4: Optimization
- [ ] Performance optimization
- [ ] Advanced analytics
- [ ] Widget support
- [ ] Wearable integration

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👥 Authors

- **Your Name** - *Initial work* - [YourGitHub](https://github.com/yourusername)

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Firebase for backend infrastructure
- IBM watsonx for AI capabilities
- Google ML Kit for on-device ML
- Open source community

## 📞 Support

- 📧 Email: support@smartgroceryoptimizer.com
- 🐛 Issues: [GitHub Issues](https://github.com/yourusername/smart_grocery_optimizer/issues)
- 💬 Discussions: [GitHub Discussions](https://github.com/yourusername/smart_grocery_optimizer/discussions)

---

<div align="center">

**Made with ❤️ using Flutter**

[Website](https://smartgroceryoptimizer.com) • [Documentation](docs/) • [Report Bug](issues/) • [Request Feature](issues/)

</div>
