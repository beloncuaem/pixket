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
import 'screens/main_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';

bool shouldShowLoginScreen({required AuthStatus status}) {
  return status != AuthStatus.authenticated;
}

class ChiTieuApp extends ConsumerWidget {
  const ChiTieuApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!settings.onboardingComplete) {
      return const OnboardingScreen();
    }

    if (shouldShowLoginScreen(status: authState.status)) {
      return const LoginScreen();
    }

    return const MainScreen();
  }
}
