import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';
import '../../core/utils/storage_paths.dart';
import '../../data/models/expense.dart';
import 'app_icon.dart';

enum ReceiptImageSource { signedUrl, localFile, none }

typedef ReceiptImageTarget = ({
  ReceiptImageSource source,
  String? url,
  String? localPath,
  String? cacheKey,
});

/// Chọn nguồn ảnh hiển thị theo độ tin cậy: signed URL > tệp tạm trên máy.
/// URL public legacy (bắt đầu bằng http) không còn hợp lệ nên bị loại.
ReceiptImageTarget resolveReceiptImage({
  String? imagePath,
  String? displayImageUrl,
}) {
  if (displayImageUrl != null && displayImageUrl.isNotEmpty) {
    return (
      source: ReceiptImageSource.signedUrl,
      url: displayImageUrl,
      localPath: null,
      cacheKey: storagePathOf(imagePath),
    );
  }
  final path = imagePath;
  if (path != null && path.isNotEmpty && !path.startsWith('http')) {
    return (
      source: ReceiptImageSource.localFile,
      url: null,
      localPath: path,
      cacheKey: null,
    );
  }
  return (
    source: ReceiptImageSource.none,
    url: null,
    localPath: null,
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
    this.localPath,
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
    VoidCallback? onTap,
  }) {
    final target = resolveReceiptImage(
      imagePath: expense.imagePath,
      displayImageUrl: expense.displayImageUrl,
    );
    return PixelReceiptImage(
      localPath: target.localPath,
      displayUrl: target.url,
      cacheKey: target.cacheKey,
      width: width,
      height: height,
      fit: fit,
      onTap: onTap,
      semanticLabel:
          semanticLabel ??
          (expense.caption.isEmpty
              ? 'Ảnh khoản chi ${expense.amount.toInt()}'
              : 'Ảnh khoản chi: ${expense.caption}'),
    );
  }

  final String? localPath;
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

    Widget image;
    if (displayUrl != null) {
      image = CachedNetworkImage(
        imageUrl: displayUrl!,
        cacheKey: cacheKey,
        fit: fit,
        width: width,
        height: height,
        placeholder: (_, __) => ColoredBox(
          color: palette.surfaceAlt,
          child: Center(
            child: AppIcon(
              name: 'dotsThreeOutline',
              size: 16,
              color: palette.inkMuted,
            ),
          ),
        ),
        errorWidget: (_, __, ___) => receiptPlaceholder(),
      );
    } else if (localPath != null) {
      image = Image.file(
        File(localPath!),
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (_, __, ___) => receiptPlaceholder(),
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
