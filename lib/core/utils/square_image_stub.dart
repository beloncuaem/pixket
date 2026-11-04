import 'dart:typed_data';

/// Nhánh mặc định của conditional export — chỉ chạy trên nền tảng không có
/// `dart.library.io` lẫn `dart.library.js_interop`. Throwing loudly có chủ đích:
/// âm thầm trả nguyên trạng sẽ cho ra ảnh chữ nhật sai tỷ lệ.
Future<Uint8List?> squareBytes(Uint8List source) => throw UnsupportedError(
  'Pixket chưa có trình cắt ảnh vuông cho nền tảng này.',
);
