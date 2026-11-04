import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../core/platform/receipt_cache_image.dart';
import '../../core/theme/app_palette.dart';
import '../../core/utils/storage_paths.dart';
import '../../data/models/expense.dart';
import 'app_icon.dart';

enum ReceiptImageSource { signedUrl, localDraft, none }

typedef ReceiptImageTarget = ({
  ReceiptImageSource source,
  String? url,
  String? draftHandle,
  String? cacheKey,
});

/// Chọn nguồn ảnh hiển thị theo độ tin cậy: signed URL > ảnh nháp trên máy.
/// URL public legacy (bắt đầu bằng http) không còn hợp lệ nên bị loại.
ReceiptImageTarget resolveReceiptImage({
  String? imagePath,
  String? displayImageUrl,
}) {
  if (displayImageUrl != null && displayImageUrl.isNotEmpty) {
    return (
      source: ReceiptImageSource.signedUrl,
      url: displayImageUrl,
      draftHandle: null,
      cacheKey: storagePathOf(imagePath),
    );
  }
  final path = imagePath;
  if (path != null && path.isNotEmpty && !path.startsWith('http')) {
    return (
      source: ReceiptImageSource.localDraft,
      url: null,
      draftHandle: path,
      cacheKey: null,
    );
  }
  return (
    source: ReceiptImageSource.none,
    url: null,
    draftHandle: null,
    cacheKey: null,
  );
}

/// Ô placeholder chung cho mọi ảnh lỗi/thiếu trong app.
Widget receiptPlaceholder({double size = 32}) {
  return Builder(
    builder: (context) {
      final palette = context.palette;
      return ColoredBox(
        color: palette.surfaceAlt,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppIcon(name: 'cloudOff', size: size, color: palette.inkMuted),
              const SizedBox(height: 6),
              Text(
                'Không tải được ảnh',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall
                    ?.copyWith(color: palette.inkMuted),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class PixelReceiptImage extends StatelessWidget {
  const PixelReceiptImage({
    super.key,
    this.draftHandle,
    this.localBytes,
    this.displayUrl,
    this.cacheKey,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.semanticLabel,
    this.radius = 12,
    this.onTap,
  });

  factory PixelReceiptImage.fromExpense(
    Expense expense, {
    double? width,
    double? height,
    String? semanticLabel,
    BoxFit fit = BoxFit.cover,
    double radius = 12,
    VoidCallback? onTap,
  }) {
    final target = resolveReceiptImage(
      imagePath: expense.imagePath,
      displayImageUrl: expense.displayImageUrl,
    );
    return PixelReceiptImage(
      draftHandle: target.draftHandle,
      displayUrl: target.url,
      cacheKey: target.cacheKey,
      width: width,
      height: height,
      fit: fit,
      radius: radius,
      onTap: onTap,
      semanticLabel:
          semanticLabel ??
          (expense.caption.isEmpty
              ? 'Ảnh khoản chi ${expense.amount.toInt()}'
              : 'Ảnh khoản chi: ${expense.caption}'),
    );
  }

  /// Ảnh trong form khoản chi: khi sửa thì lấy dữ liệu đã lưu, khi tạo mới thì
  /// lấy ảnh nháp từ camera.
  factory PixelReceiptImage.source(
    String? path, {
    Expense? expense,
    Uint8List? bytes,
    String? semanticLabel,
  }) {
    if (expense != null) {
      return PixelReceiptImage.fromExpense(
        expense,
        semanticLabel: semanticLabel,
      );
    }
    final target = resolveReceiptImage(imagePath: path);
    return PixelReceiptImage(
      draftHandle: target.draftHandle,
      localBytes: bytes,
      displayUrl: target.url,
      cacheKey: target.cacheKey,
      semanticLabel: semanticLabel,
    );
  }

  /// Giá trị do `LocalDraftStore` sinh ra: trên nền tảng có hệ tệp nó là đường dẫn
  /// thật, trên trình duyệt nó là key của một ảnh trong phiên. File này không được
  /// đối xử nó như đường dẫn — chỉ nhánh render dưới mới hiểu nó.
  final String? draftHandle;

  /// Ảnh đã có sẵn trong bộ nhớ (vừa chụp, vừa chọn) thì thắng `draftHandle`.
  final Uint8List? localBytes;
  final String? displayUrl;
  final String? cacheKey;
  final double? width;
  final double? height;
  final BoxFit fit;
  final String? semanticLabel;
  final double radius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    // Hai nhánh render nằm sau seam `receipt_cache_image.dart`: `Image.file` và
    // `CachedNetworkImage` chỉ tồn tại ở nền tảng có hệ tệp, còn placeholder là
    // phần thuần nên vẫn ở file này.
    final Widget image;
    if (displayUrl != null) {
      image = ReceiptCacheImage(
        url: displayUrl!,
        cacheKey: cacheKey,
        fit: fit,
        width: width,
        height: height,
        placeholder: (_) => ColoredBox(
          color: palette.surfaceAlt,
          child: Center(
            child: AppIcon(
              name: 'dotsThreeOutline',
              size: 16,
              color: palette.inkMuted,
            ),
          ),
        ),
        errorBuilder: (_, __) => receiptPlaceholder(),
      );
    } else if (draftHandle != null || localBytes != null) {
      image = ReceiptLocalImage(
        draftHandle: draftHandle,
        bytes: localBytes,
        fit: fit,
        width: width,
        height: height,
        placeholder: (_) => receiptPlaceholder(),
      );
    } else {
      image = receiptPlaceholder();
    }

    final framed = DecoratedBox(
      decoration: BoxDecoration(
        color: palette.surfaceAlt,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: palette.line, width: 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius - 2),
        child: image,
      ),
    );

    if (onTap == null) {
      return Semantics(image: true, label: semanticLabel, child: framed);
    }
    return Semantics(
      image: true,
      button: true,
      label: semanticLabel,
      child: GestureDetector(onTap: onTap, child: framed),
    );
  }
}
