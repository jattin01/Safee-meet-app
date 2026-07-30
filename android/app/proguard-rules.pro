# Stripe Android SDK references its "push provisioning" classes (adding a
# card directly to Google Wallet) even though this app doesn't use that
# feature and doesn't pull in the optional Google Wallet library it needs.
# R8 can't resolve those references during release minification — silence
# them instead of adding an unused dependency just to satisfy R8.
-dontwarn com.stripe.android.pushProvisioning.**
-keep class com.stripe.android.pushProvisioning.** { *; }

# Standard Stripe Android SDK keep rules (see
# https://github.com/flutter-stripe/flutter_stripe#android for context).
-keep class com.stripe.android.** { *; }
-dontwarn com.reactnativestripesdk.**
-keep class com.reactnativestripesdk.** { *; }
