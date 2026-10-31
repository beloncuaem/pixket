import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:chi_tieu/core/constants/app_colors.dart';
import 'package:chi_tieu/core/utils/icon_helper.dart';
import 'package:chi_tieu/data/repositories/supabase_storage_service.dart';
import 'package:chi_tieu/providers/auth_provider.dart';
import 'package:chi_tieu/widgets/category_icon_badge.dart';

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

  group('Storage Path Tests', () {
    test('Extracts object path from public and signed URLs', () {
      expect(
        SupabaseStorageService.storagePathFromUrl(
          'https://abc.supabase.co/storage/v1/object/public/'
          'expense-receipts/user-1/123_45.jpg',
        ),
        'user-1/123_45.jpg',
      );
      expect(
        SupabaseStorageService.storagePathFromUrl(
          'https://abc.supabase.co/storage/v1/object/sign/'
          'expense-receipts/user-1/123_45.jpg?token=xyz',
        ),
        'user-1/123_45.jpg',
      );
    });

    test('Returns null for URLs without a bucket object', () {
      expect(
        SupabaseStorageService.storagePathFromUrl(
          'https://example.com/image.jpg',
        ),
        isNull,
      );
      expect(
        SupabaseStorageService.storagePathFromUrl(
          'https://abc.supabase.co/storage/v1/object/public/expense-receipts',
        ),
        isNull,
      );
    });
  });

  group('IconHelper Tests', () {
    test('Resolves modern icon keys and legacy emojis', () {
      expect(IconHelper.availableIcons.contains('forkKnife'), isTrue);
      expect(IconHelper.availableIcons.contains('car'), isTrue);
      expect(IconHelper.availableIcons.contains('shoppingBag'), isTrue);

      final widgetFork = IconHelper.getIconWidget('forkKnife');
      expect(widgetFork, isA<Icon>());

      final widgetEmoji = IconHelper.getIconWidget('🍜');
      expect(widgetEmoji, isA<Icon>());
    });

    test('Parses hex colors safely', () {
      final color = IconHelper.parseColor('#10B981');
      expect(color.toARGB32(), const Color(0xFF10B981).toARGB32());

      final fallback = IconHelper.parseColor('invalid_color');
      expect(fallback.toARGB32(), const Color(0xFF10B981).toARGB32());
    });
  });

  group('Fintech Colors Tests', () {
    test('AppColors brand constants are defined', () {
      expect(AppColors.primary, const Color(0xFF10B981));
      expect(AppColors.backgroundDark, const Color(0xFF0B0F19));
      expect(AppColors.cardGradientDark.colors.length, 2);
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
