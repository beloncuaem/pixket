import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixket/core/config/secure_session_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const sessionKey = 'sb-demo-supabase-co-auth-token';
  const legacySession = '{"currentSession":{"refresh_token":"rt-abc"}}';

  late Map<String, String> secure;

  Future<SecureSessionLocalStorage> buildStorage({
    Map<String, String> legacyValues = const {},
  }) async {
    SharedPreferences.setMockInitialValues(legacyValues);
    FlutterSecureStorage.setMockInitialValues(secure);
    final prefs = await SharedPreferences.getInstance();
    return SecureSessionLocalStorage(
      persistSessionKey: sessionKey,
      legacyPreferences: () async => prefs,
    );
  }

  setUp(() {
    secure = {};
  });

  group('SecureSessionLocalStorage', () {
    test('migrate session cũ từ SharedPreferences vào Keystore rồi xóa bản plaintext', () async {
      final storage = await buildStorage(
        legacyValues: {sessionKey: legacySession},
      );

      await storage.initialize();

      expect(secure[sessionKey], legacySession);
      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getString(sessionKey),
        isNull,
        reason: 'bản plaintext phải bị xóa sau migration',
      );
    });

    test('không ghi đè session đang có trong Keystore bằng bản cũ', () async {
      secure[sessionKey] = 'newer-session';
      final storage = await buildStorage(
        legacyValues: {sessionKey: legacySession},
      );

      await storage.initialize();

      expect(secure[sessionKey], 'newer-session');
    });

    test('persistSession / accessToken / hasAccessToken round-trip', () async {
      final storage = await buildStorage();

      expect(await storage.hasAccessToken(), isFalse);
      expect(await storage.accessToken(), isNull);

      await storage.persistSession(legacySession);

      expect(secure[sessionKey], legacySession);
      expect(await storage.hasAccessToken(), isTrue);
      expect(await storage.accessToken(), legacySession);
    });

    test('removePersistedSession xóa khỏi Keystore', () async {
      secure[sessionKey] = legacySession;
      final storage = await buildStorage();

      await storage.removePersistedSession();

      expect(secure.containsKey(sessionKey), isFalse);
      expect(await storage.accessToken(), isNull);
    });

    test('initialize không ném khi không có session cũ', () async {
      final storage = await buildStorage();
      await expectLater(storage.initialize(), completes);
      expect(secure, isEmpty);
    });
  });

  group('SecureGotrueAsyncStorage', () {
    test('lưu PKCE verifier có prefix, không va chạm key session', () async {
      secure[sessionKey] = legacySession;
      FlutterSecureStorage.setMockInitialValues(secure);
      final storage = SecureGotrueAsyncStorage();

      await storage.setItem(key: 'codeVerifier', value: 'verifier-123');

      expect(secure['pkce_codeVerifier'], 'verifier-123');
      expect(secure[sessionKey], legacySession);
      expect(await storage.getItem(key: 'codeVerifier'), 'verifier-123');

      await storage.removeItem(key: 'codeVerifier');

      expect(secure.containsKey('pkce_codeVerifier'), isFalse);
      expect(await storage.getItem(key: 'codeVerifier'), isNull);
    });
  });
}
