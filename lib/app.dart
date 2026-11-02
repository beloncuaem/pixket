import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'core/constants/app_strings.dart';
import 'providers/budget_provider.dart';
import 'providers/category_provider.dart';
import 'providers/expense_provider.dart';
import 'providers/statistics_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/app_settings_provider.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/reset_password_screen.dart';
import 'screens/main_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';

enum HomeTarget { loading, onboarding, login, resetPassword, main }

/// Routing ưu tiên: onboarding > đặt lại mật khẩu > đăng nhập > app chính.
HomeTarget decideHomeTarget({
  required bool onboardingComplete,
  required AppAuthState auth,
}) {
  if (!onboardingComplete) return HomeTarget.onboarding;
  if (auth.recoveryMode && auth.status == AuthStatus.authenticated) {
    return HomeTarget.resetPassword;
  }
  if (auth.status != AuthStatus.authenticated) return HomeTarget.login;
  return HomeTarget.main;
}

class HomeTargetLoading extends StatelessWidget {
  const HomeTargetLoading({super.key});

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}

class PixketApp extends ConsumerWidget {
  const PixketApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      home: const _AppHome(),
    );
  }
}

class _AppHome extends ConsumerWidget {
  const _AppHome();

  Future<void> _clearUserCaches() async {
    PaintingBinding.instance.imageCache
      ..clear()
      ..clearLiveImages();
    await DefaultCacheManager().emptyCache();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final authState = ref.watch(authProvider);

    ref.listen<AppAuthState>(authProvider, (previous, next) {
      final wasAuthenticated = previous?.status == AuthStatus.authenticated;
      final isAuthenticated = next.status == AuthStatus.authenticated;

      if (!wasAuthenticated && isAuthenticated) {
        ref.read(expenseProvider.notifier).refreshDashboard();
        ref.read(categoryProvider.notifier).loadCategories();
        ref
            .read(budgetProvider.notifier)
            .refreshCurrentMonthAfterExpenseChange();
      } else if (wasAuthenticated && !isAuthenticated) {
        ref.invalidate(expenseProvider);
        ref.invalidate(categoryProvider);
        ref.invalidate(budgetProvider);
        ref.invalidate(statisticsProvider);
        unawaited(_clearUserCaches());
      }
    });

    if (settings.isLoading) {
      return const HomeTargetLoading();
    }

    final target = decideHomeTarget(
      onboardingComplete: settings.onboardingComplete,
      auth: authState,
    );

    return switch (target) {
      HomeTarget.onboarding => const OnboardingScreen(),
      HomeTarget.resetPassword => const ResetPasswordScreen(),
      HomeTarget.login => const LoginScreen(),
      HomeTarget.main => const MainScreen(),
      HomeTarget.loading => const HomeTargetLoading(),
    };
  }
}
