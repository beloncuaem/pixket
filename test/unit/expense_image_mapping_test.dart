import 'package:flutter_test/flutter_test.dart';

import 'package:chi_tieu/data/models/expense.dart';
import 'package:chi_tieu/data/repositories/expense_image_mapping.dart';

/// Storage path thật luôn có segment đầu là id người dùng dạng UUID.
const String u = 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee';

Expense _e(String? image, {String caption = 'A'}) => Expense(
  caption: caption,
  amount: 10000,
  categoryId: 1,
  createdAt: DateTime(2026, 11, 1),
  imagePath: image,
);

void main() {
  group('storagePathsOf', () {
    test('bỏ khoản chi không có ảnh và chuẩn hóa URL legacy', () {
      final paths = storagePathsOf([
        _e('$u/a.jpg'),
        _e(null),
        _e(
          'https://x.supabase.co/storage/v1/object/public/expense-receipts/$u/b.jpg',
        ),
      ]);
      expect(paths, ['$u/a.jpg', '$u/b.jpg']);
    });

    test('bỏ đường dẫn tệp cục bộ và giá trị rác', () {
      expect(
        storagePathsOf([
          _e('/data/user/0/com.x/app/CACHE/IMG_1.jpg'),
          _e('not-a-path.jpg'),
        ]),
        isEmpty,
      );
    });
  });

  group('attachSignedUrls', () {
    test('gán đúng URL theo path và giữ nguyên các field khác', () {
      final rows = [_e('$u/a.jpg', caption: 'Cà phê'), _e('$u/missing.jpg')];
      final out = attachSignedUrls(rows, {'$u/a.jpg': 'https://signed/a'});

      expect(out[0].displayImageUrl, 'https://signed/a');
      expect(out[0].caption, 'Cà phê');
      expect(out[0].imagePath, '$u/a.jpg');
      expect(out[1].displayImageUrl, isNull);
    });

    test('không mutate danh sách gốc', () {
      final rows = [_e('$u/a.jpg')];
      attachSignedUrls(rows, {'$u/a.jpg': 'https://signed/a'});
      expect(rows.single.displayImageUrl, isNull);
    });
  });
}
