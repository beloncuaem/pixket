import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Session đăng nhập (access token + refresh token) và PKCE code verifier được
/// chuyển từ SharedPreferences plaintext sang Android Keystore / iOS Keychain.
///
/// `supabase_flutter` mặc định dùng `SharedPreferencesLocalStorage`, nghĩa là
/// `refresh_token` nằm dạng JSON đọc được trong `shared_prefs/*.xml`. Trên thiết
/// bị root, hoặc với iOS khi Keychain item bị đồng bộ lên iCloud backup, kẻ tấn
/// công lấy được refresh token là có phiên hợp lệ của người dùng — RLS không còn
/// ý nghĩa gì. Hai class dưới thay đúng lớp lưu trữ đó.
class SecureSessionLocalStorage extends LocalStorage {
  SecureSessionLocalStorage({
    required this.persistSessionKey,
    FlutterSecureStorage? storage,
    Future<SharedPreferences> Function()? legacyPreferences,
  }) : _storage = storage ?? _defaultStorage,
       _legacyPreferences = legacyPreferences ?? SharedPreferences.getInstance;

  /// Key mà supabase_flutter vẫn dùng cho SharedPreferences; giữ nguyên để
  /// migration đọc đúng giá trị cũ.
  final String persistSessionKey;

  final FlutterSecureStorage _storage;
  final Future<SharedPreferences> Function() _legacyPreferences;

  static const FlutterSecureStorage _defaultStorage = FlutterSecureStorage(
    // first_unlock_this_device: item không migrate sang thiết bị khác và
    // không bị đưa vào iCloud backup.
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  @override
  Future<void> initialize() => _migrateLegacySession();

  /// Đọc session cũ từ SharedPreferences một lần, chuyển vào Keystore rồi xóa
  /// bản plaintext. Người dùng đang đăng nhập không bị văng ra.
  Future<void> _migrateLegacySession() async {
    try {
      final secureValue = await _storage.read(key: persistSessionKey);
      final preferences = await _legacyPreferences();
      final legacyValue = preferences.getString(persistSessionKey);

      if (secureValue == null && legacyValue != null) {
        await _storage.write(key: persistSessionKey, value: legacyValue);
      }
      if (legacyValue != null) {
        await preferences.remove(persistSessionKey);
      }
    } catch (error, stackTrace) {
      // Migration lỗi thì vẫn để app chạy: session hiện tại trong bộ nhớ còn
      // dùng được, chỉ mất khả năng tự đăng nhập lại lần sau.
      debugPrint('Bỏ qua migration session: $error\n$stackTrace');
    }
  }

  @override
  Future<bool> hasAccessToken() async {
    return await accessToken() != null;
  }

  @override
  Future<String?> accessToken() async {
    try {
      return await _storage.read(key: persistSessionKey);
    } catch (error) {
      debugPrint('Không đọc được session từ Keystore: $error');
      return null;
    }
  }

  @override
  Future<void> persistSession(String persistSessionString) async {
    await _storage.write(key: persistSessionKey, value: persistSessionString);
  }

  @override
  Future<void> removePersistedSession() async {
    try {
      await _storage.delete(key: persistSessionKey);
    } catch (error) {
      debugPrint('Không xóa được session trong Keystore: $error');
    }
  }
}

/// PKCE code verifier cũng đang nằm plaintext trong SharedPreferences theo mặc
/// định của supabase_flutter, nên chuyển sang Keystore/Keychain cùng chỗ.
class SecureGotrueAsyncStorage extends GotrueAsyncStorage {
  SecureGotrueAsyncStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? SecureSessionLocalStorage._defaultStorage;

  final FlutterSecureStorage _storage;

  /// Thêm prefix để key của gotrue không va chạm với key session.
  String _scoped(String key) => 'pkce_$key';

  @override
  Future<String?> getItem({required String key}) async {
    try {
      return await _storage.read(key: _scoped(key));
    } catch (error) {
      debugPrint('Không đọc được PKCE verifier: $error');
      return null;
    }
  }

  @override
  Future<void> setItem({required String key, required String value}) async {
    await _storage.write(key: _scoped(key), value: value);
  }

  @override
  Future<void> removeItem({required String key}) async {
    try {
      await _storage.delete(key: _scoped(key));
    } catch (error) {
      debugPrint('Không xóa được PKCE verifier: $error');
    }
  }
}
