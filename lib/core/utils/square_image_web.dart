import 'dart:js_interop';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:web/web.dart' as web;

import 'square_image_core.dart';

/// Cắt vuông bằng pipeline đồ họa gốc của trình duyệt: `createImageBitmap` với
/// `imageOrientation: 'from-image'` đọc EXIF và xoay ảnh hộ ta (tương đương
/// `img.bakeOrientation`), `OffscreenCanvas` cắt giữa, `convertToBlob` nén JPEG.
/// Không chạy trên isolate nào cả vì đây là code native của browser — mà trên
/// web `compute()` vốn chạy cùng thread, nên cách này mới không đơ UI.
Future<Uint8List?> squareBytes(Uint8List source) async {
  try {
    final blob = web.Blob(
      <JSAny>[source.toJS].toJS,
      web.BlobPropertyBag(type: 'image/jpeg'),
    );
    final bitmap = await web.window
        .createImageBitmap(
          blob,
          web.ImageBitmapOptions(imageOrientation: 'from-image'),
        )
        .toDart;

    final side = math.min(bitmap.width, bitmap.height);
    if (side <= 0) return null;

    final canvas = web.OffscreenCanvas(squareImageSide, squareImageSide);
    final context =
        canvas.getContext('2d') as web.OffscreenCanvasRenderingContext2D?;
    if (context == null) return null;
    context.drawImage(
      bitmap,
      (bitmap.width - side) ~/ 2,
      (bitmap.height - side) ~/ 2,
      side,
      side,
      0,
      0,
      squareImageSide,
      squareImageSide,
    );

    final encoded = await canvas
        .convertToBlob(
          web.ImageEncodeOptions(
            type: 'image/jpeg',
            quality: squareImageQuality / 100,
          ),
        )
        .toDart;
    final buffer = await encoded.arrayBuffer().toDart;
    return buffer.toDart.asUint8List();
  } catch (_) {
    // Ảnh rác khiến createImageBitmap reject chứ không trả bitmap rỗng, mà chữ
    // ký của squareBytes hứa null — không ném — để caller giữ nguyên ảnh gốc.
    return null;
  }
}
