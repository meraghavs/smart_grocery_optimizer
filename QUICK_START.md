# 🚀 Smart Grocery Optimizer - Quick Start Guide

## 📋 Table of Contents
1. [Prerequisites](#prerequisites)
2. [Initial Setup](#initial-setup)
3. [Firebase Configuration](#firebase-configuration)
4. [IBM watsonx Setup](#ibm-watsonx-setup)
5. [Running the App](#running-the-app)
6. [Next Steps](#next-steps)

---

## Prerequisites

### Required Software

| Software | Minimum Version | Download Link |
|----------|----------------|---------------|
| Flutter SDK | 3.11.5 | [flutter.dev](https://flutter.dev/docs/get-started/install) |
| Dart SDK | 3.11.5 | Included with Flutter |
| Git | Latest | [git-scm.com](https://git-scm.com/downloads) |
| VS Code / Android Studio | Latest | [code.visualstudio.com](https://code.visualstudio.com/) |

### Platform-Specific Requirements

#### For Android Development
- Android Studio
- Android SDK (API 21+)
- Java Development Kit (JDK) 11+

#### For iOS Development (macOS only)
- Xcode 13+
- CocoaPods
- iOS Simulator or physical device

### Accounts Needed
- ✅ Firebase account (free tier available)
- ✅ IBM Cloud account (for watsonx)
- ✅ Google account (for Firebase)

---

## Initial Setup

### Step 1: Verify Flutter Installation

```bash
# Check Flutter installation
flutter doctor

# Expected output should show:
# ✓ Flutter (Channel stable, 3.11.5+)
# ✓ Android toolchain
# ✓ Xcode (macOS only)
# ✓ VS Code / Android Studio
```

### Step 2: Clone the Repository

```bash
# Clone the repository
git clone https://github.com/yourusername/smart_grocery_optimizer.git

# Navigate to project directory
cd smart_grocery_optimizer

# Verify project structure
ls -la
```

### Step 3: Install Dependencies

```bash
# Get all Flutter packages
flutter pub get

# This will download all dependencies listed in pubspec.yaml
# Wait for completion (may take a few minutes)
```

---

## Firebase Configuration

### Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project"
3. Enter project name: `smart-grocery-optimizer`
4. Enable Google Analytics (recommended)
5. Click "Create project"

### Step 2: Add Android App

1. In Firebase Console, click "Add app" → Android icon
2. Enter package name: `com.example.smart_grocery_optimizer`
3. Download `google-services.json`
4. Place file in: `android/app/google-services.json`

### Step 3: Add iOS App (if developing for iOS)

1. In Firebase Console, click "Add app" → iOS icon
2. Enter bundle ID: `com.example.smartGroceryOptimizer`
3. Download `GoogleService-Info.plist`
4. Place file in: `ios/Runner/GoogleService-Info.plist`

### Step 4: Enable Firebase Services

In Firebase Console, enable these services:

#### Authentication
1. Go to Authentication → Sign-in method
2. Enable "Email/Password"
3. Enable "Google" sign-in

#### Firestore Database
1. Go to Firestore Database
2. Click "Create database"
3. Start in "Test mode" (for development)
4. Choose location closest to your users

#### Storage
1. Go to Storage
2. Click "Get started"
3. Start in "Test mode" (for development)

#### Cloud Messaging (Optional)
1. Go to Cloud Messaging
2. Note down the Server Key (for push notifications)

### Step 5: Update Firebase Security Rules

#### Firestore Rules
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // User data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Pantry items
    match /pantry_items/{itemId} {
      allow read, write: if request.auth != null;
    }
    
    // Recipes
    match /recipes/{recipeId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
    
    // Shopping lists
    match /shopping_lists/{listId} {
      allow read, write: if request.auth != null;
    }
    
    // Budget data
    match /budgets/{budgetId} {
      allow read, write: if request.auth != null;
    }
  }
}
```

#### Storage Rules
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /users/{userId}/{allPaths=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    match /pantry_images/{allPaths=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

---

## IBM watsonx Setup

### Step 1: Create IBM Cloud Account

1. Go to [IBM Cloud](https://cloud.ibm.com/)
2. Sign up for a free account
3. Verify your email

### Step 2: Create watsonx Project

1. Navigate to watsonx.ai
2. Click "Create project"
3. Name: `smart-grocery-optimizer`
4. Note down your Project ID

### Step 3: Get API Credentials

1. Go to "Manage" → "Access (IAM)"
2. Click "API keys"
3. Create new API key
4. Copy and save the API key securely

### Step 4: Configure Environment Variables

Create a `.env` file in the project root:

```env
# Firebase Configuration
FIREBASE_API_KEY=your_firebase_api_key
FIREBASE_APP_ID=your_firebase_app_id
FIREBASE_MESSAGING_SENDER_ID=your_sender_id
FIREBASE_PROJECT_ID=smart-grocery-optimizer

# IBM watsonx Configuration
WATSONX_API_KEY=your_watsonx_api_key
WATSONX_PROJECT_ID=your_watsonx_project_id
WATSONX_URL=https://us-south.ml.cloud.ibm.com

# Optional: Recipe API (if using external recipe API)
RECIPE_API_KEY=your_recipe_api_key
```

**⚠️ IMPORTANT**: Add `.env` to `.gitignore` to keep credentials secure!

```bash
# Add to .gitignore
echo ".env" >> .gitignore
```

### Step 5: Install flutter_dotenv

Add to `pubspec.yaml`:
```yaml
dependencies:
  flutter_dotenv: ^5.1.0
```

Then run:
```bash
flutter pub get
```

---

## Running the App

### Step 1: Generate Code

```bash
# Generate Freezed, Riverpod, and JSON serialization code
flutter pub run build_runner build --delete-conflicting-outputs

# Or use watch mode during development
flutter pub run build_runner watch --delete-conflicting-outputs
```

### Step 2: Run on Device/Emulator

#### Android
```bash
# List available devices
flutter devices

# Run on connected device
flutter run

# Run in release mode
flutter run --release
```

#### iOS (macOS only)
```bash
# Install pods
cd ios && pod install && cd ..

# Run on simulator
flutter run

# Run on physical device
flutter run --release
```

#### Web
```bash
# Run on Chrome
flutter run -d chrome

# Build for production
flutter build web
```

### Step 3: Verify Installation

The app should launch and show:
1. ✅ Splash screen
2. ✅ Login/Register screen
3. ✅ No Firebase connection errors
4. ✅ Smooth navigation

---

## Next Steps

### 1. Explore the Documentation

| Document | Purpose |
|----------|---------|
| [README.md](README.md) | Project overview |
| [ARCHITECTURE.md](ARCHITECTURE.md) | Architecture details |
| [FOLDER_STRUCTURE.md](FOLDER_STRUCTURE.md) | Folder organization |
| [IMPLEMENTATION_GUIDE.md](IMPLEMENTATION_GUIDE.md) | Development guide |
| [DEPENDENCIES.md](DEPENDENCIES.md) | Dependencies reference |

### 2. Start Development

Follow this order for implementation:

```
1. Core Setup
   ├── Configure theme and constants
   ├── Set up routing
   └── Create shared widgets

2. Authentication Feature
   ├── Login screen
   ├── Register screen
   └── Profile management

3. Pantry Feature
   ├── Camera integration
   ├── OCR implementation
   └── Item management

4. Recipe Feature
   ├── Recipe search
   ├── AI suggestions
   └── Recipe details

5. Shopping Feature
   ├── List creation
   ├── AI recommendations
   └── List sharing

6. Budget Feature
   ├── Expense tracking
   ├── Analytics
   └── Budget goals
```

### 3. Development Workflow

```bash
# 1. Create feature branch
git checkout -b feature/pantry-scanner

# 2. Implement feature following architecture

# 3. Run tests
flutter test

# 4. Check code quality
flutter analyze
dart format .

# 5. Commit changes
git add .
git commit -m "feat: implement pantry scanner"

# 6. Push and create PR
git push origin feature/pantry-scanner
```

### 4. Testing

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/features/pantry/domain/usecases/add_item_usecase_test.dart

# Generate coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

---

## Troubleshooting

### Common Issues

#### Issue: "Flutter command not found"
```bash
# Add Flutter to PATH
export PATH="$PATH:`pwd`/flutter/bin"

# Or add to ~/.bashrc or ~/.zshrc
echo 'export PATH="$PATH:/path/to/flutter/bin"' >> ~/.bashrc
source ~/.bashrc
```

#### Issue: "Google Services plugin error"
```bash
# Make sure google-services.json is in correct location
ls android/app/google-services.json

# Clean and rebuild
flutter clean
flutter pub get
flutter run
```

#### Issue: "CocoaPods not installed" (iOS)
```bash
# Install CocoaPods
sudo gem install cocoapods

# Install pods
cd ios
pod install
cd ..
```

#### Issue: "Build runner conflicts"
```bash
# Delete conflicting outputs
flutter pub run build_runner build --delete-conflicting-outputs

# Clean build cache
flutter clean
flutter pub get
```

#### Issue: "Firebase initialization error"
```bash
# Verify Firebase configuration files exist
ls android/app/google-services.json
ls ios/Runner/GoogleService-Info.plist

# Check Firebase console for correct package name/bundle ID
```

---

## Development Tools

### Recommended VS Code Extensions

- **Flutter** - Official Flutter extension
- **Dart** - Official Dart extension
- **Awesome Flutter Snippets** - Code snippets
- **Flutter Riverpod Snippets** - Riverpod snippets
- **Error Lens** - Inline error display
- **GitLens** - Git integration
- **Todo Tree** - TODO highlighting

### Useful Commands

```bash
# Hot reload (during development)
# Press 'r' in terminal

# Hot restart
# Press 'R' in terminal

# Open DevTools
# Press 'd' in terminal

# Clear build cache
flutter clean

# Update dependencies
flutter pub upgrade

# Check for outdated packages
flutter pub outdated

# Analyze code
flutter analyze

# Format code
dart format .

# Generate icons
flutter pub run flutter_launcher_icons

# Generate splash screen
flutter pub run flutter_native_splash:create
```

---

## Getting Help

### Resources

- 📚 [Flutter Documentation](https://flutter.dev/docs)
- 📚 [Riverpod Documentation](https://riverpod.dev)
- 📚 [Firebase Documentation](https://firebase.google.com/docs)
- 📚 [IBM watsonx Documentation](https://www.ibm.com/docs/en/watsonx)

### Community

- 💬 [Flutter Discord](https://discord.gg/flutter)
- 💬 [Stack Overflow](https://stackoverflow.com/questions/tagged/flutter)
- 💬 [Reddit r/FlutterDev](https://reddit.com/r/FlutterDev)

### Project Support

- 🐛 [Report Issues](https://github.com/yourusername/smart_grocery_optimizer/issues)
- 💡 [Feature Requests](https://github.com/yourusername/smart_grocery_optimizer/issues)
- 📧 Email: support@smartgroceryoptimizer.com

---

## Success Checklist

Before starting development, ensure:

- [ ] Flutter doctor shows no issues
- [ ] Firebase project created and configured
- [ ] Firebase configuration files in place
- [ ] IBM watsonx credentials obtained
- [ ] `.env` file created with all credentials
- [ ] Dependencies installed (`flutter pub get`)
- [ ] Code generation completed
- [ ] App runs successfully on device/emulator
- [ ] No Firebase connection errors
- [ ] Documentation reviewed

---

**🎉 Congratulations! You're ready to start building Smart Grocery Optimizer!**

For detailed implementation guidance, refer to [IMPLEMENTATION_GUIDE.md](IMPLEMENTATION_GUIDE.md).