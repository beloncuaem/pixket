import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';

/// Khung pixel: nền surface, viền cứng, bóng lệch không blur.
class PixelPanel extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color? background;
  final Color? borderColor;
  final double borderWidth;
  final Offset shadowOffset;
  final BorderRadius? radius;

  const PixelPanel({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.background,
    this.borderColor,
    this.borderWidth = 2,
    this.shadowOffset = const Offset(3, 4),
    this.radius,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final border = radius ?? BorderRadius.circular(4);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: background ?? palette.surface,
        borderRadius: border,
        border: Border.all(
          color: borderColor ?? palette.lineStrong,
          width: borderWidth,
        ),
        boxShadow: [
          BoxShadow(
            color: palette.shadow.withValues(alpha: 0.9),
            offset: shadowOffset,
            blurRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: border,
          splashColor: palette.mint.withValues(alpha: 0.25),
          highlightColor: palette.mint.withValues(alpha: 0.15),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
