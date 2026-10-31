import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';
import 'app_icon.dart';

enum PixelButtonVariant { primary, secondary, ghost, danger }

/// Nút pixel cao 48dp, bóng cứng, lún xuống khi đang chạm.
class PixelButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final PixelButtonVariant variant;
  final String? icon;
  final bool expanded;
  final double? minWidth;
  final bool isLoading;

  const PixelButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = PixelButtonVariant.primary,
    this.icon,
    this.expanded = false,
    this.minWidth,
    this.isLoading = false,
  });

  @override
  State<PixelButton> createState() => _PixelButtonState();
}

class _PixelButtonState extends State<PixelButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final enabled = widget.onPressed != null && !widget.isLoading;

    final colors = switch (widget.variant) {
      PixelButtonVariant.primary => (
        bg: enabled ? palette.mint : palette.surfaceAlt,
        fg: enabled ? palette.onAccent : palette.inkMuted,
        border: enabled ? palette.lineStrong : palette.line,
      ),
      PixelButtonVariant.secondary => (
        bg: enabled ? palette.surface : palette.surfaceAlt,
        fg: enabled ? palette.ink : palette.inkMuted,
        border: enabled ? palette.lineStrong : palette.line,
      ),
      PixelButtonVariant.ghost => (
        bg: Colors.transparent,
        fg: enabled ? palette.mintInk : palette.inkMuted,
        border: Colors.transparent,
      ),
      PixelButtonVariant.danger => (
        bg: enabled ? palette.rose : palette.surfaceAlt,
        fg: enabled ? palette.onAccent : palette.inkMuted,
        border: enabled ? palette.lineStrong : palette.line,
      ),
    };

    final glyph = widget.isLoading ? 'dotsThreeOutline' : widget.icon;

    Widget content = Row(
      mainAxisSize: widget.expanded ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (glyph != null) ...[
          AppIcon(name: glyph, size: 16, color: colors.fg),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Text(
            widget.label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: colors.fg,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );

    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      child: GestureDetector(
        onTap: enabled ? widget.onPressed : null,
        onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
        behavior: HitTestBehavior.opaque,
        child: AnimatedSlide(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          offset: _pressed ? const Offset(0.03, 0.05) : Offset.zero,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colors.bg,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: colors.border, width: 2),
              boxShadow:
                  widget.variant == PixelButtonVariant.ghost || !enabled
                  ? null
                  : [
                    BoxShadow(
                      color: palette.shadow.withValues(alpha: 0.9),
                      offset: const Offset(2, 3),
                      blurRadius: 0,
                    ),
                  ],
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth:
                    widget.minWidth ??
                    (widget.variant == PixelButtonVariant.ghost ? 48 : 64),
                minHeight: 48,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: content,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
