import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chi_tieu/core/theme/app_theme.dart';
import 'package:chi_tieu/data/models/budget.dart';
import 'package:chi_tieu/data/models/category.dart';
import 'package:chi_tieu/data/models/expense.dart';
import 'package:chi_tieu/data/models/priority_level.dart';
import 'package:chi_tieu/providers/auth_provider.dart';
import 'package:chi_tieu/providers/budget_provider.dart';
import 'package:chi_tieu/providers/category_provider.dart';
import 'package:chi_tieu/providers/expense_provider.dart';
import 'package:chi_tieu/providers/priority_provider.dart';
import 'package:chi_tieu/screens/home/budget_progress_card.dart';
import 'package:chi_tieu/screens/home/dashboard_summary.dart';
import 'package:chi_tieu/screens/home/home_screen.dart';
import 'package:chi_tieu/widgets/pixel/pixel_expense_tile.dart';
import 'package:chi_tieu/widgets/pixel/pixel_progress.dart';

class _FakeExpenseNotifier extends StateNotifier<ExpenseState>
    implements ExpenseNotifier {
  _FakeExpenseNotifier(this._initial) : super(_initial);
  final ExpenseState _initial;
  @override
  dynamic noSuchMethod(Invocation invocation) => _initial;
}

class _FakeCategoryNotifier extends StateNotifier<CategoryState>
    implements CategoryNotifier {
  _FakeCategoryNotifier(super.state);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakePriorityNotifier extends StateNotifier<PriorityState>
    implements PriorityNotifier {
  _FakePriorityNotifier(super.state);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeBudgetNotifier extends StateNotifier<BudgetState>
    implements BudgetNotifier {
  _FakeBudgetNotifier(super.state);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAuthNotifier extends StateNotifier<AppAuthState>
    implements AuthNotifier {
  _FakeAuthNotifier(super.state);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

ExpenseState expenseState(List<Expense> items, {bool loading = false}) =>
    ExpenseState(
      expenses: items,
      todayTotal: 50000,
      weekTotal: 200000,
      monthTotal: 1200000,
      isLoading: loading,
    );

Expense makeExpense({int id = 1, String caption = 'Cà phê'}) => Expense(
  id: id,
  caption: caption,
  amount: 45000,
  categoryId: 10,
  priority: 0,
  createdAt: DateTime.now(),
);

final _categories = [Category(id: 10, name: 'Ăn uống', icon: 'forkKnife')];
const _priorities = [
  PriorityLevel(id: 0, name: 'Cần thiết', colorValue: 0xFF7BD8A8, sortOrder: 0),
];

Widget harness(
  Widget child, {
  ExpenseState? expenses,
  List<Category>? categories,
  List<PriorityLevel>? priorities,
  BudgetState? budget,
}) {
  return ProviderScope(
    overrides: [
      expenseProvider.overrideWith(
        (ref) => _FakeExpenseNotifier(expenses ?? expenseState(const [])),
      ),
      categoryProvider.overrideWith(
        (ref) => _FakeCategoryNotifier(
          CategoryState(categories: categories ?? const []),
        ),
      ),
      priorityProvider.overrideWith(
        (ref) => _FakePriorityNotifier(
          PriorityState(levels: priorities ?? const []),
        ),
      ),
      budgetProvider.overrideWith(
        (ref) => _FakeBudgetNotifier(budget ?? BudgetState(month: '11/2026')),
      ),
      authProvider.overrideWith(
        (ref) => _FakeAuthNotifier(const AppAuthState()),
      ),
    ],
    child: MaterialApp(theme: AppTheme.light, home: child),
  );
}

void main() {
  testWidgets('DashboardSummary hiện hero và 3 stat tile rút gọn', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(
        const DashboardSummary(
          month: 1200000,
          today: 50000,
          week: 200000,
          expenseCount: 12,
        ),
      ),
    );
    expect(find.text('CHI THÁNG NÀY'), findsOneWidget);
    expect(find.textContaining('1.200.000'), findsOneWidget);
    expect(find.text('HÔM NAY'), findsOneWidget);
    expect(find.text('TUẦN NÀY'), findsOneWidget);
    expect(find.text('SỐ KHOẢN'), findsOneWidget);
    expect(find.text('50 K'), findsOneWidget);
    expect(find.text('200 K'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
  });

  testWidgets('BudgetProgressCard hiện QUÁ NGÂN SÁCH khi vượt', (tester) async {
    await tester.pumpWidget(
      harness(
        const BudgetProgressCard(spent: 7000000, budget: 5000000, onTap: null),
      ),
    );
    expect(find.textContaining('QUÁ NGÂN SÁCH'), findsOneWidget);
    expect(find.textContaining('2.000.000'), findsOneWidget);
    final progress = tester.widget<PixelProgress>(find.byType(PixelProgress));
    expect(progress.value, greaterThanOrEqualTo(1));
  });

  testWidgets('BudgetProgressCard trong hạn hiện Còn lại', (tester) async {
    await tester.pumpWidget(
      harness(
        const BudgetProgressCard(spent: 1000000, budget: 5000000, onTap: null),
      ),
    );
    expect(find.textContaining('Còn lại'), findsOneWidget);
    expect(find.textContaining('4.000.000'), findsOneWidget);
  });

  testWidgets('BudgetProgressCard chưa đặt hiện hướng dẫn đặt', (tester) async {
    await tester.pumpWidget(
      harness(const BudgetProgressCard(spent: 1000000, budget: 0, onTap: null)),
    );
    expect(find.text('Chưa đặt ngân sách'), findsOneWidget);
    expect(find.byType(PixelProgress), findsNothing);
  });

  testWidgets('HomeScreen rỗng hiện PixelEmptyState', (tester) async {
    await tester.pumpWidget(
      harness(const HomeScreen(), expenses: const ExpenseState(expenses: [])),
    );
    await tester.pumpAndSettle();
    expect(find.text('CHƯA CÓ KHOẢN CHI NÀO'), findsOneWidget);
    expect(find.text('Mở camera và chụp khoản chi đầu tiên.'), findsOneWidget);
  });

  testWidgets('HomeScreen render PixelExpenseTile theo danh mục', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(
        const HomeScreen(),
        expenses: expenseState([makeExpense(caption: 'Đồ ăn trưa')]),
        categories: _categories,
        priorities: _priorities,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(PixelExpenseTile), findsOneWidget);
    expect(find.text('Ăn uống'), findsOneWidget);
    expect(find.text('Đồ ăn trưa'), findsOneWidget);
  });

  testWidgets('HomeScreen loading hiện PixelLoading, không spinner tròn', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(
        const HomeScreen(),
        expenses: expenseState(const [], loading: true),
      ),
    );
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Đang tải…'), findsOneWidget);
  });

  testWidgets('HomeScreen 1.3x text scale không overflow', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          expenseProvider.overrideWith(
            (ref) => _FakeExpenseNotifier(
              expenseState([makeExpense(id: 1), makeExpense(id: 2)]),
            ),
          ),
          categoryProvider.overrideWith(
            (ref) =>
                _FakeCategoryNotifier(CategoryState(categories: _categories)),
          ),
          priorityProvider.overrideWith(
            (ref) =>
                _FakePriorityNotifier(const PriorityState(levels: _priorities)),
          ),
          budgetProvider.overrideWith(
            (ref) => _FakeBudgetNotifier(
              BudgetState(
                month: '11/2026',
                totalSpent: 900000,
                totalBudget: Budget(month: '11/2026', amount: 1000000),
              ),
            ),
          ),
          authProvider.overrideWith(
            (ref) => _FakeAuthNotifier(const AppAuthState()),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(1.3)),
              child: const HomeScreen(),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
