import 'package:shared_preferences/shared_preferences.dart';

/// Cài đặt cấp thiết bị, đọc được cả khi chưa đăng nhập (cờ onboarding,
/// theme, khoá hiệu ứng). Từng nằm trong SQLite; chuyển sang
/// shared_preferences vì sqflite không chạy được trên web.
///
/// Giá trị bool vẫn lưu dạng chuỗi 'true'/'false' để giữ đúng ngữ nghĩa cũ
/// và để migration từ DB SQLite cũ chỉ là chép chuỗi nguyên trạng.
class AppSettingsRepository {
  Future<String?> getString(String key) async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(key);
  }

  Future<void> setString(String key, String value) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(key, value);
  }

  Future<bool> getBool(String key, {required bool fallback}) async {
    final saved = await getString(key);
    if (saved == 'true') return true;
    if (saved == 'false') return false;
    return fallback;
  }

  Future<void> setBool(String key, bool value) =>
      setString(key, value ? 'true' : 'false');

  Future<void> remove(String key) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(key);
  }
}
