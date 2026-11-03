import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:pixket/core/utils/save_to_gallery.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('gal_dl');
  });

  tearDown(() async {
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  test('khoản chi không có ảnh thì báo rõ ràng', () async {
    expect(
      await saveReceiptToGallery(
        signedUrl: null,
        localPath: null,
        name: 'pixket_1',
      ),
      'Khoản chi này chưa có ảnh để tải.',
    );
  });

  test('signed URL trả lỗi vẫn có thông báo thay vì ném exception', () async {
    final message = await saveReceiptToGallery(
      signedUrl: 'https://signed/a.jpg',
      localPath: null,
      name: 'pixket_1',
      client: MockClient((_) async => http.Response('gone', 404)),
    );

    expect(message, 'Không lưu được ảnh về máy.');
  });

  test(
    'đường dẫn cục bộ không tồn tại trả thông báo, không làm hỏng UI',
    () async {
      final message = await saveReceiptToGallery(
        signedUrl: null,
        localPath: '${tempDir.path}/missing.jpg',
        name: 'pixket_1',
      );

      expect(message, 'Không lưu được ảnh về máy.');
    },
  );
}
