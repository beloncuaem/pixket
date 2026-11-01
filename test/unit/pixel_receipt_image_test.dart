import 'package:flutter_test/flutter_test.dart';

import 'package:chi_tieu/widgets/pixel/pixel_receipt_image.dart';

/// `storagePathOf` chỉ công nhận path có tên tệp UUID thật (36 ký tự hex+dấu),
/// nên fixture phải dùng uuid hợp lệ chứ không phải chuỗi "uuid" rút gọn.
const String _objectPath = '0f1c2b3d-4e5f-4a6b-8c9d-0e1f2a3b4c5d/a.png';

void main() {
  group('resolveReceiptImage', () {
    test('ưu tiên signed URL khi có', () {
      final r = resolveReceiptImage(
        imagePath: _objectPath,
        displayImageUrl: 'https://x/signed/a.png',
      );
      expect(r.source, ReceiptImageSource.signedUrl);
      expect(r.url, 'https://x/signed/a.png');
      expect(r.cacheKey, _objectPath);
      expect(r.localPath, isNull);
    });

    test('đường dẫn local là file tạm khi chưa upload xong', () {
      final r = resolveReceiptImage(imagePath: '/data/user/0/tmp/IMG_1.jpg');
      expect(r.source, ReceiptImageSource.localFile);
      expect(r.localPath, '/data/user/0/tmp/IMG_1.jpg');
      expect(r.url, isNull);
      expect(r.cacheKey, isNull);
    });

    test('URL cũ không có chữ ký thì không hiển thị', () {
      final r = resolveReceiptImage(imagePath: 'https://old.public/uuid/b.png');
      expect(r.source, ReceiptImageSource.none);
      expect(r.url, isNull);
    });

    test('không có ảnh thì none', () {
      expect(resolveReceiptImage().source, ReceiptImageSource.none);
      expect(
        resolveReceiptImage(imagePath: '', displayImageUrl: null).source,
        ReceiptImageSource.none,
      );
    });
  });
}
