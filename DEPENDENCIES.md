# Smart Grocery Optimizer - Dependencies Guide

## Required Dependencies for pubspec.yaml

### State Management
```yaml
# Riverpod ecosystem
flutter_riverpod: ^2.5.1
riverpod_annotation: ^2.3.5
hooks_riverpod: ^2.5.1
flutter_hooks: ^0.20.5
```

### Firebase
```yaml
# Firebase core
firebase_core: ^3.3.0
firebase_auth: ^5.1.4
cloud_firestore: ^5.2.1
firebase_storage: ^12.1.3
firebase_analytics: ^11.2.1
firebase_crashlytics: ^4.0.4
firebase_messaging: ^15.0.4

# Google Sign-In
google_sign_in: ^6.2.1
```

### Camera & Image Processing
```yaml
# Camera and image handling
camera: ^0.11.0+2
image_picker: ^1.1.2
image: ^4.2.0
image_cropper: ^8.0.2

# ML Kit for OCR
google_mlkit_text_recognition: ^0.13.0
google_mlkit_barcode_scanning: ^0.12.0
```

### Local Storage
```yaml
# Hive for local database
hive: ^2.2.3
hive_flutter: ^1.1.0
path_provider: ^2.1.3

# Secure storage
flutter_secure_storage: ^9.2.2

# Shared preferences
shared_preferences: ^2.2.3
```

### Networking
```yaml
# HTTP client
dio: ^5.5.0+1
retrofit: ^4.1.0
pretty_dio_logger: ^1.4.0

# Connectivity
connectivity_plus: ^6.0.3
```

### UI & UX
```yaml
# Navigation
go_router: ^14.2.0

# UI components
cached_network_image: ^3.3.1
shimmer: ^3.0.0
flutter_svg: ^2.0.10+1
lottie: ^3.1.2

# Charts and visualization
fl_chart: ^0.68.0

# Animations
animations: ^2.0.11

# Icons
cupertino_icons: ^1.0.8
font_awesome_flutter: ^10.7.0
```

### Utilities
```yaml
# Date and time
intl: ^0.19.0
timeago: ^3.7.0

# UUID generation
uuid: ^4.4.2

# JSON serialization
json_annotation: ^4.9.0
freezed_annotation: ^2.4.4

# Functional programming
dartz: ^0.10.1

# Logging
logger: ^2.4.0

# Permission handling
permission_handler: ^11.3.1

# URL launcher
url_launcher: ^6.3.0

# Share functionality
share_plus: ^10.0.0

# Device info
device_info_plus: ^10.1.2

# Package info
package_info_plus: ^8.0.2
```

### AI & ML
```yaml
# IBM watsonx (via HTTP client - no official package)
# Will use dio for API calls

# Optional: TensorFlow Lite for on-device ML
tflite_flutter: ^0.10.4
```

### Dev Dependencies
```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  
  # Linting
  flutter_lints: ^6.0.0
  very_good_analysis: ^6.0.0
  
  # Code generation
  build_runner: ^2.4.11
  freezed: ^2.5.7
  json_serializable: ^6.8.0
  riverpod_generator: ^2.4.3
  retrofit_generator: ^8.1.2
  hive_generator: ^2.0.1
  
  # Testing
  mocktail: ^1.0.4
  integration_test:
    sdk: flutter
  
  # Icons
  flutter_launcher_icons: ^0.13.1
  
  # Native splash
  flutter_native_splash: ^2.4.1
```

## Complete pubspec.yaml

