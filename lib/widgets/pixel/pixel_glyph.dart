import 'package:flutter/material.dart';

import '../../core/icons/pixel_glyph_data.dart';
import '../../core/theme/app_palette.dart';

/// Vẽ một glyph pixel 16x16. Size nên là bội số 16 để sắc nét.
class PixelGlyph extends StatelessWidget {
  final String name;
  final double size;
  final Color? color;
  final Color? secondary;

  const PixelGlyph({
    super.key,
    required this.name,
    this.size = 32,
    this.color,
    this.secondary,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final rows = PixelGlyphData.rowsOf(name) ??
        PixelGlyphData.rowsOf(PixelGlyphData.fallbackKey)!;
    final main = color ?? palette.ink;
    final sub = secondary ?? main.withValues(alpha: 0.55);

    return SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _GlyphPainter(rows, main, sub)),
    );
  }
}

class _GlyphPainter extends CustomPainter {
  final List<String> rows;
  final Color main;
  final Color secondary;

  _GlyphPainter(this.rows, this.main, this.secondary);

  @override
  void paint(Canvas canvas, Size size) {
    if (rows.isEmpty || size.width <= 0 || size.height <= 0) return;
    final cell = size.width / pixelGlyphGrid;
    final cellHeight = size.height / pixelGlyphGrid;
    final paint = Paint()..isAntiAlias = false;

    for (var y = 0; y < pixelGlyphGrid; y++) {
      final row = y < rows.length ? rows[y] : '.' * pixelGlyphGrid;
      for (var x = 0; x < pixelGlyphGrid; x++) {
        final char = x < row.length ? row[x] : '.';
        if (char == '.') continue;
        paint.color = char == '#' ? main : secondary;
        // +0.2 là dung sai chống kẻ hở giữa hai ô liền kề; không đổi thành
        // anti-alias.
        canvas.drawRect(
          Rect.fromLTWH(x * cell, y * cellHeight, cell + 0.2, cellHeight + 0.2),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _GlyphPainter old) =>
      old.main != main || old.secondary != secondary || old.rows != rows;
}
