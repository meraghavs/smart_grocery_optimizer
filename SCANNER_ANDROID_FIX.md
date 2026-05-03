# Android SDK Version Fix for Scanner Implementation

## 🚨 Issue

The `google_ml_kit` package (specifically `google_mlkit_genai_prompt`) requires **Android SDK 26** or higher, but the project is currently configured with **minSdkVersion 24**.

## Error Message

```
uses-sdk:minSdkVersion 24 cannot be smaller than version 26 declared in library [:google_mlkit_genai_prompt]
```

## ✅ Solution

Update the Android minimum SDK version from 24 to 26 in the build configuration.

## 📝 Implementation Steps

### Step 1: Update build.gradle.kts

**File:** [`android/app/build.gradle.kts`](android/app/build.gradle.kts)

Find the `defaultConfig` section and **replace** `minSdk = flutter.minSdkVersion` with `minSdk = 26`:

**BEFORE:**
```kotlin
defaultConfig {
    applicationId = "com.example.smart_grocery_optimizer"
    minSdk = flutter.minSdkVersion  // ← This references Flutter's default (24)
    targetSdk = flutter.targetSdkVersion
    versionCode = flutter.versionCode
    versionName = flutter.versionName
}
```

**AFTER:**
```kotlin
defaultConfig {
    applicationId = "com.example.smart_grocery_optimizer"
    minSdk = 26  // ← CHANGE THIS: Explicitly set to 26 (required by google_ml_kit)
    targetSdk = flutter.targetSdkVersion
    versionCode = flutter.versionCode
    versionName = flutter.versionName
}
```

**Complete context (lines 23-32 of build.gradle.kts):**
```kotlin
defaultConfig {
    // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
    applicationId = "com.example.smart_grocery_optimizer"
    // You can update the following values to match your application needs.
    // For more information, see: https://flutter.dev/to/review-gradle-config.
    minSdk = 26  // ← CHANGE from flutter.minSdkVersion to 26
    targetSdk = flutter.targetSdkVersion
    versionCode = flutter.versionCode
    versionName = flutter.versionName
}
```

### Step 2: Clean and Rebuild

After making the change, clean the build and rebuild:

```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter run
```

## 📊 Impact Analysis

### Device Compatibility

**Before (minSdk 24):**
- Android 7.0 (Nougat) and above
- Released: August 2016
- Market share: ~99% of active devices

**After (minSdk 26):**
- Android 8.0 (Oreo) and above
- Released: August 2017
- Market share: ~95% of active devices

### Recommendation

✅ **Proceed with minSdk 26** because:
1. Required by Google ML Kit dependencies
2. Still covers 95%+ of active Android devices
3. Android 7.x devices are 8+ years old
4. Most modern features require Android 8.0+

## 🔍 Alternative Solutions (Not Recommended)

### Option 1: Use tools:overrideLibrary (Not Recommended)
```xml
<!-- In AndroidManifest.xml -->
<uses-sdk tools:overrideLibrary="com.google_mlkit_genai_prompt" />
```
⚠️ **Warning:** May cause runtime crashes on Android 7.x devices

### Option 2: Remove google_ml_kit (Not Viable)
This would eliminate OCR functionality, which is the core requirement.

### Option 3: Use Alternative OCR Library
- Firebase ML Kit (deprecated)
- Tesseract OCR (lower accuracy, more complex setup)
- ML Kit standalone packages (same SDK requirement)

## ✅ Recommended Action

**Update minSdk to 26** - This is the standard solution and aligns with modern Android development practices.

## 📋 Updated Implementation Checklist

### Phase 0: Android Configuration (NEW - MUST DO FIRST)
- [ ] Update `minSdk = 26` in `android/app/build.gradle.kts`
- [ ] Run `flutter clean`
- [ ] Run `flutter pub get`
- [ ] Verify build succeeds with `flutter build apk --debug`

### Phase 1: Platform Setup
- [ ] Add camera permission to Android manifest
- [ ] Add camera usage description to iOS Info.plist
- [ ] Verify dependencies in pubspec.yaml

### Phase 2-4: Continue with original plan...

## 🧪 Testing After Fix

1. **Build Test:**
   ```bash
   flutter build apk --debug
   ```
   Should complete without errors

2. **Run Test:**
   ```bash
   flutter run -d emulator-5554
   ```
   Should launch successfully

3. **Verify ML Kit:**
   - App should start without crashes
   - Camera permission should be requestable
   - OCR functionality should work

## 📚 Additional Resources

- [Android API Levels](https://developer.android.com/guide/topics/manifest/uses-sdk-element)
- [Google ML Kit Requirements](https://developers.google.com/ml-kit/vision/text-recognition/android)
- [Flutter Android Configuration](https://docs.flutter.dev/deployment/android)

## 🎯 Summary

**Required Change:**
```kotlin
// In android/app/build.gradle.kts
defaultConfig {
    minSdk = 26  // Changed from 24
}
```

**Why:**
- Google ML Kit requires Android 8.0+
- Standard requirement for modern ML features
- Minimal impact on device compatibility

**Next Steps:**
1. Make the change
2. Clean and rebuild
3. Continue with scanner implementation