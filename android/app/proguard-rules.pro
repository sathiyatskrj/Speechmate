# Flutter / Dart keep rules
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# ── Play Core (Flutter deferred components — dontwarn since we don't use them) ──
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }

# ── Firebase ─────────────────────────────────────────────────────────────────
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# ── ML Kit ───────────────────────────────────────────────────────────────────
-keep class com.google.mlkit.** { *; }
-keep class com.google_mlkit_** { *; }
-keep class com.google.android.gms.vision.** { *; }

# Suppress missing ML Kit language-specific recognizers (we only bundle Latin + Devanagari)
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**

# ── SQLite / sqflite ─────────────────────────────────────────────────────────
-keep class org.sqlite.** { *; }
-keep class org.sqlite.database.** { *; }

# ── Kotlin ───────────────────────────────────────────────────────────────────
-keep class kotlin.** { *; }
-keepclassmembers class **$WhenMappings { *; }

# ── OkHttp / Dio (translator package) ────────────────────────────────────────
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }
