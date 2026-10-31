import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:chi_tieu/core/constants/app_colors.dart';
import 'package:chi_tieu/core/utils/icon_helper.dart';
import 'package:chi_tieu/providers/auth_provider.dart';
import 'package:chi_tieu/widgets/category_icon_badge.dart';
import 'package:chi_tieu/widgets/pixel/app_icon.dart';

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

  group('Legacy Colors', () {
    test('AppColors trỏ tới hex pixel', () {
      expect(AppColors.primary, const Color(0xFF2F9E6E));
      expect(AppColors.backgroundDark, const Color(0xFF1A130D));
      expect(AppColors.cardGradientDark.colors.length, 2);
      expect(
        AppColors.cardGradientDark.colors.first,
        const Color(0xFF241A12),
      );
    });
  });

  group('CategoryIconBadge Widget Tests', () {
    testWidgets('Renders CategoryIconBadge without throwing', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: CategoryIconBadge(iconKey: 'forkKnife')),
        ),
      );

      expect(find.byType(CategoryIconBadge), findsOneWidget);
    });
  });
}
