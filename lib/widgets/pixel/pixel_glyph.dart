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
    final rows =
        PixelGlyphData.rowsOf(name) ??
        PixelGlyphData.rowsOf(PixelGlyphData.fallbackKey)!;
    final main = color ?? palette.ink;
    final sub = secondary ?? main.withValues(alpha: 0.55);

    return SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _GlyphPainter(rows, main, sub, palette)),
    );
  }
}

class _GlyphPainter extends CustomPainter {
  final List<String> rows;
  final Color main;
  final Color secondary;
  final AppPalette palette;

  _GlyphPainter(this.rows, this.main, this.secondary, this.palette);

  /// Highlight cố định màu sáng để đọc được trên cả nền kem lẫn nền vũ trụ.
  static const Color _highlight = Color(0xFFF7FBFF);

  Color? _colorOf(String char) => switch (char) {
    '#' => main,
    '+' => secondary,
    'k' => palette.shadow,
    'w' => _highlight,
    '1' => palette.accents[0],
    '2' => palette.accents[1],
    '3' => palette.accents[2],
    '4' => palette.accents[3],
    '5' => palette.accents[4],
    '6' => palette.accents[5],
    _ => null,
  };

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
        final color = _colorOf(char);
        if (color == null) continue;
        paint.color = color;
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
      old.main != main ||
      old.secondary != secondary ||
      old.rows != rows ||
      old.palette != palette;
}
