import 'dart:typed_data';

import 'package:flutter/material.dart';

/// Mặc định của conditional export — chỉ chạy trên nền tảng không có
/// `dart.library.io` lẫn `dart.library.js_interop`. Ở đây không có bất kỳ chỗ nào
/// để lấy ảnh về nên widget không vẽ gì; khác `square_image_stub.dart`, nơi âm
/// thầm trả nguyên trạng sẽ sinh ảnh chữ nhật sai tỷ lệ nên phải ném.
class ReceiptCacheImage extends StatelessWidget {
  const ReceiptCacheImage({
    super.key,
    required String url,
    String? cacheKey,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    WidgetBuilder? placeholder,
    Widget Function(BuildContext context, Object error)? errorBuilder,
  });

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class ReceiptLocalImage extends StatelessWidget {
  const ReceiptLocalImage({
    super.key,
    String? draftHandle,
    Uint8List? bytes,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    WidgetBuilder? placeholder,
    Widget Function(BuildContext context, Object error)? errorBuilder,
  });

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
