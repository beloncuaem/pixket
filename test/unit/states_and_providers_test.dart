import 'package:flutter_test/flutter_test.dart';
import 'package:pixket/providers/budget_provider.dart';
import 'package:pixket/providers/statistics_provider.dart';
import 'package:pixket/providers/expense_provider.dart';
import 'package:pixket/providers/category_provider.dart';
import 'package:pixket/providers/priority_provider.dart';
import 'package:pixket/providers/app_settings_provider.dart';
import 'package:pixket/data/models/budget.dart';
import 'package:pixket/data/models/category.dart';
import 'package:pixket/data/models/expense.dart';
import 'package:pixket/data/models/priority_level.dart';

void main() {
  group('BudgetState Logic Tests', () {
    test('Calculates totalBudgetAmount and unallocatedAmount correctly', () {
      final state = BudgetState(
        month: '2026-10',
        totalBudget: Budget(month: '2026-10', amount: 5000000),
        totalSpent: 2000000,
        allocatedAmount: 1500000,
        budgetUsagePercent: 0.4,
      );

      expect(state.totalBudgetAmount, 5000000);
      expect(state.unallocatedAmount, 3500000);
      expect(state.isOverBudget, false);
      expect(state.budgetUsagePercent, 0.4);
      expect(state.totalSpent, 2000000);
      expect(state.allocatedAmount, 1500000);
    });

    test('Over-budget state and unallocatedAmount clamped when negative', () {
      final state = BudgetState(
        month: '2026-10',
        totalBudget: Budget(month: '2026-10', amount: 3000000),
        totalSpent: 4000000,
        allocatedAmount: 3500000,
        budgetUsagePercent: 1.33,
        isOverBudget: true,
      );

      expect(state.totalBudgetAmount, 3000000);
      expect(state.unallocatedAmount, 0.0);
      expect(state.isOverBudget, true);
      expect(state.budgetUsagePercent, 1.33);
      expect(state.totalSpent, 4000000);
    });

    test('BudgetValidationException message is preserved', () {
      const ex = BudgetValidationException('Vượt hạn mức cho phép');
      expect(ex.message, 'Vượt hạn mức cho phép');
      expect(ex.toString(), contains('Vượt hạn mức cho phép'));
    });

    test('BudgetState copyWith allows clearing totalBudget', () {
      final state = BudgetState(
        month: '2026-10',
        totalBudget: Budget(month: '2026-10', amount: 5000000),
      );

      final cleared = state.copyWith(clearTotalBudget: true);
      expect(cleared.totalBudget, isNull);
    });
  });

  group('StatisticsState Logic Tests', () {
    test('Calculates spending metrics and aliases', () {
      final state = StatisticsState(
        totalAmount: 1200000,
        categoryTotals: {1: 500000, 2: 700000},
        priorityTotals: {0: 800000, 1: 400000},
        dailyTotals: {'2026-10-14': 1200000},
        insights: ['Tổng chi tiêu: 1.200.000 đ'],
      );

      expect(state.totalSpending, 1200000);
      expect(state.spendingByCategory[1], 500000);
      expect(state.spendingByPriority[0], 800000);
      expect(state.dailyTotals['2026-10-14'], 1200000);
      expect(state.insights.length, 1);
    });

    test('StatisticsState copyWith works properly', () {
      final state = StatisticsState(totalAmount: 500000);
      final updated = state.copyWith(totalAmount: 900000, isLoading: true);

      expect(updated.totalAmount, 900000);
      expect(updated.isLoading, true);
    });
  });

  group('ExpenseState Logic Tests', () {
    test('ExpenseState holds dashboard totals and list', () {
      final expense = Expense(
        id: 1,
        caption: 'Ăn trưa',
        amount: 40000,
        categoryId: 1,
        priority: 0,
        createdAt: DateTime.now(),
      );

      final state = ExpenseState(
        expenses: [expense],
        todayTotal: 40000,
        weekTotal: 250000,
        monthTotal: 1200000,
      );

      expect(state.expenses.length, 1);
      expect(state.todayTotal, 40000);
      expect(state.weekTotal, 250000);
      expect(state.monthTotal, 1200000);
    });

    test('ExpenseState copyWith clearError', () {
      const state = ExpenseState(errorMessage: 'Lỗi tải');
      final cleared = state.copyWith(clearError: true);
      expect(cleared.errorMessage, isNull);
    });
  });

  group('CategoryState Logic Tests', () {
    test('CategoryState updates categories and error correctly', () {
      final cat = Category(id: 1, name: 'Ăn uống', icon: '🍜', isDefault: true);
      const state = CategoryState(isLoading: true);
      final updated = state.copyWith(categories: [cat], isLoading: false);

      expect(updated.categories.length, 1);
      expect(updated.isLoading, false);
      expect(updated.categories.first.name, 'Ăn uống');
    });
  });

  group('PriorityState Logic Tests', () {
    test('PriorityState manages priority levels list', () {
      const level = PriorityLevel(
        id: 0,
        name: 'Thiết yếu',
        colorValue: 0xFF43A047,
        sortOrder: 0,
      );

      const state = PriorityState(isLoading: true);
      final updated = state.copyWith(levels: [level], isLoading: false);

      expect(updated.levels.length, 1);
      expect(updated.levels.first.name, 'Thiết yếu');
      expect(updated.isLoading, false);
    });
  });

  group('AppSettingsState Logic Tests', () {
    test('AppSettingsState tracks onboarding status', () {
      const state = AppSettingsState(
        isLoading: true,
        onboardingComplete: false,
      );
      final updated = state.copyWith(
        isLoading: false,
        onboardingComplete: true,
      );

      expect(updated.isLoading, false);
      expect(updated.onboardingComplete, true);
    });
  });
}
