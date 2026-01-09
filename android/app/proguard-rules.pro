# Flutter Stripe - Keep Push Provisioning classes
-dontwarn com.stripe.android.pushProvisioning.**
-keep class com.stripe.android.pushProvisioning.** { *; }

# React Native Stripe SDK (used internally by flutter_stripe)
-dontwarn com.reactnativestripesdk.**
-keep class com.reactnativestripesdk.** { *; }

# Stripe general rules
-keep class com.stripe.android.** { *; }
-dontwarn com.stripe.android.**

# Keep Stripe models
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}
