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
import 'package:pixket/data/repositories/priority_repository.dart';
import 'package:pixket/data/repositories/priority_row_reader.dart';

/// Reader giả chạy theo kịch bản: lần gọi thứ n dùng bước thứ n, hết kịch bản
/// thì lặp lại bước cuối.
class _ScriptedReader implements PriorityRowReader {
  _ScriptedReader(this._script);

  final List<Future<List<Map<String, dynamic>>> Function()> _script;
  int calls = 0;

  @override
  Future<List<Map<String, dynamic>>> readAll() {
    final step = _script[calls.clamp(0, _script.length - 1)];
    calls++;
    return step();
  }
}

Future<List<Map<String, dynamic>>> _readFails() async =>
    throw StateError('Chưa kết nối được Supabase. Vui lòng kiểm tra mạng.');

Future<List<Map<String, dynamic>>> _readSeed() async => _seededRows;

/// Đúng 4 dòng mà section 5.1 của supabase_setup.sql seed.
const List<Map<String, dynamic>> _seededRows = [
  {
    'id': 1,
    'level_key': 0,
    'name': 'Thiết yếu',
    'color_value': 4282622023,
    'sort_order': 0,
  },
  {
    'id': 2,
    'level_key': 1,
    'name': 'Rất cần',
    'color_value': 4280191205,
    'sort_order': 1,
  },
  {
    'id': 3,
    'level_key': 2,
    'name': 'Cần vừa',
    'color_value': 4294675456,
    'sort_order': 2,
  },
  {
    'id': 4,
    'level_key': 3,
    'name': 'Chưa cần',
    'color_value': 4293212469,
    'sort_order': 3,
  },
];

PriorityNotifier _notifierWith(PriorityRowReader reader) =>
    PriorityNotifier(repository: PriorityRepository(reader: reader));

/// Constructor của PriorityNotifier gọi loadLevels() mà không await, nên test
/// phải nhường event loop cho lần đọc đó xong trước khi assert state.
Future<void> _settleFirstLoad() => pumpEventQueue();

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

  group('PriorityNotifier.loadLevels', () {
    test('lần đọc đầu ném lỗi: state rỗng, không ném ra ngoài', () async {
      final notifier = _notifierWith(_ScriptedReader([_readFails]));
      await _settleFirstLoad();

      await expectLater(notifier.loadLevels(), completes);

      expect(notifier.state.levels, isEmpty);
      expect(notifier.state.isLoading, isFalse);
    });

    test('đọc lại sau lần đầu thất bại thì có dữ liệu', () async {
      final notifier = _notifierWith(_ScriptedReader([_readFails, _readSeed]));
      await _settleFirstLoad();

      expect(notifier.state.levels, isEmpty, reason: 'lần đọc đầu thất bại');

      await notifier.loadLevels();

      expect(notifier.state.levels.map((level) => level.id), [0, 1, 2, 3]);
      expect(notifier.state.isLoading, isFalse);
    });

    test('reader ném lỗi vẫn giữ dữ liệu đã load được trước đó', () async {
      final notifier = _notifierWith(_ScriptedReader([_readSeed, _readFails]));
      await _settleFirstLoad();
      expect(notifier.state.levels, hasLength(4));

      await notifier.loadLevels();

      expect(notifier.state.levels, hasLength(4));
      expect(notifier.state.isLoading, isFalse);
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
