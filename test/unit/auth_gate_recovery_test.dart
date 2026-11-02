import 'package:flutter_test/flutter_test.dart';
import 'package:pixket/app.dart';
import 'package:pixket/providers/auth_provider.dart';

void main() {
  test('onboarding wins over everything else', () {
    expect(
      decideHomeTarget(
        onboardingComplete: false,
        auth: const AppAuthState(status: AuthStatus.authenticated),
      ),
      HomeTarget.onboarding,
    );
  });

  test('recovery mode wins over the normal authenticated route', () {
    expect(
      decideHomeTarget(
        onboardingComplete: true,
        auth: const AppAuthState(
          status: AuthStatus.authenticated,
          recoveryMode: true,
        ),
      ),
      HomeTarget.resetPassword,
    );
  });

  test('authenticated without recovery goes to main', () {
    expect(
      decideHomeTarget(
        onboardingComplete: true,
        auth: const AppAuthState(status: AuthStatus.authenticated),
      ),
      HomeTarget.main,
    );
  });

  test('every non-authenticated status shows login', () {
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
        ),
        HomeTarget.login,
      );
    }
  });
}
