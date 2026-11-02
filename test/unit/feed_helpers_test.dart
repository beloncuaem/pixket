import 'package:flutter_test/flutter_test.dart';
import 'package:pixket/data/models/expense.dart';
import 'package:pixket/screens/camera/feed_helpers.dart';

Expense _expense({int? id, String? imagePath, required DateTime createdAt}) {
  return Expense(
    id: id,
    imagePath: imagePath,
    caption: 'Khoản chi $id',
    amount: 10000,
    categoryId: 1,
    createdAt: createdAt,
  );
}

void main() {
  group('buildFeedPhotos', () {
    test('Bỏ qua khoản chi không có ảnh', () {
      final expenses = [
        _expense(id: 1, imagePath: 'a.jpg', createdAt: DateTime(2026, 10, 1)),
        _expense(id: 2, createdAt: DateTime(2026, 10, 2)),
        _expense(id: 3, imagePath: '   ', createdAt: DateTime(2026, 10, 3)),
        _expense(id: 4, imagePath: 'b.jpg', createdAt: DateTime(2026, 10, 4)),
      ];

      final photos = buildFeedPhotos(expenses);

      expect(photos.map((e) => e.id), [4, 1]);
    });

    test('Sắp xếp ảnh mới nhất lên đầu', () {
      final expenses = [
        _expense(id: 1, imagePath: 'old.jpg', createdAt: DateTime(2026, 9, 1)),
        _expense(
          id: 2,
          imagePath: 'new.jpg',
          createdAt: DateTime(2026, 10, 20),
        ),
        _expense(id: 3, imagePath: 'mid.jpg', createdAt: DateTime(2026, 10, 5)),
      ];

      final photos = buildFeedPhotos(expenses);

      expect(photos.map((e) => e.id), [2, 3, 1]);
    });

    test('Danh sách rỗng trả về rỗng', () {
      expect(buildFeedPhotos(const []), isEmpty);
    });
  });
}
