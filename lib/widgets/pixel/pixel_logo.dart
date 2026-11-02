import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';

/// Cạnh lưới logo: bội số 8, làm tròn xuống từ [size].
int logoGridSize(double size) => math.max(8, (size ~/ 8) * 8);

/// Sinh lưới logo máy ảnh theo spec §3, dùng chung cho brand (24), glyph nhỏ
/// (16) và icon launcher. Trả về `n` chuỗi, mỗi chuỗi `n` ký tự:
/// `.` trống · `k` ink · `b` surface · `f` flash · `g` highlight · `h` đồng tử ·
/// `1`..`6` sáu cung iris.
List<String> buildLogoGrid(int n, {bool mono = false, bool simple = false}) {
  final cells = List.generate(n, (_) => List<String>.filled(n, '.'));
  int at(double ratio) => (ratio * n).round();

  final x0 = at(0.12), x1 = at(0.88);
  final y0 = at(0.33), y1 = at(0.75);

  // 1. Thân máy: chữ nhật đặc, ô nào có hàng xóm ngoài mask thì thành viền.
  for (var y = y0; y < y1; y++) {
    for (var x = x0; x < x1; x++) {
      final border = x == x0 || x == x1 - 1 || y == y0 || y == y1 - 1;
      cells[y][x] = border ? 'k' : 'b';
    }
  }

  final bumpHeight = math.max(1, at(0.08));

  if (!simple) {
    // 2. Gờ nhả chụp, nằm ngay trên thân.
    for (var y = y0 - bumpHeight; y < y0; y++) {
      for (var x = at(0.76); x < at(0.88); x++) {
        if (y >= 0 && x >= 0 && x < n) cells[y][x] = 'f';
      }
    }

    // 3. Ô ngắm ở góc trên-trái thân máy, nằm trong ruột nên không phá viền.
    final vx0 = x0 + 2;
    final vx1 = vx0 + math.max(1, at(0.17));
    for (var y = y0 + 1; y < y0 + 1 + bumpHeight && y < y1 - 1; y++) {
      for (var x = vx0; x < vx1 && x < x1 - 1; x++) {
        cells[y][x] = 'h';
      }
    }
  }

  // 4. Ống kính: vành ink, sáu cung 60° lệch swirl 15°, đồng tử lục giác.
  final cx = (x0 + x1 - 1) / 2;
  final cy = (y0 + y1 - 1) / 2 + 0.01 * n;
  // Spec §3 chốt R = 26%·n nhưng thân máy chỉ cao 42%·n, nên đĩa kính 52%·n
  // tràn ra ngoài thân một hàng ở cả trên lẫn dưới. Lấy R nội tiếp trong thân
  // thì đúng ở mọi n: hàng trên/dưới của viền luôn cách tâm xa hơn R.
  final radius = (y1 - y0) / 2 - 0.5;
  final pupilRadius = 0.34 * radius;
  for (var y = 0; y < n; y++) {
    for (var x = 0; x < n; x++) {
      final dx = x - cx, dy = y - cy;
      final rho = math.sqrt(dx * dx + dy * dy);
      if (rho > radius) continue;
      if (rho > radius - 1) {
        cells[y][x] = 'k';
        continue;
      }
      final sweep = (math.atan2(dy, dx) * 180 / math.pi + 15) % 360;
      // Bán kính lục giác theo hướng: a / cos(góc lệch trong cung 60°).
      final local = (sweep % 60) - 30;
      final hexRadius = pupilRadius / math.cos(local * math.pi / 180);
      cells[y][x] = rho < hexRadius ? 'h' : '${sweep ~/ 60 + 1}';
    }
  }

  // 5. Highlight 2×2 nằm trên cung màu, không đè lên viền hay đồng tử.
  final hx = (cx - 0.52 * radius).round();
  final hy = (cy - 0.62 * radius).round();
  for (var y = hy; y < hy + 2; y++) {
    for (var x = hx; x < hx + 2; x++) {
      if (y < 0 || x < 0 || y >= n || x >= n) continue;
      if ('123456'.contains(cells[y][x])) cells[y][x] = 'g';
    }
  }

  // 6. Bản mono: chỉ còn ink. Ruột thân và highlight thành rỗng để silhouette
  // không đặc kín — thân máy là viền, ống kính là khối ink đặc.
  if (mono) {
    for (var y = 0; y < n; y++) {
      for (var x = 0; x < n; x++) {
        cells[y][x] = switch (cells[y][x]) {
          '.' || 'b' || 'g' => '.',
          _ => 'k',
        };
      }
    }
  }

  return [for (final row in cells) row.join()];
}

/// Logo Pixket: thân máy ảnh pixel + ống kính iris sáu cung màu Nyan Cat.
class PixelLogo extends StatelessWidget {
  const PixelLogo({
    super.key,
    this.size = 24,
    this.mono = false,
    this.simple = false,
  });

  /// Cạnh logo; giá trị không phải bội số 8 bị làm tròn xuống.
  final double size;

  /// Chỉ dùng ink, cho launcher / drawer / favicon.
  final bool mono;

  /// Bỏ gờ nhả chụp và ô ngắm, chỉ còn thân + ống kính.
  final bool simple;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final grid = logoGridSize(size);
    final rows = buildLogoGrid(grid, mono: mono, simple: simple);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox.square(
      dimension: grid.toDouble(),
      child: CustomPaint(painter: _LogoPainter(rows, palette, isDark)),
    );
  }
}

class _LogoPainter extends CustomPainter {
  final List<String> rows;
  final AppPalette palette;
  final bool isDark;

  _LogoPainter(this.rows, this.palette, this.isDark);

  Color _colorOf(String char) => switch (char) {
    'k' || 'h' => palette.ink,
    'b' => palette.surface,
    'f' => palette.butter,
    'g' => isDark ? palette.star : palette.surface,
    '1' => palette.accents[0],
    '2' => palette.accents[1],
    '3' => palette.accents[2],
    '4' => palette.accents[3],
    '5' => palette.accents[4],
    '6' => palette.accents[5],
    _ => Colors.transparent,
  };

  @override
  void paint(Canvas canvas, Size size) {
    if (rows.isEmpty || size.width <= 0 || size.height <= 0) return;
    final cell = size.width / rows.length;
    final cellHeight = size.height / rows.length;
    final paint = Paint()..isAntiAlias = false;

    for (var y = 0; y < rows.length; y++) {
      final row = rows[y];
      for (var x = 0; x < row.length; x++) {
        final char = row[x];
        if (char == '.') continue;
        paint.color = _colorOf(char);
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
  bool shouldRepaint(covariant _LogoPainter old) =>
      old.rows != rows || old.palette != palette || old.isDark != isDark;
}
