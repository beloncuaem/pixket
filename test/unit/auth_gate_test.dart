import 'package:flutter_test/flutter_test.dart';
import 'package:chi_tieu/app.dart';
import 'package:chi_tieu/providers/auth_provider.dart';

void main() {
  group('decideHomeTarget', () {
    test('Hiện login khi chưa đăng nhập', () {
      expect(
        decideHomeTarget(
          onboardingComplete: true,
          auth: const AppAuthState(status: AuthStatus.unauthenticated),
        ),
        HomeTarget.login,
      );
    });

    test('Vẫn hiện login sau khi đăng nhập thất bại (status error)', () {
      expect(
        decideHomeTarget(
          onboardingComplete: true,
          auth: const AppAuthState(status: AuthStatus.error),
        ),
        HomeTarget.login,
      );
    });

    test('Không hiện login khi đã xác thực', () {
      expect(
        decideHomeTarget(
          onboardingComplete: true,
          auth: const AppAuthState(status: AuthStatus.authenticated),
        ),
        HomeTarget.main,
      );
    });

    test('Mọi status chưa xác thực đều không vào được app chính', () {
      for (final status in [
        AuthStatus.initial,
        AuthStatus.unauthenticated,
        AuthStatus.loading,
        AuthStatus.error,
      ]) {
        expect(
          decideHomeTarget(
                onboardingComplete: true,
                auth: AppAuthState(status: status),
              ) !=
              HomeTarget.main,
          isTrue,
        );
      }
    });
  });
}
