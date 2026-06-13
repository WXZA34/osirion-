# Flutter rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Google Play Services & Firebase
-keep class com.google.android.gms.** { *; }
-keep class com.google.firebase.** { *; }

# Prevent obfuscation of R classes for resources
-keep class **.R$* { *; }

# Ignore warnings for missing Google Play Core classes (common in Flutter R8 builds)
-dontwarn com.google.android.play.core.**
