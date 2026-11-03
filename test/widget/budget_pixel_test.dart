import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pixket/core/theme/app_theme.dart';
import 'package:pixket/data/models/budget.dart';
import 'package:pixket/data/models/category.dart';
import 'package:pixket/providers/budget_provider.dart';
import 'package:pixket/providers/category_provider.dart';
import 'package:pixket/screens/budget/budget_screen.dart';
import 'package:pixket/widgets/pixel/pixel_button.dart';
import 'package:pixket/widgets/pixel/pixel_progress.dart';
import 'package:pixket/widgets/pixel/pixel_screen_header.dart';
import 'package:pixket/widgets/pixel/pixel_segmented.dart';
import 'package:pixket/widgets/pixel/pixel_text_field.dart';

class _FakeBudgetNotifier extends StateNotifier<BudgetState>
    implements BudgetNotifier {
  _FakeBudgetNotifier(super.state);

  /// Ghi lại số tiền từng lời gọi lưu để kiểm tra mà không cần repository.
  final List<double> totalCalls = [];
  final List<Map<int, double>> categoryCalls = [];

  @override
  Future<void> loadBudgets(String month, {bool checkAlerts = false}) async {}

  @override
  Future<void> setTotalBudget({
    required String month,
    required double amount,
  }) async {
    totalCalls.add(amount);
  }

  @override
  Future<void> setCategoryBudgets({
    required String month,
    required Map<int, double> categoryBudgets,
  }) async {
    categoryCalls.add(Map<int, double>.from(categoryBudgets));
  }

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

Widget _harness(BudgetState budget, _FakeBudgetNotifier notifier) =>
    ProviderScope(
      overrides: [
        budgetProvider.overrideWith((ref) => notifier),
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

Future<_FakeBudgetNotifier> _pumpBudget(
  WidgetTester tester,
  BudgetState state,
) async {
  final notifier = _FakeBudgetNotifier(state);
  await tester.pumpWidget(_harness(state, notifier));
  await tester.pump();
  return notifier;
}

/// Cuộn tới nút rồi bấm: hàng điều chỉnh nằm dưới ô nhập nên có thể ở ngoài
/// khung nhìn mặc định 800×600 của test.
Future<void> tapAdjust(WidgetTester tester, String key) async {
  final finder = find.byKey(Key(key));
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await tester.pump();
}

Finder confirmButton(String label) => find.descendant(
  of: find.byType(Dialog),
  matching: find.widgetWithText(PixelButton, label),
);

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
    await _pumpBudget(tester, stateWith(budget: 5000000, spent: 1000000));
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
    await _pumpBudget(tester, stateWith(budget: 5000000, spent: 7000000));
    expect(find.textContaining('QUÁ NGÂN SÁCH'), findsOneWidget);
    final progress = tester.widget<PixelProgress>(find.byType(PixelProgress));
    expect(progress.value, greaterThanOrEqualTo(1));
    expect(progress.spendRamp, isTrue);
  });

  testWidgets('chưa đặt ngân sách hiện hướng dẫn đặt', (tester) async {
    await _pumpBudget(tester, stateWith(spent: 800000));
    expect(find.text('Chưa đặt ngân sách'), findsOneWidget);
    expect(find.textContaining('QUÁ NGÂN SÁCH'), findsNothing);
  });

  testWidgets('chế độ theo danh mục liệt kê từng danh mục', (tester) async {
    await _pumpBudget(
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
    await _pumpBudget(tester, stateWith(budget: 5000000, spent: 7000000));
    await tester.tap(find.byKey(const Key('totalBudgetField')));
    await tester.binding.setSurfaceSize(const Size(400, 260));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('cộng/trừ áp số tiền điều chỉnh lên hạn mức đã lưu', (
    tester,
  ) async {
    final notifier = await _pumpBudget(
      tester,
      stateWith(budget: 5000000, spent: 1000000),
    );
    final adjust = find.byKey(const Key('totalAdjust'));
    await tester.ensureVisible(adjust);
    await tester.pump();

    await tester.enterText(adjust, '500000');
    await tapAdjust(tester, 'totalAdjust-add');
    expect(notifier.totalCalls, [5500000]);
    // Ô điều chỉnh trống lại để một lần bấm nữa không âm thầm cộng tiếp.
    expect(tester.widget<PixelTextField>(adjust).controller!.text, isEmpty);

    await tester.enterText(adjust, '500000');
    await tapAdjust(tester, 'totalAdjust-subtract');
    expect(notifier.totalCalls, [5500000, 4500000]);
  });

  testWidgets('trừ quá tay chỉ về 0 chứ không âm', (tester) async {
    final notifier = await _pumpBudget(tester, stateWith(budget: 300000));
    final adjust = find.byKey(const Key('totalAdjust'));
    await tester.ensureVisible(adjust);
    await tester.pump();
    await tester.enterText(adjust, '900000');
    await tapAdjust(tester, 'totalAdjust-subtract');
    expect(notifier.totalCalls, [0]);
  });

  testWidgets('ô điều chỉnh trống thì không ghi và được nhắc', (tester) async {
    final notifier = await _pumpBudget(tester, stateWith(budget: 5000000));
    await tapAdjust(tester, 'totalAdjust-add');
    expect(notifier.totalCalls, isEmpty);
    expect(find.text('Nhập số tiền cần điều chỉnh trước.'), findsOneWidget);
  });

  testWidgets('xóa ngân sách tổng hỏi lại rồi mới ghi 0', (tester) async {
    final notifier = await _pumpBudget(tester, stateWith(budget: 5000000));
    await tapAdjust(tester, 'totalAdjust-delete');
    expect(find.text('Xóa ngân sách tổng?'), findsOneWidget);
    expect(notifier.totalCalls, isEmpty);

    await tester.tap(confirmButton('XÓA'));
    await tester.pump();
    expect(notifier.totalCalls, [0]);
  });

  testWidgets('bấm Hủy ở hộp thoại xóa thì giữ nguyên ngân sách', (
    tester,
  ) async {
    final notifier = await _pumpBudget(tester, stateWith(budget: 5000000));
    await tapAdjust(tester, 'totalAdjust-delete');
    await tester.tap(confirmButton('Hủy'));
    await tester.pump();
    expect(notifier.totalCalls, isEmpty);
    expect(find.text('Xóa ngân sách tổng?'), findsNothing);
  });

  testWidgets('cộng theo danh mục chỉ đổi hạn mức của danh mục đó', (
    tester,
  ) async {
    final notifier = await _pumpBudget(
      tester,
      stateWith(budget: 5000000, categoryBudgets: const {1: 800000}),
    );
    await tester.tap(find.text('THEO DANH MỤC'));
    await tester.pump();

    final adjust = find.byKey(const Key('categoryAdjust-1'));
    await tester.ensureVisible(adjust);
    await tester.pump();
    await tester.enterText(adjust, '200000');
    await tapAdjust(tester, 'categoryAdjust-1-add');
    expect(notifier.categoryCalls, [
      {1: 1000000},
    ]);
  });

  testWidgets('xóa hạn mức một danh mục sau khi hỏi lại', (tester) async {
    final notifier = await _pumpBudget(
      tester,
      stateWith(budget: 5000000, categoryBudgets: const {1: 800000}),
    );
    await tester.tap(find.text('THEO DANH MỤC'));
    await tester.pump();
    await tapAdjust(tester, 'categoryAdjust-1-delete');
    expect(find.textContaining('Xóa ngân sách "Ăn uống"?'), findsOneWidget);

    await tester.tap(confirmButton('XÓA'));
    await tester.pump();
    expect(notifier.categoryCalls.single, isEmpty);
  });
}
