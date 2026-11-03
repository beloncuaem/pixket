import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import 'package:pixket/core/utils/square_image.dart';

Uint8List jpeg(int width, int height) =>
    img.encodeJpg(img.Image(width: width, height: height), quality: 90);

void main() {
  group('isSquareImagePath', () {
    test('nhận marker của ảnh đã vuông', () {
      expect(isSquareImagePath('user-1/1710_204533_sq.jpg'), isTrue);
    });

    test('ảnh legacy không marker trả false', () {
      expect(isSquareImagePath('user-1/1710_204533.jpg'), isFalse);
      expect(isSquareImagePath(null), isFalse);
      expect(isSquareImagePath(''), isFalse);
    });
  });

  group('cropToSquareBytes', () {
    test('vuông lớn hơn cạnh chuẩn thì hạ về 1200', () {
      final out = cropToSquareBytes(jpeg(2000, 1500));
      expect(out, isNotNull);
      final decoded = img.decodeImage(out!);
      expect(decoded!.width, squareImageSide);
      expect(decoded.height, squareImageSide);
    });

    test('ảnh dọc cắt theo chiều rộng rồi hạ về cạnh chuẩn', () {
      final out = cropToSquareBytes(jpeg(1500, 2400));
      final decoded = img.decodeImage(out!);
      expect(decoded!.width, squareImageSide);
      expect(decoded.height, squareImageSide);
    });

    test('ảnh ngang cắt theo chiều cao, cạnh nhỏ hơn chuẩn thì giữ nguyên', () {
      final out = cropToSquareBytes(jpeg(1600, 900));
      final decoded = img.decodeImage(out!);
      expect(decoded!.width, 900);
      expect(decoded.height, 900);
    });

    test('ảnh nhỏ hơn cạnh chuẩn thì không phóng to', () {
      final out = cropToSquareBytes(jpeg(300, 200));
      final decoded = img.decodeImage(out!);
      expect(decoded!.width, 200);
      expect(decoded.height, 200);
    });

    test('bytes không giải mã được trả null để caller giữ ảnh gốc', () {
      expect(cropToSquareBytes(Uint8List.fromList([1, 2, 3, 4])), isNull);
    });
  });
}
