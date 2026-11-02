# Keep rules cho R8/ProGuard của bản release Pixket.
#
# Flutter tự thêm rule cho io.flutter.** qua flutter-gradle-plugin, nhưng các
# plugin gọi Java từ Dart channel bằng reflection thì phải giữ tay. Thiếu các
# rule dưới là lỗi chỉ lộ ra lúc runtime (notification không hiển thị, share
# crash, secure storage đọc sai), không hiện ở bước build.

# --- Flutter engine + plugin host ---
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# --- flutter_local_notifications (18.x) ---
# Lịch notification được serialize JSON bằng Gson rồi đọc lại sau khi app chết;
# nếu R8 đổi tên field thì notification mất nội dung hoặc crash khi khôi phục.
-keep class com.dexterous.flutterlocalnotifications.models.** { *; }
-keep class com.dexterous.flutterlocalnotifications.isolate.** { *; }
-keepattributes Signature
-keepattributes *Annotation*
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken
-keep,allowobfuscation,allowshrinking class com.google.gson.reflect.TypeToken
-if @com.google.gson.annotations.SerializedName class * { *; }
-keep class com.google.gson.** { *; }
-dontwarn com.google.gson.**
-dontwarn org.codehaus.mojo.animal_sniffer.*

# --- share_plus (13.x) ---
-keep class dev.fluttercommunity.plus.share.** { *; }

# --- flutter_secure_storage (11.x) ---
# Cipher chọn theo options lúc runtime; giữ nguyên để session đã lưu không bị
# mất sau khi nâng cấp app.
-keep class com.it_nomads.fluttersecurestorage.** { *; }

# --- permission_handler (11.x) ---
-keep class com.baseflow.permissionhandler.** { *; }

# --- camera / image_picker ---
-keep class io.flutter.plugins.camera.** { *; }
-keep class io.flutter.plugins.imagepicker.** { *; }

# AndroidX + desugaring đã bật trong build.gradle.kts.
-dontwarn java.lang.invoke.StringConcatFactory
-dontwarn javax.lang.model.element.Modifier
