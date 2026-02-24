# =======================================================
# PROGUARD RULES UNTUK HRIS PRESENSI MOBILE (PT QMS/TS3)
# =======================================================

# 1. MELINDUNGI CORE FLUTTER PLUGINS (Termasuk Image Picker & Camera)
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.plugins.**

# 2. MELINDUNGI FILE PROVIDER ANDROID (PENYEBAB CRASH UTAMA)
-keep class androidx.core.content.FileProvider { *; }
-dontwarn androidx.core.content.FileProvider.**
-keep class io.flutter.plugins.imagepicker.ImagePickerFileProvider { *; }

# 3. MELINDUNGI FIREBASE & MESSAGING
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# 4. MELINDUNGI BASEFLOW (Geolocator & Permission Handler)
-keep class com.baseflow.** { *; }
-dontwarn com.baseflow.**

# 5. MELINDUNGI CRAZECODER (Open Filex)
-keep class com.crazecoder.** { *; }
-dontwarn com.crazecoder.**

# 6. MELINDUNGI IT NOMADS (Flutter Secure Storage)
-keep class com.it_nomads.** { *; }
-dontwarn com.it_nomads.**

# 7. MELINDUNGI SHARMA DHIRAJ (Installed Apps / Anti Fake GPS)
-keep class com.sharmadhiraj.** { *; }
-dontwarn com.sharmadhiraj.**

# 8. MELINDUNGI XAMDESIGN (Safe Device / Anti Mock Location)
-keep class com.xamdesign.** { *; }
-dontwarn com.xamdesign.**

# 9. MELINDUNGI FLUTTER COMMUNITY (Device Info Plus, Connectivity Plus)
-keep class dev.fluttercommunity.** { *; }
-dontwarn dev.fluttercommunity.**

# 10. MELINDUNGI MR FLUTTER (File Picker)
-keep class com.mr.flutter.plugin.filepicker.** { *; }
-dontwarn com.mr.flutter.plugin.filepicker.**

# 11. MELINDUNGI SYSTERM (Flutter Image Compress)
-keep class com.systerm.flutter_image_compress.** { *; }
-dontwarn com.systerm.flutter_image_compress.**

# 12. MELINDUNGI DEXTEROUS (Flutter Local Notifications)
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-dontwarn com.dexterous.flutterlocalnotifications.**