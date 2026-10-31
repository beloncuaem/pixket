import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../data/repositories/auth_repository.dart';

enum AuthStatus { initial, authenticated, unauthenticated, loading, error }

class AppAuthState {
  final AuthStatus status;
  final sb.User? user;
  final String? errorMessage;
  final bool isConfigured;
  final bool recoveryMode;

  const AppAuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
    this.isConfigured = false,
    this.recoveryMode = false,
  });

  AppAuthState copyWith({
    AuthStatus? status,
    sb.User? user,
    String? errorMessage,
    bool? isConfigured,
    bool? recoveryMode,
    bool clearUser = false,
  }) {
    return AppAuthState(
      status: status ?? this.status,
      user: clearUser ? null : user ?? this.user,
      errorMessage: errorMessage,
      isConfigured: isConfigured ?? this.isConfigured,
      recoveryMode: recoveryMode ?? this.recoveryMode,
    );
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

class AuthNotifier extends StateNotifier<AppAuthState> {
  final AuthRepository _repo;
  StreamSubscription<sb.AuthState>? _authSubscription;

  AuthNotifier(this._repo)
    : super(
        AppAuthState(
          isConfigured: _repo.isConfigured,
          user: _repo.currentUser,
          status: _repo.currentUser != null
              ? AuthStatus.authenticated
              : AuthStatus.unauthenticated,
        ),
      ) {
    _listenAuth();
  }

  void _listenAuth() {
    final stream = _repo.onAuthStateChange;
    if (stream != null) {
      _authSubscription = stream.listen((data) {
        final session = data.session;
        if (data.event == sb.AuthChangeEvent.passwordRecovery) {
          // Deep link đã đổi code thành session: ưu tiên màn đặt lại mật khẩu.
          state = state.copyWith(
            status: AuthStatus.authenticated,
            user: session?.user,
            recoveryMode: true,
            errorMessage: null,
          );
          return;
        }
        if (session != null) {
          state = state.copyWith(
            status: AuthStatus.authenticated,
            user: session.user,
            errorMessage: null,
          );
        } else {
          state = state.copyWith(
            status: AuthStatus.unauthenticated,
            clearUser: true,
            recoveryMode: false,
            errorMessage: null,
          );
        }
      });
    }
  }

  Future<bool> signInWithEmail(String email, String password) async {
    try {
      state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
      final res = await _repo.signInWithEmail(email: email, password: password);
      if (res.user != null) {
        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: res.user,
        );
        return true;
      }
      return false;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: _humanReadableError(e.toString()),
      );
      return false;
    }
  }

  Future<bool> signUpWithEmail(
    String email,
    String password, {
    String? fullName,
  }) async {
    try {
      state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
      final res = await _repo.signUpWithEmail(
        email: email,
        password: password,
        fullName: fullName,
      );
      // Khi Supabase bật "Confirm email", signUp trả về user nhưng session
      // vẫn null; chỉ coi là đăng nhập khi đã có session thật.
      if (res.session != null && res.user != null) {
        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: res.user,
        );
        return true;
      }
      final pendingEmail = res.user?.email;
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        user: null,
        errorMessage: pendingEmail != null
            ? 'Tài khoản đã tạo. Kiểm tra email $pendingEmail, bấm link xác nhận rồi quay lại đăng nhập.'
            : 'Đăng ký chưa hoàn tất. Vui lòng thử lại.',
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: _humanReadableError(e.toString()),
      );
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    try {
      state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
      final launched = await _repo.signInWithGoogle();
      if (state.status == AuthStatus.loading) {
        // OAuth hoàn tất trong trình duyệt; trả UI về trạng thái cũ để nút
        // đăng nhập không bị kẹt spinner khi người dùng quay lại app.
        state = state.copyWith(
          status: state.user != null
              ? AuthStatus.authenticated
              : AuthStatus.unauthenticated,
        );
      }
      return launched;
    } catch (e) {
      state = state.copyWith(
        status: state.user != null
            ? AuthStatus.authenticated
            : AuthStatus.unauthenticated,
        errorMessage: _humanReadableError(e.toString()),
      );
      return false;
    }
  }

  /// Gửi email đặt lại mật khẩu. Luôn trả về thông điệp trung tính để
  /// không tiết lộ email nào tồn tại trong hệ thống.
  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
      await _repo.resetPassword(email);
      state = state.copyWith(
        status: state.user != null
            ? AuthStatus.authenticated
            : AuthStatus.unauthenticated,
        errorMessage: null,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        status: state.user != null
            ? AuthStatus.authenticated
            : AuthStatus.unauthenticated,
        errorMessage: _humanReadableError(e.toString()),
      );
      return false;
    }
  }

  Future<bool> setNewPassword(String password) async {
    try {
      state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
      await _repo.updatePassword(password);
      state = state.copyWith(
        status: AuthStatus.authenticated,
        recoveryMode: false,
        errorMessage: null,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.authenticated,
        recoveryMode: true,
        errorMessage: _humanReadableError(e.toString()),
      );
      return false;
    }
  }

  void exitRecoveryMode() {
    state = state.copyWith(recoveryMode: false);
  }

  Future<void> signOut() async {
    await _repo.signOut();
    state = state.copyWith(status: AuthStatus.unauthenticated, clearUser: true);
  }

  String _humanReadableError(String raw) {
    if (raw.contains('Invalid login credentials')) {
      return 'Email hoặc mật khẩu không chính xác.';
    }
    if (raw.contains('Email not confirmed')) {
      return 'Email chưa được xác nhận. Mở hộp thư và bấm link xác nhận rồi đăng nhập lại.';
    }
    if (raw.contains('Email rate limit exceeded')) {
      return 'Bạn thử quá nhiều lần. Vui lòng đợi vài phút rồi thử lại.';
    }
    if (raw.contains('User already registered')) {
      return 'Email này đã được đăng ký tài khoản.';
    }
    if (raw.contains('Password should be at least')) {
      return 'Mật khẩu phải có ít nhất 6 ký tự.';
    }
    if (raw.contains('AuthSessionMissingException') ||
        raw.contains('Session missing') ||
        raw.contains('valid session')) {
      return 'Phiên đặt lại mật khẩu đã hết hạn. Hãy bấm "Quên mật khẩu" một lần nữa.';
    }
    if (raw.contains('For security purposes') ||
        raw.contains('requires reauthentication')) {
      return 'Cần đăng nhập lại trước khi đổi mật khẩu.';
    }
    if (raw.contains('Supabase chưa được cấu hình')) {
      return 'Chưa cấu hình Supabase. Vui lòng thêm URL và Anon Key vào file .env.';
    }
    if (raw.contains('provider is not enabled')) {
      return 'Google chưa được bật trong Supabase. Hãy bật Google provider trong Authentication > Providers.';
    }
    if (raw.contains('redirect_uri') || raw.contains('redirect_to')) {
      return 'URL chuyển hướng chưa được cho phép trong Supabase. Thêm io.supabase.chitieu://login-callback/ vào Redirect URLs.';
    }
    if (raw.contains('canceled') || raw.contains('cancelled')) {
      return 'Bạn đã hủy đăng nhập Google.';
    }
    if (raw.contains('SocketException') ||
        raw.contains('Failed host lookup') ||
        raw.contains('network')) {
      return 'Không thể kết nối máy chủ. Kiểm tra mạng và thử lại.';
    }
    return raw.replaceAll('Exception: ', '').replaceAll('AuthException: ', '');
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AppAuthState>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return AuthNotifier(repo);
});
