# Flutter / engine
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep annotations & generic signatures (used by several plugins via reflection)
-keepattributes *Annotation*, Signature, InnerClasses, EnclosingMethod

# flutter_local_notifications: GSON-based scheduled-notification serialization
-keep class com.dexterous.** { *; }
-keep class com.google.gson.** { *; }
-keepclassmembers class * { @com.google.gson.annotations.SerializedName <fields>; }

# workmanager background callback dispatcher
-keep class dev.fluttercommunity.workmanager.** { *; }

# Suppress notes for missing optional classes pulled in by dependencies
-dontwarn javax.annotation.**

# Suppress warnings for missing Google Play Core Split Install classes referenced by Flutter PlayStoreSplitApplication
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**
