import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:pixket/data/models/expense.dart';
import 'package:pixket/widgets/pixel/pixel_receipt_image.dart';

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
      expect(r.draftHandle, isNull);
    });

    test('ảnh nháp còn trong phiên thì là draftHandle khi chưa upload xong', () {
      final r = resolveReceiptImage(imagePath: '/data/user/0/tmp/IMG_1.jpg');
      expect(r.source, ReceiptImageSource.localDraft);
      expect(r.draftHandle, '/data/user/0/tmp/IMG_1.jpg');
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

  group('PixelReceiptImage.source', () {
    test('tệp tạm từ camera thành draftHandle', () {
      final widget = PixelReceiptImage.source(
        '/data/user/0/tmp/IMG_1.jpg',
        semanticLabel: 'Ảnh khoản chi',
      );
      expect(widget.draftHandle, '/data/user/0/tmp/IMG_1.jpg');
      expect(widget.displayUrl, isNull);
      expect(widget.cacheKey, isNull);
      expect(widget.semanticLabel, 'Ảnh khoản chi');
    });

    test('bytes có sẵn thì đi kèm handle, không thay handle', () {
      // PixelReceiptImage ưu tiên localBytes khi render, nhưng resolveReceiptImage
      // vẫn phải trả draftHandle để một ảnh nháp còn đọc lại được sau rebuild.
      final widget = PixelReceiptImage.source(
        '/data/user/0/tmp/IMG_1.jpg',
        bytes: Uint8List.fromList([1, 2, 3]),
      );
      expect(widget.localBytes, Uint8List.fromList([1, 2, 3]));
      expect(widget.draftHandle, '/data/user/0/tmp/IMG_1.jpg');
    });

    test('không có đường dẫn thì về placeholder', () {
      final widget = PixelReceiptImage.source(null);
      expect(widget.draftHandle, isNull);
      expect(widget.localBytes, isNull);
      expect(widget.displayUrl, isNull);
    });

    test('khi sửa thì lấy signed URL của khoản chi đã lưu', () {
      final expense = Expense(
        caption: 'Đồ ăn',
        amount: 30000,
        categoryId: 1,
        createdAt: DateTime(2026, 11, 1, 12),
        imagePath: _objectPath,
        displayImageUrl: 'https://x/signed/a.png',
      );
      final widget = PixelReceiptImage.source(_objectPath, expense: expense);
      expect(widget.displayUrl, 'https://x/signed/a.png');
      expect(widget.cacheKey, _objectPath);
      expect(widget.draftHandle, isNull);
    });
  });
}
