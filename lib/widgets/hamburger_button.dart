import 'package:flutter/material.dart';

import '../core/theme/app_palette.dart';
import 'pixel/app_icon.dart';

class HamburgerButton extends StatelessWidget {
  final VoidCallback? onTap;
  final bool light;

  const HamburgerButton({super.key, required this.onTap, this.light = false});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return IconButton(
      tooltip: 'Mở menu',
      onPressed: onTap,
      style: IconButton.styleFrom(
        backgroundColor: light
            ? palette.feedBg.withValues(alpha: 0.5)
            : palette.surface,
        side: BorderSide(
          color: light ? palette.feedInk.withValues(alpha: 0.3) : palette.line,
        ),
        padding: const EdgeInsets.all(10),
      ),
      icon: AppIcon(
        name: 'menu',
        size: 32,
        color: light ? palette.feedInk : palette.ink,
      ),
    );
  }
}
