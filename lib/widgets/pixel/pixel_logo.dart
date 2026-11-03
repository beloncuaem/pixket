import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';

/// Cạnh lưới logo: bội số 8, làm tròn xuống từ [size].
int logoGridSize(double size) => math.max(8, (size ~/ 8) * 8);

/// Lưới "Lens Orbit": vành ống kính khía sáu rãnh, quỹ đạo nghiêng, vì sao bốn
/// cánh giữa ống kính, một hành tinh ngồi trên mép vành và các ô sao nền.
///
/// Mọi hằng số đo trên lưới chuẩn 24×24 rồi nhân theo `n / 24`, nên cùng một
/// mark ở mọi cỡ: header 24 dp, drawer 40 dp, icon launcher tới 192 px.
///
/// `.` trống · `k` vành ink · `s` quỹ đạo · `f` vì sao vàng · `m` hành tinh lục ·
/// `*` sao nền, chỉ theme tối vẽ.
List<String> buildLogoGrid(int n) {
  final scale = n / 24;
  final cells = List.generate(n, (_) => List<String>.filled(n, '.'));

  void set(int x, int y, String c) {
    if (x >= 0 && y >= 0 && x < n && y < n) cells[y][x] = c;
  }

  // Vùng chữ nhật trong lưới chuẩn, biên làm tròn theo tỉ lệ.
  void rect(double x0, double x1, double y0, double y1, String c) {
    final left = (x0 * scale).ceil(), right = (x1 * scale).floor();
    final top = (y0 * scale).ceil(), bottom = (y1 * scale).floor();
    for (var y = top; y <= bottom; y++) {
      for (var x = left; x <= right; x++) {
        set(x, y, c);
      }
    }
  }

  // Một ô sao: lưới nhỏ hơn 24 vẫn giữ tối thiểu một cell để không mất nét.
  void dot(double x, double y, String c) {
    final side = math.max(1, scale.round());
    final offset = ((side - 1) / 2).floor();
    final cx = (x * scale).round(), cy = (y * scale).round();
    for (var dy = 0; dy < side; dy++) {
      for (var dx = 0; dx < side; dx++) {
        set(cx - offset + dx, cy - offset + dy, c);
      }
    }
  }

  const ringX = 11.5, ringY = 11.5, ringRadius = 8.8;

  // 1. Vành ống kính: vòng dày 2,1 ô, khía sáu rãnh 60° lệch nhau 9°.
  for (var y = 0; y < n; y++) {
    for (var x = 0; x < n; x++) {
      final dx = x / scale - ringX, dy = y / scale - ringY;
      final rho = math.sqrt(dx * dx + dy * dy);
      if (rho > ringRadius || rho < ringRadius - 2.1) continue;
      final ang = ((math.atan2(dy, dx) * 180 / math.pi + 30) % 60 + 60) % 60;
      if (ang < 9) continue;
      set(x, y, 'k');
    }
  }

  // 2. Quỹ đạo nghiêng -26°, tâm thấp hơn tâm vành 0,7 ô nên vòng elip đeo
  // chéo qua ống kính; phần vẽ bị cắt trong vành nên không chạm mép ngoài.
  final tilt = -26 * math.pi / 180;
  final cosTilt = math.cos(tilt), sinTilt = math.sin(tilt);
  for (var y = 0; y < n; y++) {
    for (var x = 0; x < n; x++) {
      final dx = x / scale - ringX, dy = y / scale - ringY;
      if (math.sqrt(dx * dx + dy * dy) > ringRadius - 2.4) continue;
      final orbitY = y / scale - 12.2;
      final u = dx * cosTilt + orbitY * sinTilt;
      final v = -dx * sinTilt + orbitY * cosTilt;
      final ellipse = math.sqrt((u / 6.9) * (u / 6.9) + (v / 2.2) * (v / 2.2));
      if ((ellipse - 1).abs() > 0.11) continue;
      set(x, y, 's');
    }
  }

  // 3. Vì sao vàng bốn cánh ở giữa ống kính.
  rect(9, 14, 9, 10, 'f');
  rect(11, 12, 7, 12, 'f');

  // 4. Hành tinh lục trên mép vành, vẽ sau nên đè lên vành.
  for (var y = 0; y < n; y++) {
    for (var x = 0; x < n; x++) {
      final dx = x / scale - 5.4, dy = y / scale - 15.2;
      final rho = math.sqrt(dx * dx + dy * dy);
      if (rho > 2.6) continue;
      set(x, y, rho > 1.6 ? 'k' : 'm');
    }
  }

  // 5. Sao nền: vì sao bốn cánh góc trên-phải cộng mười chấm rời.
  rect(19, 21, 4, 4, '*');
  rect(20, 20, 3, 5, '*');
  for (final star in const [
    [4, 2],
    [1, 13],
    [21, 19],
    [7, 1],
    [2, 7],
    [23, 12],
    [12, 22],
    [2, 20],
    [18, 1],
    [22, 22],
  ]) {
    dot(star[0].toDouble(), star[1].toDouble(), '*');
  }

  return [for (final row in cells) row.join()];
}

/// Màu của một ô lưới; null là ô không vẽ (sao trên nền sáng, ký tự ngoài bảng).
Color? logoCellColor(String char, AppPalette palette, {required bool isDark}) =>
    switch (char) {
      'k' => palette.ink,
      's' => palette.sky,
      'f' => palette.butter,
      'm' => palette.mint,
      '*' => isDark ? palette.star : null,
      _ => null,
    };

/// Logo Pixket: ống kính pixel trên quỹ đạo, tinh tú quanh vành.
class PixelLogo extends StatelessWidget {
  const PixelLogo({super.key, this.size = 24});

  /// Cạnh logo; giá trị không phải bội số 8 bị làm tròn xuống.
  final double size;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final grid = logoGridSize(size);
    final rows = buildLogoGrid(grid);
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

  @override
  void paint(Canvas canvas, Size size) {
    if (rows.isEmpty || size.width <= 0 || size.height <= 0) return;
    final cell = size.width / rows.length;
    final cellHeight = size.height / rows.length;
    final paint = Paint()..isAntiAlias = false;

    for (var y = 0; y < rows.length; y++) {
      final row = rows[y];
      for (var x = 0; x < row.length; x++) {
        final color = logoCellColor(row[x], palette, isDark: isDark);
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
  bool shouldRepaint(covariant _LogoPainter old) =>
      old.rows != rows || old.palette != palette || old.isDark != isDark;
}
