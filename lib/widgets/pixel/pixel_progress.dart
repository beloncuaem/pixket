import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';

/// Thanh tiến độ gồm các khối pixel rời nhau.
class PixelProgress extends StatelessWidget {
  final double value;
  final int segments;
  final Color? fillColor;
  final Color? emptyColor;
  final bool showLabel;

  const PixelProgress({
    super.key,
    required this.value,
    this.segments = 10,
    this.fillColor,
    this.emptyColor,
    this.showLabel = false,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final clamped = value.isNaN ? 0.0 : value.clamp(0.0, 1.0);
    final filled = (clamped * segments).round().clamp(0, segments);

    return Semantics(
      value: '${(clamped * 100).round()}%',
      label: showLabel ? 'Tiến độ' : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              for (var i = 0; i < segments; i++)
                Expanded(
                  child: Container(
                    height: 14,
                    margin: EdgeInsets.only(right: i == segments - 1 ? 0 : 3),
                    color: i < filled
                        ? (fillColor ?? palette.mintStrong)
                        : (emptyColor ?? palette.surfaceAlt),
                  ),
                ),
            ],
          ),
          if (showLabel) ...[
            const SizedBox(height: 6),
            Text(
              '${(clamped * 100).round()}%',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.end,
            ),
          ],
        ],
      ),
    );
  }
}
