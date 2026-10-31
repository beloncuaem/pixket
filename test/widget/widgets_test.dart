import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chi_tieu/widgets/amount_display.dart';
import 'package:chi_tieu/widgets/priority_badge.dart';
import 'package:chi_tieu/widgets/category_chip.dart';
import 'package:chi_tieu/widgets/expense_card.dart';
import 'package:chi_tieu/data/models/expense.dart';
import 'package:chi_tieu/data/models/category.dart';
import 'package:chi_tieu/widgets/pixel/app_icon.dart';

/// Glyph pixel tương ứng emoji cũ `🍜`, dùng để kiểm tra ánh xạ emoji → glyph.
final Finder forkKnifeGlyph = find.byWidgetPredicate(
  (widget) => widget is AppIcon && widget.name == 'forkKnife',
);

void main() {
  group('AmountDisplay Widget Tests', () {
    testWidgets('Renders formatted currency text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: AmountDisplay(amount: 150000))),
      );

      expect(find.text('150.000\u00a0đ'), findsOneWidget);
    });

    testWidgets('Applies custom color and style', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AmountDisplay(
              amount: 50000,
              color: Colors.red,
              style: TextStyle(fontSize: 20),
            ),
          ),
        ),
      );

      final textWidget = tester.widget<Text>(find.text('50.000\u00a0đ'));
      expect(textWidget.style?.color, Colors.red);
      expect(textWidget.style?.fontSize, 20);
    });
  });

  group('PriorityBadge Widget Tests', () {
    testWidgets('Renders correct label for priority 0 (Thiết yếu)', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: PriorityBadge(priority: 0))),
      );
      expect(find.text('Thiết yếu'), findsOneWidget);
    });

    testWidgets('Renders correct label for priority 1 (Rất cần)', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: PriorityBadge(priority: 1))),
      );
      expect(find.text('Rất cần'), findsOneWidget);
    });

    testWidgets('Renders correct label for priority 2 (Cần vừa)', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: PriorityBadge(priority: 2))),
      );
      expect(find.text('Cần vừa'), findsOneWidget);
    });

    testWidgets('Renders correct label for priority 3 (Chưa cần)', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: PriorityBadge(priority: 3))),
      );
      expect(find.text('Chưa cần'), findsOneWidget);
    });
  });

  group('CategoryChip Widget Tests', () {
    testWidgets('Displays category icon, name and handles tap', (tester) async {
      bool tapped = false;
      final category = Category(id: 1, name: 'Ăn uống', icon: '🍜');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryChip(
              category: category,
              isSelected: true,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      expect(forkKnifeGlyph, findsOneWidget);
      expect(find.text('Ăn uống'), findsOneWidget);

      await tester.tap(find.byType(CategoryChip));
      expect(tapped, isTrue);
    });
  });

  group('ExpenseCard Widget Tests', () {
    testWidgets('Renders ExpenseCard with details', (tester) async {
      final category = Category(id: 1, name: 'Ăn uống', icon: '🍜');
      final expense = Expense(
        id: 1,
        caption: 'Phở bò Hà Nội',
        amount: 45000,
        categoryId: 1,
        priority: 0,
        createdAt: DateTime(2026, 10, 14, 7, 30),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExpenseCard(expense: expense, category: category),
          ),
        ),
      );

      expect(find.text('Phở bò Hà Nội'), findsOneWidget);
      expect(find.text('Ăn uống'), findsOneWidget);
      expect(forkKnifeGlyph, findsNWidgets(2));
      expect(find.text('Thiết yếu'), findsOneWidget);
      expect(find.text('45.000\u00a0đ'), findsOneWidget);
      expect(find.text('07:30'), findsOneWidget);
    });
  });
}
