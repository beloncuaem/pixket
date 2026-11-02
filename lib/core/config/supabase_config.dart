import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'secure_session_storage.dart';

class SupabaseConfig {
  static bool _isInitialized = false;
  static bool get isInitialized => _isInitialized;
  static String? _initializationError;
  static String? get initializationError => _initializationError;
  static String? _projectUrl;
  static String? _publishableKey;
  static String? get projectUrl => _projectUrl;
  static String? get publishableKey => _publishableKey;

  static SupabaseClient? get client {
    if (!_isInitialized) return null;
    return Supabase.instance.client;
  }

  static Future<void> initialize() async {
    _isInitialized = false;
    _initializationError = null;

    try {
      await dotenv.load(fileName: '.env');
    } catch (error, stackTrace) {
      _initializationError = 'Không thể đọc file cấu hình .env.';
      debugPrint('Could not load .env: $error\n$stackTrace');
      return;
    }

    final url = (dotenv.env['SUPABASE_URL'] ?? '').trim();
    final publishableKey = (dotenv.env['SUPABASE_ANON_KEY'] ?? '').trim();
    final uri = Uri.tryParse(url);

    if (url.isNotEmpty &&
        publishableKey.isNotEmpty &&
        !url.contains('your-project.supabase.co') &&
        uri != null &&
        uri.hasScheme &&
        uri.host.isNotEmpty) {
      _projectUrl = url;
      _publishableKey = publishableKey;
      try {
        await Supabase.initialize(
          url: url,
          publishableKey: publishableKey,
          authOptions: _authOptions(uri),
        );
        _isInitialized = true;
        debugPrint('Supabase initialized successfully.');
      } catch (error, stackTrace) {
        // Supabase creates its client before restoring a previous auth session.
        // A failed session restore must not disable email/password sign-in when
        // that client is already available.
        try {
          _isInitialized = Supabase.instance.isInitialized;
        } catch (_) {
          _isInitialized = false;
        }

        if (!_isInitialized) {
          _initializationError = 'Không thể khởi tạo Supabase trên thiết bị.';
        }
        debugPrint('Error initializing Supabase: $error\n$stackTrace');
      }
    } else {
      _initializationError =
          'SUPABASE_URL hoặc SUPABASE_ANON_KEY trong .env không hợp lệ.';
      debugPrint('Supabase credentials are not configured correctly.');
    }
  }

  /// Trên mobile, session và PKCE verifier đi vào Android Keystore / iOS
  /// Keychain thay vì SharedPreferences plaintext. Web giữ mặc định vì
  /// localStorage là lựa chọn duy nhất ở đó.
  static FlutterAuthClientOptions _authOptions(Uri uri) {
    if (kIsWeb) return const FlutterAuthClientOptions();

    // Trùng đúng key mà supabase_flutter dùng cho SharedPreferences, để
    // migration trong SecureSessionLocalStorage đọc được bản ghi cũ và người
    // dùng đang đăng nhập không bị văng ra.
    final persistSessionKey = 'sb-${uri.host.split('.').first}-auth-token';

    return FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
      persistSession: true,
      autoRefreshToken: true,
      localStorage: SecureSessionLocalStorage(
        persistSessionKey: persistSessionKey,
      ),
      pkceAsyncStorage: SecureGotrueAsyncStorage(),
    );
  }
}
