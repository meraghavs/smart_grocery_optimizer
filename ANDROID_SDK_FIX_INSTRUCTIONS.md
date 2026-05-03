# IMMEDIATE FIX REQUIRED - Android SDK Version

## 🚨 Current Status
Your app **cannot build** because `google_ml_kit` requires Android SDK 26, but your project is configured for SDK 24.

## ✅ The Fix (2 minutes)

### Step 1: Edit build.gradle.kts

**File to edit:** `android/app/build.gradle.kts`

**Line to change:** Line 28

**Current code (line 28):**
```kotlin
minSdk = flutter.minSdkVersion
```

**Change to:**
```kotlin
minSdk = 26
```

### Step 2: Clean and Rebuild

Run these commands in your terminal:
```bash
cd /home/ubuntu/grocery-optimizer/smart_grocery_optimizer
flutter clean
flutter pub get
flutter run -d emulator-5554
```

## 📝 Complete Context

Here's what the `defaultConfig` section should look like after the change:

```kotlin
defaultConfig {
    // TODO: Specify your own unique Application ID
    applicationId = "com.example.smart_grocery_optimizer"
    // You can update the following values to match your application needs.
    // For more information, see: https://flutter.dev/to/review-gradle-config.
    minSdk = 26  // ← CHANGED from flutter.minSdkVersion
    targetSdk = flutter.targetSdkVersion
    versionCode = flutter.versionCode
    versionName = flutter.versionName
}
```

## 🎯 Why This Fix is Needed

- `google_ml_kit` package includes `google_mlkit_genai_prompt`
- This sub-package requires Android 8.0+ (SDK 26)
- Your project currently uses `flutter.minSdkVersion` which defaults to 24
- Must explicitly override to 26

## 📊 Impact

**Before:** Supports Android 7.0+ (99% of devices)
**After:** Supports Android 8.0+ (95% of devices)

This is acceptable for a modern app using ML features.

## 🔄 Alternative: Switch to Code Mode

If you'd like me to make this change for you:

1. Switch to **Code mode**
2. I'll update the build.gradle.kts file
3. I'll also implement the complete scanner screen

Would you like to switch to Code mode now?