@Tags(['web'])
library;

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:pixket/core/utils/square_image.dart';

Uint8List jpegOf(int w, int h) => img.encodeJpg(
  // `fill` là hàm top-level của package:image 4.x, không phải method của Image.
  img.fill(img.Image(width: w, height: h), color: img.ColorRgb8(200, 30, 30)),
);

void main() {
  test('web squareBytes cắt đúng cạnh và trả JPEG hợp lệ', () async {
    final out = await squareBytes(jpegOf(2000, 1500));
    expect(out, isNotNull);
    final decoded = img.decodeImage(out!)!;
    expect(decoded.width, squareImageSide);
    expect(decoded.height, squareImageSide);
  });

  test('web squareBytes không phóng ảnh nhỏ hơn cạnh chuẩn', () async {
    final out = await squareBytes(jpegOf(300, 200));
    expect(out, isNotNull);
    final decoded = img.decodeImage(out!)!;
    expect(decoded.width, 200);
    expect(decoded.height, 200);
  });

  test('web squareBytes trả null cho bytes rác', () async {
    expect(await squareBytes(Uint8List.fromList([1, 2, 3, 4])), isNull);
  });
}
