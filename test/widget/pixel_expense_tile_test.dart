import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pixket/core/theme/app_theme.dart';
import 'package:pixket/data/models/expense.dart';
import 'package:pixket/widgets/pixel/app_icon.dart';
import 'package:pixket/widgets/pixel/pixel_expense_tile.dart';
import 'package:pixket/widgets/pixel/pixel_screen_header.dart';

void main() {
  Expense makeExpense() => Expense(
    caption: 'Mua cà phê',
    amount: 45000,
    categoryId: 3,
    priority: 0,
    createdAt: DateTime(2026, 11, 1, 13, 25),
  );

  // PixelScreenHeader giờ chứa RainbowRule (Consumer) nên cần ProviderScope.
  Widget wrap(Widget child) => ProviderScope(
    child: MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(body: SizedBox(width: 420, child: child)),
    ),
  );

  testWidgets('tile hiện tên danh mục, ghi chú, số tiền và giờ', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        PixelExpenseTile(
          expense: makeExpense(),
          categoryName: 'Cà phê',
          onTap: (_) {},
        ),
      ),
    );
    expect(find.text('Cà phê'), findsOneWidget);
    expect(find.text('Mua cà phê'), findsOneWidget);
    expect(find.textContaining('45.000'), findsOneWidget);
    expect(find.text('13:25'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tile có Dismissible key theo id và hiện nền Xóa khi vuốt', (
    tester,
  ) async {
    Expense makeRow() => Expense(
      id: 7,
      caption: 'Mua cà phê',
      amount: 45000,
      categoryId: 3,
      createdAt: DateTime(2026, 11, 1, 13, 25),
    );
    final expense = makeRow();
    Expense? dismissed;
    await tester.pumpWidget(
      wrap(
        PixelExpenseTile(
          expense: expense,
          categoryName: 'Cà phê',
          onDismiss: (e) => dismissed = e,
        ),
      ),
    );
    final dismissible = tester.widget<Dismissible>(find.byType(Dismissible));
    expect((dismissible.key as ValueKey<String>).value, 'expense-row-7');
    expect(dismissible.direction, DismissDirection.endToStart);

    // Nền xóa chỉ được dựng trong lúc vuốt, nên phải giữ gesture đang chạy.
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(PixelExpenseTile)),
    );
    await gesture.moveBy(const Offset(-80, 0));
    await tester.pump();
    expect(find.byKey(ValueKey('delete-bg-7')), findsOneWidget);
    expect(find.text('Xóa'), findsOneWidget);
    await gesture.up();
    await tester.pumpAndSettle();
    expect(dismissed, isNull); // chưa vượt ngưỡng nên hàng không bị xóa
  });

  testWidgets('vuốt hết cỡ báo cáo xóa cho onDismiss', (tester) async {
    Expense? dismissed;
    await tester.pumpWidget(
      wrap(
        PixelExpenseTile(
          expense: Expense(
            id: 8,
            caption: 'Tiền xe',
            amount: 20000,
            categoryId: 4,
            createdAt: DateTime(2026, 11, 1, 8),
          ),
          categoryName: 'Di chuyển',
          onDismiss: (e) => dismissed = e,
        ),
      ),
    );
    await tester.drag(find.byType(Dismissible), const Offset(-460, 0));
    await tester.pumpAndSettle();
    expect(dismissed?.caption, 'Tiền xe');
  });

  testWidgets('không có onDismiss thì không có Dismissible', (tester) async {
    await tester.pumpWidget(
      wrap(PixelExpenseTile(expense: makeExpense(), categoryName: 'Cà phê')),
    );
    expect(find.byType(Dismissible), findsNothing);
  });

  testWidgets('header có nút menu 48dp, title và subtitle', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      wrap(
        PixelScreenHeader(
          title: 'TỔNG QUAN',
          subtitle: 'tháng 11/2026',
          onMenuTap: () => taps++,
        ),
      ),
    );
    expect(find.text('TỔNG QUAN'), findsOneWidget);
    expect(find.text('tháng 11/2026'), findsOneWidget);
    final menu = find.byType(IconButton);
    expect(menu, findsOneWidget);
    final size = tester.getSize(menu);
    expect(size.width, greaterThanOrEqualTo(48));
    expect(size.height, greaterThanOrEqualTo(48));
    await tester.tap(menu);
    expect(taps, 1);
    expect(
      tester.getSize(find.byType(PixelScreenHeader)).height,
      greaterThanOrEqualTo(64),
    );
  });

  testWidgets('header chỉ có onBackTap thì vẽ nút back', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      wrap(PixelScreenHeader(title: 'ẢNH', onBackTap: () => taps++)),
    );
    expect(find.text('Quay lại'), findsNothing);
    final icon = tester.widget<AppIcon>(
      find.descendant(
        of: find.byType(IconButton),
        matching: find.byType(AppIcon),
      ),
    );
    expect(icon.name, 'back');
    await tester.tap(find.byType(IconButton));
    expect(taps, 1);
  });
}
