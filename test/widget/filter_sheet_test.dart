import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pixket/core/theme/app_theme.dart';
import 'package:pixket/data/models/category.dart';
import 'package:pixket/data/models/priority_level.dart';
import 'package:pixket/screens/home/expense_filter_sheet.dart';
import 'package:pixket/widgets/pixel/pixel_button.dart';
import 'package:pixket/widgets/pixel/pixel_chip.dart';
import 'package:pixket/widgets/pixel/pixel_text_field.dart';

void main() {
  final categories = [
    Category(id: 1, name: 'Ăn uống', icon: 'forkKnife'),
    Category(id: 2, name: 'Đi lại', icon: 'car'),
  ];
  const priorities = [
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
  ];

  Future<void> openSheet(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: PixelButton(
                label: 'Lọc',
                onPressed: () => openExpenseFilterSheet(
                  context,
                  initial: const ExpenseFilter(),
                  categories: categories,
                  priorities: priorities,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Lọc'));
    await tester.pumpAndSettle();
  }

  testWidgets('sheet có chip danh mục, mức độ và 2 ô số tiền', (tester) async {
    await openSheet(tester);
    expect(find.text('Lọc giao dịch'), findsOneWidget);
    expect(find.text('Ăn uống'), findsOneWidget);
    expect(find.text('Cần thiết'), findsOneWidget);
    expect(find.byType(PixelChip), findsWidgets);
    expect(find.byType(PixelTextField), findsNWidgets(2));
    expect(find.text('Từ số tiền'), findsOneWidget);
    expect(find.text('Đến số tiền'), findsOneWidget);
    expect(find.byType(ChoiceChip), findsNothing);
  });

  testWidgets('nhập 1000000 được nhóm nghìn trước khi parse', (tester) async {
    await openSheet(tester);
    await tester.enterText(find.byType(PixelTextField).first, '1000000');
    await tester.pump();
    expect(find.text('1.000.000'), findsOneWidget);
    await tester.tap(find.text('ÁP DỤNG'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('chip danh mục bật/tắt đúng một lần chạm', (tester) async {
    await openSheet(tester);
    await tester.tap(find.text('Ăn uống'));
    await tester.pump();
    expect(
      tester
          .widget<PixelChip>(
            find.ancestor(
              of: find.text('Ăn uống'),
              matching: find.byType(PixelChip),
            ),
          )
          .selected,
      isTrue,
    );
    await tester.tap(find.text('Ăn uống'));
    await tester.pump();
    expect(
      tester
          .widget<PixelChip>(
            find.ancestor(
              of: find.text('Ăn uống'),
              matching: find.byType(PixelChip),
            ),
          )
          .selected,
      isFalse,
    );
  });

  testWidgets('nút XÓA BỘ LỌC đóng sheet', (tester) async {
    await openSheet(tester);
    await tester.tap(find.text('XÓA BỘ LỌC'));
    await tester.pumpAndSettle();
    expect(find.byType(ExpenseFilterSheet), findsNothing);
  });
}
