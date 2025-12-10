# Keep OkHttp3 classes
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }
-dontwarn okhttp3.**

# Keep uCrop classes
-keep class com.yalantis.ucrop.** { *; }
-dontwarn com.yalantis.ucrop.**

# Keep Okio (often used with OkHttp)
-keep class okio.** { *; }
-dontwarn okio.**
