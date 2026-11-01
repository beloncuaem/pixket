import 'package:flutter/material.dart';

import '../../core/icons/pixel_glyph_data.dart';
import '../../core/theme/app_palette.dart';
import 'pixel_glyph.dart';

/// Icon pixel kèm nhãn ngữ nghĩa.
///
/// Glyph trang trí (label đã có trong text) bị loại khỏi semantics; glyph
/// truyền tải hành động thì cần [semanticLabel] để screen reader không mất
/// thông tin khi không còn icon hệ thống.
class AppIcon extends StatelessWidget {
  final String name;
  final double size;
  final Color? color;
  final Color? secondary;
  final String? semanticLabel;

  const AppIcon({
    super.key,
    required this.name,
    this.size = 32,
    this.color,
    this.secondary,
    this.semanticLabel,
  });

  String get _resolvedName =>
      PixelGlyphData.rowsOf(name) != null ? name : PixelGlyphData.fallbackKey;

  @override
  Widget build(BuildContext context) {
    final glyph = PixelGlyph(
      name: _resolvedName,
      size: size,
      color: color,
      secondary: secondary,
    );
    final label = semanticLabel;
    if (label == null) return ExcludeSemantics(child: glyph);
    return Semantics(label: label, child: glyph);
  }
}

/// Nút chỉ có icon, vùng chạm 48×48 dp, viền cứng theo ngôn ngữ pixel.
///
/// `tooltip` đồng thời là nhãn ngữ nghĩa nên screen reader vẫn đọc được hành
/// động khi không còn icon hệ thống.
class PixelIconButton extends StatelessWidget {
  const PixelIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.iconSize = 32,
    this.size = 48,
    this.background,
    this.borderColor,
    this.iconColor,
  });

  final String icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final double iconSize;
  final double size;
  final Color? background;
  final Color? borderColor;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final enabled = onPressed != null;
    return SizedBox(
      width: size,
      height: size,
      child: IconButton(
        onPressed: onPressed,
        tooltip: tooltip,
        padding: EdgeInsets.zero,
        style: IconButton.styleFrom(
          backgroundColor: background ?? palette.surface,
          side: BorderSide(
            color: enabled ? (borderColor ?? palette.lineStrong) : palette.line,
            width: 2,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        icon: AppIcon(
          name: icon,
          size: iconSize,
          color: enabled ? (iconColor ?? palette.ink) : palette.inkMuted,
        ),
      ),
    );
  }
}
