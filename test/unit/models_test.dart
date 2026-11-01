import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chi_tieu/data/models/expense.dart';
import 'package:chi_tieu/data/models/category.dart';
import 'package:chi_tieu/data/models/budget.dart';
import 'package:chi_tieu/data/models/priority_level.dart';

void main() {
  group('Expense Model Tests', () {
    test('Expense initialization and properties', () {
      final now = DateTime(2026, 10, 14, 15, 30);
      final expense = Expense(
        id: 10,
        imagePath: '/path/to/img.jpg',
        caption: 'Cà phê sáng',
        amount: 30000,
        categoryId: 2,
        priority: 0,
        createdAt: now,
      );

      expect(expense.id, 10);
      expect(expense.imagePath, '/path/to/img.jpg');
      expect(expense.caption, 'Cà phê sáng');
      expect(expense.amount, 30000);
      expect(expense.categoryId, 2);
      expect(expense.priority, 0);
      expect(expense.createdAt, now);
      expect(expense.dateTime, now);
      expect(expense.date, now);
      expect(expense.isDeleted, false);
      expect(expense.priorityLabel, 'Thiết yếu');
    });

    test('Priority label returns empty string when out of bounds', () {
      final expense = Expense(
        caption: 'Test',
        amount: 1000,
        categoryId: 1,
        priority: 99,
        createdAt: DateTime.now(),
      );
      expect(expense.priorityLabel, '');
    });

    test('Expense copyWith works correctly', () {
      final initial = Expense(
        id: 1,
        caption: 'Ăn tối',
        amount: 50000,
        categoryId: 1,
        priority: 1,
        createdAt: DateTime(2026, 1, 1),
      );

      final updated = initial.copyWith(
        caption: 'Ăn tối sang chảnh',
        amount: 250000,
        deletedAt: DateTime(2026, 1, 2),
      );

      expect(updated.id, 1);
      expect(updated.caption, 'Ăn tối sang chảnh');
      expect(updated.amount, 250000);
      expect(updated.categoryId, 1);
      expect(updated.isDeleted, true);
    });

    test('Expense toMap and fromMap roundtrip', () {
      final date = DateTime(2026, 10, 14, 12, 0, 0);
      final deleted = DateTime(2026, 10, 14, 13, 0, 0);
      final expense = Expense(
        id: 5,
        imagePath: '/data/photo.png',
        caption: 'Đổ xăng',
        amount: 70000,
        categoryId: 3,
        priority: 1,
        createdAt: date,
        deletedAt: deleted,
      );

      final map = expense.toMap();
      expect(map['id'], 5);
      expect(map['image_path'], '/data/photo.png');
      expect(map['caption'], 'Đổ xăng');
      expect(map['amount'], 70000.0);
      expect(map['category_id'], 3);
      expect(map['priority'], 1);
      expect(map['created_at'], date.toIso8601String());
      expect(map['deleted_at'], deleted.toIso8601String());

      final restored = Expense.fromMap(map);
      expect(restored.id, expense.id);
      expect(restored.imagePath, expense.imagePath);
      expect(restored.caption, expense.caption);
      expect(restored.amount, expense.amount);
      expect(restored.categoryId, expense.categoryId);
      expect(restored.priority, expense.priority);
      expect(restored.createdAt, expense.createdAt);
      expect(restored.deletedAt, expense.deletedAt);
      expect(restored.isDeleted, true);
    });
  });

  group('Category Model Tests', () {
    test('Default category creation sets createdAt automatically', () {
      final before = DateTime.now().subtract(const Duration(seconds: 1));
      final cat = Category(name: 'Giải trí', icon: '🎮');
      final after = DateTime.now().add(const Duration(seconds: 1));

      expect(cat.name, 'Giải trí');
      expect(cat.icon, '🎮');
      expect(cat.isDefault, false);
      expect(cat.createdAt.isAfter(before), true);
      expect(cat.createdAt.isBefore(after), true);
    });

    test('Category copyWith works correctly', () {
      final cat = Category(id: 1, name: 'Cũ', icon: '❓', isDefault: false);
      final updated = cat.copyWith(name: 'Mới', icon: '✨', isDefault: true);

      expect(updated.id, 1);
      expect(updated.name, 'Mới');
      expect(updated.icon, '✨');
      expect(updated.isDefault, true);
    });

    test('Category toMap and fromMap with safe created_at', () {
      final mapWithoutCreatedAt = {
        'id': 2,
        'name': 'Học tập',
        'icon': '📚',
        'is_default': 1,
      };

      final cat = Category.fromMap(mapWithoutCreatedAt);
      expect(cat.id, 2);
      expect(cat.name, 'Học tập');
      expect(cat.icon, '📚');
      expect(cat.isDefault, true);
      expect(cat.createdAt, isNotNull);

      final fullMap = cat.toMap();
      final restored = Category.fromMap(fullMap);
      expect(restored.id, 2);
      expect(restored.name, 'Học tập');
      expect(restored.isDefault, true);
    });
  });

  group('Budget Model Tests', () {
    test('Total budget creation and serialization (categoryId is null)', () {
      final budget = Budget(
        id: 1,
        month: '2026-10',
        categoryId: null,
        amount: 5000000,
      );

      final map = budget.toMap();
      expect(map['id'], 1);
      expect(map['month'], '2026-10');
      expect(map['category_id'], isNull);
      expect(map['amount'], 5000000.0);

      final restored = Budget.fromMap(map);
      expect(restored.id, 1);
      expect(restored.month, '2026-10');
      expect(restored.categoryId, isNull);
      expect(restored.amount, 5000000.0);
    });

    test('Category budget creation and serialization', () {
      final budget = Budget(
        id: 2,
        month: '2026-10',
        categoryId: 3,
        amount: 1500000,
      );

      final map = budget.toMap();
      expect(map['category_id'], 3);

      final restored = Budget.fromMap(map);
      expect(restored.categoryId, 3);
      expect(restored.amount, 1500000.0);
    });

    test('Budget copyWith works properly', () {
      final budget = Budget(month: '2026-10', amount: 1000000);
      final updated = budget.copyWith(id: 10, amount: 2000000);
      expect(updated.id, 10);
      expect(updated.amount, 2000000);
      expect(updated.month, '2026-10');
    });
  });

  group('PriorityLevel Model Tests', () {
    test('PriorityLevel creation and properties', () {
      const level = PriorityLevel(
        id: 0,
        name: 'Thiết yếu',
        colorValue: 0xFF43A047,
        sortOrder: 0,
      );

      expect(level.id, 0);
      expect(level.name, 'Thiết yếu');
      expect(level.colorValue, 0xFF43A047);
      expect(level.color, const Color(0xFF43A047));
      expect(level.sortOrder, 0);
    });

    test('PriorityLevel toMap and fromMap roundtrip', () {
      const level = PriorityLevel(
        id: 2,
        name: 'Cần vừa',
        colorValue: 0xFFFB8C00,
        sortOrder: 2,
      );

      final map = level.toMap();
      final restored = PriorityLevel.fromMap(map);

      expect(restored.id, 2);
      expect(restored.name, 'Cần vừa');
      expect(restored.colorValue, 0xFFFB8C00);
      expect(restored.sortOrder, 2);
    });

    test('PriorityLevel copyWith', () {
      const level = PriorityLevel(
        id: 1,
        name: 'Rất cần',
        colorValue: 0xFF1E88E5,
        sortOrder: 1,
      );

      final updated = level.copyWith(name: 'Cực kỳ cần', sortOrder: 5);
      expect(updated.id, 1);
      expect(updated.name, 'Cực kỳ cần');
      expect(updated.sortOrder, 5);
      expect(updated.colorValue, 0xFF1E88E5);
    });
  });

  group('Expense.displayImageUrl', () {
    Expense sample() => Expense(
      id: 1,
      caption: 'Cà phê',
      amount: 45000,
      categoryId: 3,
      createdAt: DateTime(2026, 11, 1, 9, 30),
      imagePath: 'user-1/1710_204.jpg',
    );

    test('mặc định null và không ghi vào toMap', () {
      final expense = sample();
      expect(expense.displayImageUrl, isNull);
      expect(expense.toMap().containsKey('display_image_url'), isFalse);
    });

    test('copyWith gán URL hiển thị mà không đổi imagePath', () {
      final updated = sample().copyWith(
        displayImageUrl: 'https://signed/abc',
      );
      expect(updated.displayImageUrl, 'https://signed/abc');
      expect(updated.imagePath, 'user-1/1710_204.jpg');
      expect(updated.id, 1);
    });
  });
}
