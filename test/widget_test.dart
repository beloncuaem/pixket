import 'package:flutter_test/flutter_test.dart';
import 'package:chi_tieu/core/utils/currency_formatter.dart';
import 'package:chi_tieu/data/models/expense.dart';
import 'package:chi_tieu/data/models/category.dart';

void main() {
  group('CurrencyFormatter Tests', () {
    test('Formats VND properly', () {
      expect(CurrencyFormatter.format(35000), '35.000\u00a0đ');
      expect(CurrencyFormatter.format(1500000), '1.500.000\u00a0đ');
      expect(CurrencyFormatter.format(0), '0\u00a0đ');
    });
  });

  group('Expense Model Tests', () {
    test('Expense creation and priority labels', () {
      final expense = Expense(
        caption: 'Ăn trưa',
        amount: 35000,
        categoryId: 1,
        priority: 0,
        createdAt: DateTime(2026, 10, 4, 12, 30),
      );

      expect(expense.caption, 'Ăn trưa');
      expect(expense.amount, 35000);
      expect(expense.priorityLabel, 'Thiết yếu');
      expect(expense.dateTime, DateTime(2026, 10, 4, 12, 30));
    });

    test('Expense toMap and fromMap serialization', () {
      final date = DateTime(2026, 10, 4, 12, 30);
      final expense = Expense(
        id: 1,
        caption: 'Mua sách',
        amount: 120000,
        categoryId: 5,
        priority: 1,
        createdAt: date,
      );

      final map = expense.toMap();
      final fromMap = Expense.fromMap(map);

      expect(fromMap.id, 1);
      expect(fromMap.caption, 'Mua sách');
      expect(fromMap.amount, 120000);
      expect(fromMap.priority, 1);
      expect(fromMap.priorityLabel, 'Rất cần');
    });
  });

  group('Category Model Tests', () {
    test('Category serialization', () {
      final category = Category(
        id: 1,
        name: 'Ăn uống',
        icon: '🍜',
        isDefault: true,
      );

      final map = category.toMap();
      final fromMap = Category.fromMap(map);

      expect(fromMap.name, 'Ăn uống');
      expect(fromMap.icon, '🍜');
      expect(fromMap.isDefault, true);
    });
  });
}
