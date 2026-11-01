import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chi_tieu/core/theme/app_theme.dart';
import 'package:chi_tieu/data/models/budget.dart';
import 'package:chi_tieu/data/models/category.dart';
import 'package:chi_tieu/providers/budget_provider.dart';
import 'package:chi_tieu/providers/category_provider.dart';
import 'package:chi_tieu/screens/budget/budget_screen.dart';
import 'package:chi_tieu/widgets/pixel/pixel_progress.dart';
import 'package:chi_tieu/widgets/pixel/pixel_screen_header.dart';
import 'package:chi_tieu/widgets/pixel/pixel_segmented.dart';
import 'package:chi_tieu/widgets/pixel/pixel_text_field.dart';

class _FakeBudgetNotifier extends StateNotifier<BudgetState>
    implements BudgetNotifier {
  _FakeBudgetNotifier(super.state);

  @override
  Future<void> loadBudgets(String month, {bool checkAlerts = false}) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeCategoryNotifier extends StateNotifier<CategoryState>
    implements CategoryNotifier {
  _FakeCategoryNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

BudgetState stateWith({
  double budget = 0,
  double spent = 0,
  Map<int, double> categoryBudgets = const {},
}) => BudgetState(
  month: '2026-11',
  totalBudget: budget > 0
      ? Budget(id: 1, amount: budget, month: '2026-11')
      : null,
  totalSpent: spent,
  categoryBudgets: categoryBudgets,
);

Widget harness(BudgetState budget) => ProviderScope(
  overrides: [
    budgetProvider.overrideWith((ref) => _FakeBudgetNotifier(budget)),
    categoryProvider.overrideWith(
      (ref) => _FakeCategoryNotifier(
        CategoryState(
          categories: [Category(id: 1, name: 'Ăn uống', icon: 'forkKnife')],
        ),
      ),
    ),
  ],
  child: MaterialApp(
    theme: AppTheme.light,
    home: BudgetScreen(onMenuTap: () {}),
  ),
);

Future<void> pumpBudget(WidgetTester tester, BudgetState state) async {
  await tester.pumpWidget(harness(state));
  await tester.pump();
}

void main() {
  test('budgetTotals an toàn khi chưa đặt ngân sách', () {
    expect(budgetTotals(stateWith()).budget, 0);
    expect(budgetTotals(stateWith()).spent, 0);
    final t = budgetTotals(stateWith(budget: 5, spent: 7));
    expect(t.budget, 5);
    expect(t.spent, 7);
  });

  testWidgets('màn ngân sách dùng pixel và có ô nhập với formatter', (
    tester,
  ) async {
    await pumpBudget(tester, stateWith(budget: 5000000, spent: 1000000));
    expect(find.byType(PixelScreenHeader), findsOneWidget);
    expect(find.byType(PixelSegmented<BudgetMode>), findsOneWidget);
    expect(find.byType(PixelTextField), findsWidgets);
    expect(find.text('NGÂN SÁCH TỔNG'), findsOneWidget);
    // PixelTextField bọc TextFormField nên không đếm TextField; kiểm chứng bằng
    // các widget Material cũ đã biến mất.
    expect(find.byType(SegmentedButton<bool>), findsNothing);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(find.byType(ElevatedButton), findsNothing);
    final field = tester.widget<PixelTextField>(
      find.byKey(const Key('totalBudgetField')),
    );
    expect(field.inputFormatters, isNotNull);
    expect(field.controller?.text, '5.000.000');
  });

  testWidgets('vượt ngân sách hiện QUÁ NGÂN SÁCH bằng chữ', (tester) async {
    await pumpBudget(tester, stateWith(budget: 5000000, spent: 7000000));
    expect(find.textContaining('QUÁ NGÂN SÁCH'), findsOneWidget);
    final progress = tester.widget<PixelProgress>(find.byType(PixelProgress));
    expect(progress.value, greaterThanOrEqualTo(1));
    expect(progress.fillColor, isNotNull);
  });

  testWidgets('chưa đặt ngân sách hiện hướng dẫn đặt', (tester) async {
    await pumpBudget(tester, stateWith(spent: 800000));
    expect(find.text('Chưa đặt ngân sách'), findsOneWidget);
    expect(find.textContaining('QUÁ NGÂN SÁCH'), findsNothing);
  });

  testWidgets('chế độ theo danh mục liệt kê từng danh mục', (tester) async {
    await pumpBudget(
      tester,
      stateWith(categoryBudgets: const {1: 800000}, spent: 200000),
    );
    await tester.tap(find.text('THEO DANH MỤC'));
    await tester.pump();
    expect(find.text('Ăn uống'), findsOneWidget);
    expect(find.byKey(const Key('categoryBudget-1')), findsOneWidget);
    expect(
      tester
          .widget<PixelTextField>(find.byKey(const Key('categoryBudget-1')))
          .controller!
          .text,
      '800.000',
    );
  });

  testWidgets('màn ngắn vẫn cuộn được, không overflow', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 740));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpBudget(tester, stateWith(budget: 5000000, spent: 7000000));
    await tester.tap(find.byKey(const Key('totalBudgetField')));
    await tester.binding.setSurfaceSize(const Size(400, 260));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
