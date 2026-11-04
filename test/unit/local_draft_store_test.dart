@Tags(['io'])
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pixket/core/platform/local_draft_store.dart';
import 'package:pixket/core/platform/local_draft_store_io.dart';
import 'package:pixket/core/utils/square_image.dart';

Uint8List tinyJpeg() => Uint8List.fromList(<int>[
  // JPEG tối thiểu do package image sinh ra, dùng lại helper của test cắt vuông
  // không được ở đây vì file test không share fixture → tự sinh:
  0xFF, 0xD8, 0xFF, 0xD9,
]);

void main() {
  late Directory dir;
  // Kiểu khai báo là chữ ký chung để import façade ở trên cũng được kiểm tra.
  late LocalDraftStore store;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('pixket_draft_test');
    store = IoLocalDraftStore(dir: dir);
  });
  tearDown(() => dir.deleteSync(recursive: true));

  test('save rồi readBytes trả đúng bytes', () async {
    final bytes = tinyJpeg();
    final handle = await store.save(bytes, extension: 'jpg', squared: false);
    expect(await store.readBytes(handle), bytes);
    expect(await store.exists(handle), isTrue);
  });

  test('squared: true đặt marker squareImageSuffix vào handle', () async {
    final handle = await store.save(
      tinyJpeg(),
      extension: 'jpg',
      squared: true,
    );
    expect(isSquareImagePath(handle), isTrue);
  });

  test(
    'handle không tồn tại: exists false, readBytes null, delete không ném',
    () async {
      final ghost = '${dir.path}/pixket_khong_co.jpg';
      expect(await store.exists(ghost), isFalse);
      expect(await store.readBytes(ghost), isNull);
      await store.delete(ghost);
    },
  );

  test('delete rồi thì không đọc được nữa', () async {
    final handle = await store.save(
      tinyJpeg(),
      extension: 'png',
      squared: false,
    );
    await store.delete(handle);
    expect(await store.exists(handle), isFalse);
  });
}
