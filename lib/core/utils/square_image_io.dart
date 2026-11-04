import 'dart:typed_data';

import 'package:flutter/foundation.dart' show compute;

import 'square_image_core.dart';

/// Cắt vuông trên mobile/desktop. Decode + encode mất ~1s với ảnh 12 MP nên chạy
/// trên isolate, nhờ animation của mống mắt sau khi chụp không bị giật.
Future<Uint8List?> squareBytes(Uint8List source) =>
    compute(cropToSquareBytes, source);
