import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'local_draft_store.dart';

/// Nhánh trình duyệt: không có hệ tệp và không có `flutter_cache_manager`, nên
/// phần tải/ghi cache ảnh mạng do browser lo, còn ảnh nháp phải đi qua
/// `localDraftStore`. Chữ ký giữ đúng như nhánh `_io` để `PixelReceiptImage` chỉ
/// cần một đoạn code.
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

  /// Browser tự cache theo URL, và signed URL được ký lại mỗi phiên nên một ảnh
  /// cũ không bao giờ được phát cho chữ ký mới. Giữ tham số chỉ để hai nhánh
  /// giống chữ ký nhau.
  final String? cacheKey;
  final double? width;
  final double? height;
  final BoxFit fit;
  final WidgetBuilder? placeholder;
  final Widget Function(BuildContext context, Object error)? errorBuilder;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      fit: fit,
      width: width,
      height: height,
      loadingBuilder: (context, child, progress) {
        // `progress == null` nghĩa là đã tải xong; khi còn tải thì chưa có gì để
        // vẽ, nên dùng placeholder của caller chứ không phải ảnh lỗi.
        if (progress == null) return child;
        return placeholder?.call(context) ?? const SizedBox.shrink();
      },
      errorBuilder: (context, error, _) =>
          errorBuilder?.call(context, error) ??
          placeholder?.call(context) ??
          const SizedBox.shrink(),
    );
  }
}

/// Trên web `draftHandle` không phải đường dẫn mà là key của một Map trong phiên
/// (`WebLocalDraftStore`), nên ảnh nháp chỉ hiện được sau một lượt đọc async.
class ReceiptLocalImage extends StatefulWidget {
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
  final Uint8List? bytes;
  final double? width;
  final double? height;
  final BoxFit fit;
  final WidgetBuilder? placeholder;
  final Widget Function(BuildContext context, Object error)? errorBuilder;

  @override
  State<ReceiptLocalImage> createState() => _ReceiptLocalImageState();
}

class _ReceiptLocalImageState extends State<ReceiptLocalImage> {
  Future<Uint8List?>? _loading;

  @override
  void initState() {
    super.initState();
    _read();
  }

  @override
  void didUpdateWidget(ReceiptLocalImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.draftHandle != widget.draftHandle) _read();
  }

  // Một Future cho mỗi handle, tạo ở đây chứ không ở build(): form khoản chi
  // rebuild mỗi lần gõ, và Future mới ở mỗi khung hình sẽ làm ảnh nháp nhấp nháy
  // giữa placeholder và ảnh thật suốt phiên.
  void _read() {
    final handle = widget.draftHandle;
    _loading = handle == null ? null : localDraftStore.readBytes(handle);
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.bytes;
    if (data != null) return _memory(context, data);
    final future = _loading;
    if (future == null) return _fallback(context);
    return FutureBuilder<Uint8List?>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.hasError) return _error(context, snapshot.error as Object);
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox.shrink();
        }
        final bytes = snapshot.data;
        // null khi handle không còn trong phiên (đã upload xong và dọn, hoặc trang
        // mới mở): đó là "không có ảnh", không phải "đang tải".
        if (bytes == null) return _fallback(context);
        return _memory(context, bytes);
      },
    );
  }

  Widget _memory(BuildContext context, Uint8List data) => Image.memory(
    data,
    fit: widget.fit,
    width: widget.width,
    height: widget.height,
    errorBuilder: (_, error, __) => _error(context, error),
  );

  Widget _error(BuildContext context, Object error) =>
      widget.errorBuilder?.call(context, error) ?? _fallback(context);

  Widget _fallback(BuildContext context) =>
      widget.placeholder?.call(context) ?? const SizedBox.shrink();
}