```yaml
name: smart_grocery_optimizer
description: A smart grocery management app with pantry scanner, recipe finder, shopping list, and budget tracker.
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: ^3.11.5

dependencies:
  flutter:
    sdk: flutter

  # State Management
  flutter_riverpod: ^2.5.1
  riverpod_annotation: ^2.3.5
  hooks_riverpod: ^2.5.1
  flutter_hooks: ^0.20.5

  # Firebase
  firebase_core: ^3.3.0
  firebase_auth: ^5.1.4
  cloud_firestore: ^5.2.1
  firebase_storage: ^12.1.3
  firebase_analytics: ^11.2.1
  firebase_crashlytics: ^4.0.4
  firebase_messaging: ^15.0.4
  google_sign_in: ^6.2.1

  # Camera & Image Processing
  camera: ^0.11.0+2
  image_picker: ^1.1.2
  image: ^4.2.0
  image_cropper: ^8.0.2
  google_mlkit_text_recognition: ^0.13.0
  google_mlkit_barcode_scanning: ^0.12.0

  # Local Storage
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  path_provider: ^2.1.3
  flutter_secure_storage: ^9.2.2
  shared_preferences: ^2.2.3

  # Networking
  dio: ^5.5.0+1
  retrofit: ^4.1.0
  pretty_dio_logger: ^1.4.0
  connectivity_plus: ^6.0.3

  # UI & UX
  go_router: ^14.2.0
  cached_network_image: ^3.3.1
  shimmer: ^3.0.0
  flutter_svg: ^2.0.10+1
  lottie: ^3.1.2
  fl_chart: ^0.68.0
  animations: ^2.0.11
  cupertino_icons: ^1.0.8
  font_awesome_flutter: ^10.7.0

  # Utilities
  intl: ^0.19.0
  timeago: ^3.7.0
  uuid: ^4.4.2
  json_annotation: ^4.9.0
  freezed_annotation: ^2.4.4
  dartz: ^0.10.1
  logger: ^2.4.0
  permission_handler: ^11.3.1
  url_launcher: ^6.3.0
  share_plus: ^10.0.0
  device_info_plus: ^10.1.2
  package_info_plus: ^8.0.2

  # Optional: TensorFlow Lite
  tflite_flutter: ^0.10.4

dev_dependencies:
  flutter_test:
    sdk: flutter
  
  # Linting
  flutter_lints: ^6.0.0
  very_good_analysis: ^6.0.0
  
  # Code generation
  build_runner: ^2.4.11
  freezed: ^2.5.7
  json_serializable: ^6.8.0
  riverpod_generator: ^2.4.3
  retrofit_generator: ^8.1.2
  hive_generator: ^2.0.1
  
  # Testing
  mocktail: ^1.0.4
  integration_test:
    sdk: flutter
  
  # Icons and splash
  flutter_launcher_icons: ^0.13.1
  flutter_native_splash: ^2.4.1

flutter:
  uses-material-design: true

  # Assets
  assets:
    - assets/images/
    - assets/images/logo/
    - assets/images/icons/
    - assets/images/illustrations/
    - assets/images/onboarding/
    - assets/animations/
    - assets/data/

  # Fonts
  fonts:
    - family: Roboto
      fonts:
        - asset: assets/fonts/Roboto-Regular.ttf
        - asset: assets/fonts/Roboto-Bold.ttf
          weight: 700
        - asset: assets/fonts/Roboto-Medium.ttf
          weight: 500

# Flutter Launcher Icons Configuration
flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/images/logo/logo.png"
  adaptive_icon_background: "#FFFFFF"
  adaptive_icon_foreground: "assets/images/logo/logo.png"

# Flutter Native Splash Configuration
flutter_native_splash:
  color: "#FFFFFF"
  image: assets/images/logo/splash_logo.png
  android: true
  ios: true
  web: true
```

## Dependency Categories Explained

### 1. State Management (Riverpod)
- **flutter_riverpod**: Core Riverpod package for state management
- **riverpod_annotation**: Annotations for code generation
- **hooks_riverpod**: Integration with flutter_hooks
- **flutter_hooks**: React-like hooks for Flutter

### 2. Firebase Backend
- **firebase_core**: Firebase initialization
- **firebase_auth**: User authentication
- **cloud_firestore**: NoSQL database
- **firebase_storage**: File storage
- **firebase_analytics**: Usage analytics
- **firebase_crashlytics**: Crash reporting
- **firebase_messaging**: Push notifications
- **google_sign_in**: Google authentication

### 3. Camera & ML
- **camera**: Camera access and control
- **image_picker**: Pick images from gallery
- **image**: Image manipulation
- **image_cropper**: Crop images
- **google_mlkit_text_recognition**: OCR for text extraction
- **google_mlkit_barcode_scanning**: Barcode/QR code scanning

### 4. Local Storage
- **hive**: Fast NoSQL database
- **hive_flutter**: Hive Flutter integration
- **path_provider**: Access to file system paths
- **flutter_secure_storage**: Encrypted storage for sensitive data
- **shared_preferences**: Simple key-value storage

### 5. Networking
- **dio**: HTTP client with interceptors
- **retrofit**: Type-safe REST client
- **pretty_dio_logger**: HTTP request/response logging
- **connectivity_plus**: Network connectivity status

