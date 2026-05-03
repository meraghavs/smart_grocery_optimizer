# Keep ML Kit Text Recognition classes
-keep class com.google.mlkit.vision.text.** { *; }
-keep class com.google.android.gms.internal.mlkit_vision_text_common.** { *; }

# Keep Chinese text recognition
-keep class com.google.mlkit.vision.text.chinese.** { *; }

# Keep Devanagari text recognition
-keep class com.google.mlkit.vision.text.devanagari.** { *; }

# Keep Japanese text recognition
-keep class com.google.mlkit.vision.text.japanese.** { *; }

# Keep Korean text recognition
-keep class com.google.mlkit.vision.text.korean.** { *; }

# Keep all ML Kit classes
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.internal.mlkit** { *; }

# Don't warn about missing classes
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**