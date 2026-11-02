import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';
import '../../core/utils/pixel_allocate.dart';
import 'app_icon.dart';

/// 4 khối mức độ xếp theo tỉ lệ trong [cells] ô, kèm legend chữ + số tiền.
class PixelStackedShare extends StatelessWidget {
  const PixelStackedShare({
    super.key,
    required this.labels,
    required this.glyphs,
    required this.values,
    this.colors = const [],
    required this.valueTexts,
    this.cells = 24,
    this.reference,
  });

  final List<String> labels;
  final List<String> glyphs;
  final List<double> values;
  final List<Color> colors;
  final List<String> valueTexts;
  final int cells;

  /// Mốc tham chiếu (max của kỳ đang xem); khi có thì [colors] bị bỏ qua.
  final double? reference;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    final allocation = allocateCells(values, cells);
    final total = values.fold<double>(0, (a, b) => a + (b > 0 ? b : 0));

    double? tOf(int i) =>
        reference != null && reference! > 0 && i < values.length
        ? values[i] / reference!
        : null;

    Color colorOf(int i) {
      final t = tOf(i);
      if (t != null) return palette.rampFill(t);
      return i < colors.length ? colors[i] : palette.surfaceAlt;
    }

    Widget rampTag(int i) {
      final t = tOf(i);
      if (t == null) return const SizedBox.shrink();
      return Text(
        palette.rampLabel(t),
        style: text.labelSmall?.copyWith(color: palette.rampInk(t)),
      );
    }

    final bars = <Widget>[];
    for (var i = 0; i < allocation.length; i++) {
      for (var k = 0; k < allocation[i]; k++) {
        bars.add(
          Container(
            width: 8,
            height: 26,
            margin: const EdgeInsets.only(right: 1),
            color: colorOf(i),
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Container(
            key: const ValueKey('stacked-cells'),
            height: 30,
            decoration: BoxDecoration(
              border: Border.all(color: palette.lineStrong, width: 2),
            ),
            padding: const EdgeInsets.all(2),
            child: Row(mainAxisSize: MainAxisSize.min, children: bars),
          ),
        ),
        for (var i = 0; i < labels.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Container(width: 12, height: 12, color: colorOf(i)),
                const SizedBox(width: 8),
                AppIcon(
                  name: i < glyphs.length ? glyphs[i] : 'label',
                  size: 16,
                  color: palette.inkMuted,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    labels[i],
                    style: text.bodyMedium?.copyWith(color: palette.ink),
                  ),
                ),
                Text(
                  i < valueTexts.length ? valueTexts[i] : '',
                  style: text.bodyMedium?.copyWith(
                    color: palette.ink,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 44,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        sharePercent(i < values.length ? values[i] : 0, total),
                        textAlign: TextAlign.end,
                        style: text.labelSmall?.copyWith(
                          color: palette.inkMuted,
                        ),
                      ),
                      rampTag(i),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
