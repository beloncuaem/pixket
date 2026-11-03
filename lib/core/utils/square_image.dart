import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show compute;
import 'package:image/image.dart' as img;

/// Cạnh ô vuông chuẩn hoá. Đủ nét cho màn điện thoại nhưng vẫn rẻ hơn ảnh
/// full-screen vài lần về dung lượng trong bucket.
const int squareImageSide = 1200;

const int squareImageQuality = 85;

/// Hậu tố vừa đặt tên tệp tạm sau khi cắt, vừa là marker trong path object ở
/// Supabase, nên không cần thêm cột nào để biết ảnh nào đã vuông.
const String squareImageSuffix = '_sq.jpg';

bool isSquareImagePath(String? path) =>
    path != null && path.endsWith(squareImageSuffix);

/// Cắt ô vuông giữa của [bytes] rồi mã hoá JPEG. Trả null khi không giải mã
/// được (HEIC thô, tệp hỏng) để caller giữ nguyên ảnh gốc thay vì mất ảnh.
Uint8List? cropToSquareBytes(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return null;

  // EXIF orientation phải được bake trước khi cắt: ảnh camera dựng đứng vẫn
  // khai width>height nên nếu cắt theo metadata sẽ cắt sai trục.
  final baked = img.bakeOrientation(decoded);
  final side = math.min(baked.width, baked.height);
  if (side <= 0) return null;

  final cropped = img.copyCrop(
    baked,
    x: (baked.width - side) ~/ 2,
    y: (baked.height - side) ~/ 2,
    width: side,
    height: side,
  );
  final scaled = side > squareImageSide
      ? img.copyResize(cropped, width: squareImageSide, height: squareImageSide)
      : cropped;

  return img.encodeJpg(scaled, quality: squareImageQuality);
}

/// Ghi bản vuông của [source] ngay cạnh nó, tên có hậu tố [squareImageSuffix].
/// Trả về [source] khi ảnh đã vuông (tránh nén lại lần hai) hoặc khi không cắt
/// được, để caller vẫn lưu được ảnh gốc thay vì mất trắng.
Future<File> writeSquareCopy(File source) async {
  if (isSquareImagePath(source.path)) return source;

  final bytes = await source.readAsBytes();
  // Decode + encode mất ~1s với ảnh 12 MP, chạy trên isolate để không giật
  // animation của mống mắt sau khi chụp.
  final squared = await compute(cropToSquareBytes, bytes);
  if (squared == null) return source;

  final output = File(
    '${source.parent.path}/pixket_${DateTime.now().microsecondsSinceEpoch}$squareImageSuffix',
  );
  await output.writeAsBytes(squared, flush: true);
  return output;
}
