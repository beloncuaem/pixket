import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chi_tieu/data/models/category.dart';
import 'package:chi_tieu/data/models/expense.dart';
import 'package:chi_tieu/widgets/expense_card.dart';

/// Storage path thật có segment đầu là id người dùng dạng UUID.
const String u = 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee';

void main() {
  testWidgets(
    'ExpenseCard dùng displayImageUrl, không đọc imagePath làm URL',
    (tester) async {
      final category = Category(id: 1, name: 'Ăn uống', icon: 'forkKnife');
      final expense = Expense(
        id: 1,
        caption: 'Cà phê sữa',
        amount: 39000,
        categoryId: 1,
        createdAt: DateTime(2026, 11, 1, 8, 30),
        imagePath: '$u/1710_204.jpg',
        displayImageUrl: 'https://signed.example/a.jpg',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExpenseCard(
              expense: expense,
              category: category,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byType(ExpenseCard), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('ExpenseCard không crash khi chưa ký được URL', (tester) async {
    final expense = Expense(
      id: 2,
      caption: 'Gửi xe',
      amount: 5000,
      categoryId: 2,
      createdAt: DateTime(2026, 11, 1, 9, 0),
      imagePath: '$u/1710_205.jpg',
    );

    final category = Category(id: 2, name: 'Di chuyển', icon: 'car');
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ExpenseCard(
            expense: expense,
            category: category,
            onTap: () {},
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });
}
