import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:pixket/core/utils/icon_helper.dart';
import 'package:pixket/providers/auth_provider.dart';
import 'package:pixket/widgets/pixel/app_icon.dart';

void main() {
  group('Auth State Tests', () {
    test('AppAuthState default initialization', () {
      const state = AppAuthState();
      expect(state.status, AuthStatus.initial);
      expect(state.user, isNull);
      expect(state.errorMessage, isNull);
      expect(state.isConfigured, isFalse);
    });

    test('AppAuthState copyWith updates fields properly', () {
      const state = AppAuthState();
      final updated = state.copyWith(
        status: AuthStatus.authenticated,
        errorMessage: 'Test error',
        isConfigured: true,
      );

      expect(updated.status, AuthStatus.authenticated);
      expect(updated.errorMessage, 'Test error');
      expect(updated.isConfigured, isTrue);
    });

    test('AppAuthState defaults recoveryMode to false', () {
      const state = AppAuthState();
      expect(state.recoveryMode, isFalse);
    });

    test('copyWith turns recoveryMode on and off again', () {
      const state = AppAuthState();
      final recovering = state.copyWith(
        status: AuthStatus.authenticated,
        recoveryMode: true,
      );
      expect(recovering.recoveryMode, isTrue);

      final done = recovering.copyWith(recoveryMode: false);
      expect(done.recoveryMode, isFalse);
      expect(done.status, AuthStatus.authenticated);
    });

    test('copyWith clearUser removes the previous user', () {
      final user = sb.User(
        id: 'user-1',
        appMetadata: const {},
        userMetadata: const {},
        aud: 'authenticated',
        createdAt: '2026-01-01T00:00:00Z',
      );
      final authenticated = AppAuthState(
        status: AuthStatus.authenticated,
        user: user,
      );

      final signedOut = authenticated.copyWith(
        status: AuthStatus.unauthenticated,
        clearUser: true,
      );

      expect(signedOut.user, isNull);
      expect(signedOut.status, AuthStatus.unauthenticated);
    });
  });

  group('IconHelper Tests', () {
    test('Resolves modern icon keys and legacy emojis', () {
      expect(IconHelper.availableIcons.contains('forkKnife'), isTrue);
      expect(IconHelper.availableIcons.contains('car'), isTrue);
      expect(IconHelper.availableIcons.contains('shoppingBag'), isTrue);

      final widgetFork = IconHelper.getIconWidget('forkKnife');
      expect(widgetFork, isA<AppIcon>());

      final widgetEmoji = IconHelper.getIconWidget('🍜');
      expect(widgetEmoji, isA<AppIcon>());

      final widgetUnknown = IconHelper.getIconWidget('chưa_biết');
      expect(widgetUnknown, isA<AppIcon>());
    });

    test('Parses hex colors safely', () {
      final color = IconHelper.parseColor('#10B981');
      expect(color.toARGB32(), const Color(0xFF10B981).toARGB32());

      final fallback = IconHelper.parseColor('invalid_color');
      expect(fallback.toARGB32(), const Color(0xFF10B981).toARGB32());
    });
  });
}
