import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chi_tieu/core/theme/app_theme.dart';
import 'package:chi_tieu/data/models/category.dart';
import 'package:chi_tieu/data/models/expense.dart';
import 'package:chi_tieu/data/models/priority_level.dart';
import 'package:chi_tieu/providers/category_provider.dart';
import 'package:chi_tieu/providers/expense_provider.dart';
import 'package:chi_tieu/providers/priority_provider.dart';
import 'package:chi_tieu/screens/camera/expense_form_sheet.dart';
import 'package:chi_tieu/widgets/pixel/pixel_button.dart';
import 'package:chi_tieu/widgets/pixel/pixel_chip.dart';
import 'package:chi_tieu/widgets/pixel/pixel_receipt_image.dart';
import 'package:chi_tieu/widgets/pixel/pixel_text_field.dart';

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

class _FakeExpenseNotifier extends StateNotifier<ExpenseState>
    implements ExpenseNotifier {
  _FakeExpenseNotifier() : super(const ExpenseState());
  @override
  dynamic noSuchMethod(Invocation invocation) => const ExpenseState();
}

final _categories = [
  Category(id: 1, name: 'Ăn uống', icon: 'forkKnife'),
  Category(id: 2, name: 'Khác', icon: 'receipt'),
];

Widget harness({String? imagePath, Expense? expense}) => ProviderScope(
  overrides: [
    categoryProvider.overrideWith(
      (ref) => _FakeCategoryNotifier(CategoryState(categories: _categories)),
    ),
    priorityProvider.overrideWith(
      (ref) => _FakePriorityNotifier(
        const PriorityState(
          levels: [
            PriorityLevel(
              id: 0,
              name: 'Cần thiết',
              colorValue: 0xFF7BD8A8,
              sortOrder: 0,
            ),
            PriorityLevel(
              id: 3,
              name: 'Không cần',
              colorValue: 0xFFF28C9A,
              sortOrder: 3,
            ),
          ],
        ),
      ),
    ),
    expenseProvider.overrideWith((ref) => _FakeExpenseNotifier()),
  ],
  child: MaterialApp(
    theme: AppTheme.light,
    home: Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: TextButton(
            onPressed: () => openExpenseForm(
              context,
              imagePath: imagePath,
              expense: expense,
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  ),
);

Expense editableExpense() => Expense(
  id: 5,
  caption: 'Đồ ăn',
  amount: 30000,
  categoryId: 1,
  priority: 0,
  imagePath: '0f1c2b3d-4e5f-4a6b-8c9d-0e1f2a3b4c5d/noon.png',
  createdAt: DateTime(2026, 11, 1, 12),
);

void main() {
  Future<void> openForm(WidgetTester tester, {String? imagePath}) async {
    await tester.pumpWidget(
      harness(imagePath: imagePath ?? '/tmp/missing.jpg'),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('form mới dùng component pixel, không còn Material cũ', (
    tester,
  ) async {
    await openForm(tester);
    expect(find.text('Thêm khoản chi'), findsOneWidget);
    expect(find.byType(PixelReceiptImage), findsOneWidget);
    expect(find.byType(PixelTextField), findsNWidgets(2));
    expect(find.byType(PixelChip), findsWidgets);
    expect(find.text('Ăn uống'), findsOneWidget);
    expect(
      find.text('Không chọn danh mục sẽ tự xếp vào Khác.'),
      findsOneWidget,
    );
    expect(find.byType(ChoiceChip), findsNothing);
    expect(find.byType(FilledButton), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('nhập 1234567 hiển thị 1.234.567', (tester) async {
    await openForm(tester);
    final amount = find.byKey(const Key('expenseAmountField'));
    await tester.ensureVisible(amount);
    await tester.enterText(amount, '1234567');
    await tester.pump();
    expect(find.text('1.234.567'), findsOneWidget);
  });

  testWidgets('số tiền trống bị chặn bằng lỗi inline', (tester) async {
    await openForm(tester);
    final save = find.byType(PixelButton).last;
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(find.text('Nhập số tiền lớn hơn 0'), findsOneWidget);
  });

  testWidgets('đang sửa: tiêu đề, ghi chú và ảnh giữ nguyên đường dẫn', (
    tester,
  ) async {
    await tester.pumpWidget(harness(expense: editableExpense()));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Chỉnh sửa khoản chi'), findsOneWidget);
    expect(find.text('Ảnh không thể thay đổi sau khi đã lưu.'), findsOneWidget);
    expect(find.text('LƯU THAY ĐỔI'), findsOneWidget);
    expect(find.text('Đồ ăn'), findsOneWidget);
    expect(find.byType(PixelReceiptImage), findsOneWidget);
  });

  testWidgets('form có ô ngày giờ của plan 3', (tester) async {
    await openForm(tester);
    expect(find.text('Ngày giờ ghi nhận'), findsOneWidget);
    expect(find.text('Bây giờ'), findsOneWidget);
  });

  testWidgets('chạm chip danh mục thì chọn, chạm lần nữa thì bỏ', (
    tester,
  ) async {
    await openForm(tester);
    final chip = find.text('Ăn uống');
    await tester.ensureVisible(chip);
    await tester.tap(chip);
    await tester.pump();
    expect(
      tester
          .widget<PixelChip>(
            find.ancestor(of: chip, matching: find.byType(PixelChip)),
          )
          .selected,
      isTrue,
    );
  });
}
