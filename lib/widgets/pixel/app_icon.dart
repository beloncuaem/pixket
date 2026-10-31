import 'package:flutter/material.dart';

import '../../core/icons/pixel_glyph_data.dart';
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
