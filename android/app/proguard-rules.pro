# Add project specific ProGuard rules here.
# You can control the set of applied configuration files using the
# proguardFiles setting in build.gradle.

# Keep all classes for Flutter
-keep class io.flutter.** { *; }
-keep class com.google.firebase.** { *; }
-keep class com.razorpay.** { *; }

# Google Play Core - Keep classes for deferred components
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# Flutter deferred components support
-keep class io.flutter.embedding.engine.deferredcomponents.** { *; }
-keep class io.flutter.embedding.engine.loader.** { *; }

# Keep Play Core classes that might be missing
-keep class com.google.android.play.core.splitcompat.** { *; }
-keep class com.google.android.play.core.splitinstall.** { *; }
-keep class com.google.android.play.core.tasks.** { *; }

# Suppress warnings for optional Play Core classes
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**

# Suppress other warnings
-dontwarn java.lang.invoke.**
-dontwarn **$serializer
-dontwarn org.slf4j.**
-dontwarn org.apache.log4j.**

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep Parcelable implementations
-keep class * implements android.os.Parcelable {
  public static final android.os.Parcelable$Creator *;
}

# R8 optimization rules
-allowaccessmodification
-repackageclasses