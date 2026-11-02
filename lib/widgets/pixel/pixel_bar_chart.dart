import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/pixel_allocate.dart';

/// Biểu đồ cột theo ngày, vẽ bằng khối pixel 10×10, chạm để hiện tooltip.
class PixelBarChart extends StatefulWidget {
  const PixelBarChart({
    super.key,
    required this.dates,
    required this.values,
    required this.valueTexts,
    this.rows = 8,
    this.maxBars = 31,
    this.barColor,
    this.axisLabels = 6,
    this.reference,
  });

  final List<DateTime> dates;
  final List<double> values;
  final List<String> valueTexts;
  final int rows;
  final int maxBars;
  final Color? barColor;
  final int axisLabels;

  /// Mốc tham chiếu (max của kỳ đang xem) để tô từng cột theo bậc mức chi.
  final double? reference;

  @override
  State<PixelBarChart> createState() => _PixelBarChartState();
}

class _PixelBarChartState extends State<PixelBarChart> {
  int? _selected;

  double? _t(double value) {
    final ref = widget.reference;
    return ref == null || ref <= 0 ? null : value / ref;
  }

  Color _barColor(Color fallback, double value) {
    final t = _t(value);
    return t == null ? fallback : context.palette.rampFill(t);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    final barColor = widget.barColor ?? palette.mint;

    final count = [
      widget.values.length,
      widget.dates.length,
      widget.valueTexts.length,
    ].reduce((a, b) => a < b ? a : b);
    if (count == 0) {
      return Container(
        height: 140,
        alignment: Alignment.center,
        child: Text(
          'Chưa có dữ liệu trong khoảng này.',
          textAlign: TextAlign.center,
          style: text.bodyMedium?.copyWith(color: palette.inkMuted),
        ),
      );
    }

    final skip = count > widget.maxBars ? count - widget.maxBars : 0;
    final dates = widget.dates.sublist(skip, count);
    final values = widget.values.sublist(skip, count);
    final texts = widget.valueTexts.sublist(skip, count);
    final maxValue = values.fold<double>(0, (a, b) => b > a ? b : a);
    final width = (dates.length * 14).clamp(0, 10000).toDouble();

    // Nằm trong guard index: `_selected` cũ có thể vượt biên sau khi đổi kỳ.
    String? tooltip;
    if (_selected != null && _selected! < texts.length) {
      final t = _t(values[_selected!]);
      tooltip =
          '${DateFormatter.formatDate(dates[_selected!])} • ${texts[_selected!]}'
          '${t == null ? '' : ' • ${palette.rampLabel(t)}'}';
    }

    return Semantics(
      container: true,
      label: pixelBarChartSemantics(dates, values, texts),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (tooltip != null)
            Container(
              key: const ValueKey('bar-tooltip'),
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: palette.surface,
                border: Border.all(color: palette.lineStrong, width: 2),
              ),
              child: Text(
                tooltip,
                style: text.labelLarge?.copyWith(color: palette.ink),
              ),
            ),
          SizedBox(
            height: 120,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: width,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (var i = 0; i < dates.length; i++)
                      _buildBar(
                        i,
                        dates[i],
                        values[i],
                        texts[i],
                        maxValue,
                        _barColor(barColor, values[i]),
                        palette,
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 18,
            child: Row(
              children: [
                for (final i in pickAxisIndices(
                  dates.length,
                  widget.axisLabels,
                ))
                  SizedBox(
                    width: 14,
                    child: Text(
                      '${dates[i].day}',
                      textAlign: TextAlign.center,
                      style: text.labelSmall?.copyWith(color: palette.inkMuted),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBar(
    int i,
    DateTime date,
    double value,
    String valueText,
    double maxValue,
    Color barColor,
    AppPalette palette,
  ) {
    final filled = maxValue <= 0
        ? 0
        : pixelFilledCells(value / maxValue, widget.rows);
    final isSelected = _selected == i;

    return GestureDetector(
      key: ValueKey('bar-$i'),
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _selected = isSelected ? null : i),
      child: Semantics(
        label: '${DateFormatter.formatDate(date)}: $valueText',
        child: SizedBox(
          width: 14,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              for (var r = widget.rows - 1; r >= 0; r--)
                Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.only(bottom: 1),
                  color: r < filled
                      ? (isSelected ? palette.mintInk : barColor)
                      : palette.surfaceAlt,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
