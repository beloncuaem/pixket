import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pixket/providers/auth_provider.dart';
import 'package:pixket/providers/budget_provider.dart';
import 'package:pixket/providers/category_provider.dart';
import 'package:pixket/providers/expense_provider.dart';
import 'package:pixket/providers/priority_provider.dart';
import 'package:pixket/providers/statistics_provider.dart';
import 'package:pixket/providers/theme_provider.dart';

// Mọi notifier thật đều chạm sqflite/Supabase ngay trong constructor, nên test
// nào dựng MainScreen phải override đủ 7 provider dưới. Khuôn `implements X` +
// `noSuchMethod` lấy từ test/widget/trash_settings_pixel_test.dart.

class FakeAuthNotifier extends StateNotifier<AppAuthState>
    implements AuthNotifier {
  FakeAuthNotifier()
    : super(const AppAuthState(status: AuthStatus.authenticated));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeThemeNotifier extends StateNotifier<ThemeMode>
    implements ThemeNotifier {
  FakeThemeNotifier() : super(ThemeMode.dark);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeExpenseNotifier extends StateNotifier<ExpenseState>
    implements ExpenseNotifier {
  FakeExpenseNotifier() : super(const ExpenseState());

  @override
  Future<void> refreshDashboard() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeCategoryNotifier extends StateNotifier<CategoryState>
    implements CategoryNotifier {
  FakeCategoryNotifier() : super(const CategoryState());

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakePriorityNotifier extends StateNotifier<PriorityState>
    implements PriorityNotifier {
  FakePriorityNotifier() : super(const PriorityState());

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeBudgetNotifier extends StateNotifier<BudgetState>
    implements BudgetNotifier {
  FakeBudgetNotifier() : super(const BudgetState(month: '2026-11'));

  @override
  Future<void> loadBudgets(String month, {bool checkAlerts = false}) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeStatisticsNotifier extends StateNotifier<StatisticsState>
    implements StatisticsNotifier {
  FakeStatisticsNotifier() : super(StatisticsState());

  @override
  Future<void> loadStatistics(DateTime from, DateTime to) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Override đủ cho test nào dựng MainScreen hoặc một trong 4 section.
List<Override> mainScreenOverrides() => [
  authProvider.overrideWith((ref) => FakeAuthNotifier()),
  themeProvider.overrideWith((ref) => FakeThemeNotifier()),
  expenseProvider.overrideWith((ref) => FakeExpenseNotifier()),
  categoryProvider.overrideWith((ref) => FakeCategoryNotifier()),
  priorityProvider.overrideWith((ref) => FakePriorityNotifier()),
  budgetProvider.overrideWith((ref) => FakeBudgetNotifier()),
  statisticsProvider.overrideWith((ref) => FakeStatisticsNotifier()),
];
