import 'dart:io';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Nhánh có hệ tệp thật. Đây là nơi duy nhất được phép dùng `Image.file` và
/// `CachedNetworkImage` (R1/R2 trong `test/unit/web_platform_boundary_test.dart`):
/// trên trình duyệt cả hai đều không tồn tại, mà compiler web thì im lặng.
class ReceiptCacheImage extends StatelessWidget {
  const ReceiptCacheImage({
    super.key,
    required this.url,
    this.cacheKey,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorBuilder,
  });

  final String url;

  /// Path object trong Storage, dùng làm khóa cache vì signed URL đổi mỗi phiên.
  final String? cacheKey;
  final double? width;
  final double? height;
  final BoxFit fit;
  final WidgetBuilder? placeholder;
  final Widget Function(BuildContext context, Object error)? errorBuilder;

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: url,
      cacheKey: cacheKey,
      fit: fit,
      width: width,
      height: height,
      placeholder: placeholder == null
          ? null
          : (_, __) => placeholder!(context),
      errorWidget: errorBuilder == null
          ? null
          : (_, __, error) => errorBuilder!(context, error),
    );
  }
}

/// Ảnh nháp chưa upload: trên nền tảng này `draftHandle` thật sự là một đường dẫn.
class ReceiptLocalImage extends StatelessWidget {
  const ReceiptLocalImage({
    super.key,
    this.draftHandle,
    this.bytes,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorBuilder,
  });

  final String? draftHandle;

  /// Ảnh đang có sẵn trong bộ nhớ (vừa chụp, vừa chọn) thắng `draftHandle`:
  /// khỏi đọc lại một tệp vừa ghi.
  final Uint8List? bytes;
  final double? width;
  final double? height;
  final BoxFit fit;
  final WidgetBuilder? placeholder;
  final Widget Function(BuildContext context, Object error)? errorBuilder;

  @override
  Widget build(BuildContext context) {
    final data = bytes;
    if (data != null) return _memory(context, data);
    final handle = draftHandle;
    if (handle == null) return _fallback(context);
    return Image.file(
      File(handle),
      fit: fit,
      width: width,
      height: height,
      errorBuilder: (_, error, __) => _error(context, error),
    );
  }

  Widget _memory(BuildContext context, Uint8List data) => Image.memory(
    data,
    fit: fit,
    width: width,
    height: height,
    errorBuilder: (_, error, __) => _error(context, error),
  );

  Widget _error(BuildContext context, Object error) =>
      errorBuilder?.call(context, error) ?? _fallback(context);

  Widget _fallback(BuildContext context) =>
      placeholder?.call(context) ?? const SizedBox.shrink();
}
