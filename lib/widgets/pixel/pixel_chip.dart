import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';
import 'app_icon.dart';

/// Nhãn chọn nhanh (chip) kiểu pixel: viền đậm, cao tối thiểu 48dp.
class PixelChip extends StatelessWidget {
  final String label;
  final String? icon;
  final bool selected;
  final VoidCallback? onTap;
  final Color? accent;
  final bool showCheck;

  const PixelChip({
    super.key,
    required this.label,
    this.icon,
    this.selected = false,
    this.onTap,
    this.accent,
    this.showCheck = true,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final bg = selected ? (accent ?? palette.mint) : palette.surface;
    final fg = selected ? palette.onAccent : palette.ink;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: palette.lineStrong,
              width: selected ? 3 : 2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                AppIcon(name: icon!, size: 16, color: fg),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge
                    ?.copyWith(color: fg),
              ),
              if (selected && showCheck && onTap != null) ...[
                const SizedBox(width: 6),
                AppIcon(name: 'check', size: 16, color: palette.onAccent),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
