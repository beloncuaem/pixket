import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/supabase_config.dart';
import '../../core/utils/password_policy.dart';

class AuthRepository {
  /// Deep link đã khai báo trong AndroidManifest.xml (`io.supabase.pixket`).
  static const String recoveryRedirect = 'io.supabase.pixket://login-callback/';

  SupabaseClient? get _client => SupabaseConfig.client;

  User? get currentUser => _client?.auth.currentUser;
  Session? get currentSession => _client?.auth.currentSession;
  Stream<AuthState>? get onAuthStateChange => _client?.auth.onAuthStateChange;

  bool get isConfigured => SupabaseConfig.isInitialized;

  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    String? fullName,
  }) async {
    final client = _client;
    if (client == null) {
      throw Exception(
        'Supabase chưa được cấu hình. Vui lòng kiểm tra file .env',
      );
    }

    final violation = PasswordPolicy.validate(password);
    if (violation != null) {
      throw Exception(violation);
    }

    return await client.auth.signUp(
      email: email.trim(),
      password: password,
      data: fullName != null && fullName.isNotEmpty
          ? {'full_name': fullName.trim()}
          : null,
    );
  }

  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final client = _client;
    if (client == null) {
      throw Exception(
        'Supabase chưa được cấu hình. Vui lòng kiểm tra file .env',
      );
    }

    return await client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<bool> signInWithGoogle() async {
    final client = _client;
    if (client == null) {
      throw Exception(
        'Supabase chưa được cấu hình. Vui lòng kiểm tra file .env',
      );
    }

    if (!await isGoogleProviderEnabled()) {
      throw Exception('provider is not enabled');
    }

    try {
      return await client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb ? null : 'io.supabase.pixket://login-callback/',
      );
    } catch (e) {
      debugPrint('Google Sign-in error: $e');
      rethrow;
    }
  }

  /// Kiểm tra provider Google trên Supabase trước khi mở trình duyệt, tránh
  /// người dùng rơi vào trang JSON "Unsupported provider" khó hiểu.
  Future<bool> isGoogleProviderEnabled() async {
    final url = SupabaseConfig.projectUrl;
    final key = SupabaseConfig.publishableKey;
    if (url == null || key == null) {
      return true;
    }

    try {
      final response = await http
          .get(Uri.parse('$url/auth/v1/settings'), headers: {'apikey': key})
          .timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) {
        return true;
      }

      final data = jsonDecode(response.body);
      if (data is! Map<String, dynamic>) {
        return true;
      }

      final external = data['external'];
      if (external is Map<String, dynamic> && external['google'] is bool) {
        return external['google'] as bool;
      }
    } catch (error) {
      debugPrint('Could not check Google provider status: $error');
    }

    // Không chặn đăng nhập nếu bước kiểm tra gặp sự cố mạng.
    return true;
  }

  Future<void> signOut() async {
    final client = _client;
    if (client != null) {
      await client.auth.signOut();
    }
  }

  Future<void> resetPassword(
    String email, {
    String redirectTo = recoveryRedirect,
  }) async {
    final client = _client;
    if (client == null) {
      throw Exception(
        'Supabase chưa được cấu hình. Vui lòng kiểm tra file .env',
      );
    }
    await client.auth.resetPasswordForEmail(
      email.trim(),
      redirectTo: redirectTo,
    );
  }

  Future<void> updatePassword(String newPassword) async {
    final client = _client;
    if (client == null) {
      throw Exception(
        'Supabase chưa được cấu hình. Vui lòng kiểm tra file .env',
      );
    }
    final violation = PasswordPolicy.validate(newPassword);
    if (violation != null) {
      throw Exception(violation);
    }
    await client.auth.updateUser(UserAttributes(password: newPassword));
  }
}
