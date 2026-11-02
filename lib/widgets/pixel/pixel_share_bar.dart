import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';
import '../../core/utils/pixel_allocate.dart';
import 'app_icon.dart';

/// Một hàng tỉ trọng: badge icon + tên + thanh khối + số tiền + %.
class PixelShareBar extends StatelessWidget {
  const PixelShareBar({
    super.key,
    required this.label,
    required this.glyph,
    required this.value,
    required this.total,
    required this.valueText,
    this.cells = 14,
    this.useSpendRamp = true,
    this.reference,
  });

  final String label;
  final String glyph;
  final double value;
  final double total;
  final String valueText;
  final int cells;

  /// Tô theo bậc mức chi thay vì accent của danh mục.
  final bool useSpendRamp;

  /// Mốc tham chiếu (max của kỳ đang xem) để tính bậc mức chi.
  final double? reference;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    final t = useSpendRamp && reference != null && reference! > 0
        ? value / reference!
        : null;
    final accent = t == null
        ? palette.accentForCategory(label)
        : palette.rampFill(t);
    final filled = pixelFilledCells(total <= 0 ? 0 : value / total, cells);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: accent,
              border: Border.all(color: palette.lineStrong, width: 2),
            ),
            child: Center(
              child: AppIcon(name: glyph, size: 16, color: palette.onAccent),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.bodyMedium?.copyWith(color: palette.ink),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: cells * 7.0,
            child: Row(
              key: ValueKey('share-cells-$label'),
              children: [
                for (var i = 0; i < cells; i++)
                  Container(
                    width: 6,
                    height: 14,
                    margin: const EdgeInsets.only(right: 1),
                    color: i < filled ? accent : palette.surfaceAlt,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 92,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    valueText,
                    style: text.bodyMedium?.copyWith(
                      color: palette.ink,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  sharePercent(value, total),
                  style: text.labelSmall?.copyWith(color: palette.inkMuted),
                ),
                // Nhãn chữ đi kèm màu: mức chi không được chỉ mã hoá bằng màu.
                if (t != null)
                  Text(
                    palette.rampLabel(t),
                    style: text.labelSmall?.copyWith(color: palette.rampInk(t)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
