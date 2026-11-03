import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';
import '../../core/utils/pixel_allocate.dart';
import 'app_icon.dart';

/// Một hàng chú thích tỉ trọng: ô màu + glyph + tên + % + số tiền.
/// Thay cho thanh khối cũ: % và số tiền luôn đi kèm tên nên màu không bao giờ
/// là kênh thông tin duy nhất (WCAG 1.4.1).
class PixelShareRow extends StatelessWidget {
  const PixelShareRow({
    super.key,
    required this.label,
    required this.color,
    required this.value,
    required this.total,
    required this.valueText,
    this.glyph,
  });

  final String label;
  final Color color;
  final double value;
  final double total;
  final String valueText;

  /// Glyph tuỳ chọn, dùng cho hàng mức độ cần thiết.
  final String? glyph;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(width: 12, height: 12, color: color),
          const SizedBox(width: 8),
          if (glyph != null) ...[
            AppIcon(name: glyph!, size: 16, color: palette.inkMuted),
            const SizedBox(width: 6),
          ],
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.bodyMedium?.copyWith(color: palette.ink),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            sharePercent(value, total),
            style: text.labelSmall?.copyWith(color: palette.inkMuted),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 92,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                valueText,
                style: text.bodyMedium?.copyWith(
                  color: palette.ink,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
