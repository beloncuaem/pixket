import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';
import 'app_icon.dart';

class PixelBadge extends StatelessWidget {
  final String glyph;
  final String label;
  final Color? accent;
  final Color? ink;
  final double iconSize;

  const PixelBadge({
    super.key,
    required this.glyph,
    required this.label,
    this.accent,
    this.ink,
    this.iconSize = 16,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final tone = accent ?? palette.mint;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: tone,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: palette.lineStrong, width: 2),
          ),
          child: SizedBox(
            width: 32,
            height: 32,
            child: Center(
              child: AppIcon(
                name: glyph,
                size: iconSize,
                color: palette.onAccent,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(color: ink ?? palette.ink),
        ),
      ],
    );
  }
}
