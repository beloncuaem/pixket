import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';
import 'app_icon.dart';
import 'pixel_panel.dart';

class PixelStatTile extends StatelessWidget {
  final String label;
  final String value;
  final String? glyph;

  const PixelStatTile({
    super.key,
    required this.label,
    required this.value,
    this.glyph,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return PixelPanel(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (glyph != null) ...[
                AppIcon(name: glyph!, size: 16, color: palette.mintInk),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall
                      ?.copyWith(color: palette.inkMuted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: Theme.of(context).textTheme.titleMedium),
          ),
        ],
      ),
    );
  }
}