### 6. UI Components
- **go_router**: Declarative routing
- **cached_network_image**: Image caching
- **shimmer**: Loading shimmer effect
- **flutter_svg**: SVG rendering
- **lottie**: Lottie animations
- **fl_chart**: Charts and graphs
- **animations**: Material motion animations

### 7. Utilities
- **intl**: Internationalization and formatting
- **timeago**: Relative time formatting
- **uuid**: UUID generation
- **json_annotation**: JSON serialization annotations
- **freezed_annotation**: Immutable classes annotations
- **dartz**: Functional programming (Either, Option)
- **logger**: Logging utility
- **permission_handler**: Runtime permissions
- **url_launcher**: Launch URLs
- **share_plus**: Share content
- **device_info_plus**: Device information
- **package_info_plus**: App package information

### 8. Code Generation
- **build_runner**: Code generation runner
- **freezed**: Generate immutable classes
- **json_serializable**: Generate JSON serialization
- **riverpod_generator**: Generate Riverpod providers
- **retrofit_generator**: Generate REST clients
- **hive_generator**: Generate Hive adapters

### 9. Testing
- **flutter_test**: Flutter testing framework
- **mocktail**: Mocking library
- **integration_test**: Integration testing

### 10. Linting
- **flutter_lints**: Official Flutter lints
- **very_good_analysis**: Strict linting rules

## IBM watsonx Integration

Since there's no official Flutter package for IBM watsonx, we'll use **dio** to make HTTP requests to the watsonx API.

### Example watsonx Service Implementation

```dart
// lib/services/watsonx/watsonx_service.dart
import 'package:dio/dio.dart';

class WatsonxService {
  final Dio _dio;
  final String _apiKey;
  final String _projectId;
  
  WatsonxService({
    required Dio dio,
    required String apiKey,
    required String projectId,
  })  : _dio = dio,
        _apiKey = apiKey,
        _projectId = projectId;

  Future<String> generateRecipeSuggestions(List<String> ingredients) async {
    try {
      final response = await _dio.post(
        'https://us-south.ml.cloud.ibm.com/ml/v1/text/generation',
        data: {
          'input': 'Suggest recipes using: ${ingredients.join(", ")}',
          'parameters': {
            'max_new_tokens': 500,
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
      
      return response.data['results'][0]['generated_text'];
    } catch (e) {
      throw Exception('Failed to generate recipe suggestions: $e');
    }
  }
}
```

## Environment Configuration

Create a `.env` file for sensitive configuration:

```env
# Firebase
FIREBASE_API_KEY=your_firebase_api_key
FIREBASE_APP_ID=your_firebase_app_id
FIREBASE_MESSAGING_SENDER_ID=your_sender_id
FIREBASE_PROJECT_ID=your_project_id

# IBM watsonx
WATSONX_API_KEY=your_watsonx_api_key
WATSONX_PROJECT_ID=your_watsonx_project_id
WATSONX_URL=https://us-south.ml.cloud.ibm.com

# API Keys
RECIPE_API_KEY=your_recipe_api_key
```

Use **flutter_dotenv** package to load environment variables:

```yaml
dependencies:
  flutter_dotenv: ^5.1.0
```

## Installation Commands

```bash
# Install dependencies
flutter pub get

# Generate code
flutter pub run build_runner build --delete-conflicting-outputs

# Generate icons
flutter pub run flutter_launcher_icons

# Generate splash screen
flutter pub run flutter_native_splash:create

# Run code generation in watch mode (during development)
flutter pub run build_runner watch --delete-conflicting-outputs
```

## Platform-Specific Setup

### Android (android/app/build.gradle)
```gradle
android {
    compileSdkVersion 34
    
    defaultConfig {
        minSdkVersion 21
        targetSdkVersion 34
    }
}
```

### iOS (ios/Podfile)
```ruby
platform :ios, '13.0'
```

### Permissions

#### Android (android/app/src/main/AndroidManifest.xml)
```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

#### iOS (ios/Runner/Info.plist)
```xml
<key>NSCameraUsageDescription</key>
<string>We need camera access to scan grocery items</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>We need photo library access to select images</string>
```

## Next Steps

1. Copy the complete pubspec.yaml configuration
2. Run `flutter pub get` to install dependencies
3. Set up Firebase project and download configuration files
4. Configure IBM watsonx API credentials
5. Run code generation commands
6. Start implementing features