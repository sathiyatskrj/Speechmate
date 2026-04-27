# Flutter / Dart keep rules
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# ML Kit
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.vision.** { *; }

# SQLite / sqflite
-keep class org.sqlite.** { *; }
-keep class org.sqlite.database.** { *; }

# Kotlin
-keep class kotlin.** { *; }
-keepclassmembers class **$WhenMappings { *; }

# Suppress warnings for missing classes in release builds
-dontwarn com.google.android.gms.**
-dontwarn okhttp3.**
-dontwarn okio.**
