import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';
import '../../core/utils/pixel_allocate.dart';

/// Một lát của biểu đồ tròn: [value] quyết định góc, [color] do nơi gọi chọn
/// (accent ổn định theo danh mục) để lát cắt và chú thích luôn cùng màu.
class PixelPieSlice {
  const PixelPieSlice({
    required this.label,
    required this.value,
    required this.valueText,
    required this.color,
  });

  final String label;
  final double value;
  final String valueText;
  final Color color;
}

/// Tóm tắt chữ cho screen reader, mỗi lát một dòng: 'Ăn uống 67% 500.000 đ'.
String pixelPieSemantics(List<PixelPieSlice> slices, double total) => [
  for (final slice in slices)
    if (slice.value > 0)
      '${slice.label} ${sharePercent(slice.value, total)} ${slice.valueText}',
].join('\n');

/// Biểu đồ tròn thật: lát cắt vẽ bằng cung tròn có antialias nên mép tròn
/// mượt, không phải khối vuông xếp gần đúng. Lát 0 đồng không vẽ.
class PixelPieChart extends StatelessWidget {
  const PixelPieChart({super.key, required this.slices, this.size = 132});

  final List<PixelPieSlice> slices;
  final double size;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final total = slices.fold<double>(
      0,
      (sum, slice) => sum + (slice.value > 0 ? slice.value : 0),
    );

    return Semantics(
      container: true,
      label: pixelPieSemantics(slices, total),
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          key: const ValueKey('pixel-pie'),
          painter: _PiePainter(
            slices: slices,
            total: total,
            ring: palette.lineStrong,
            seam: palette.surface,
          ),
        ),
      ),
    );
  }
}

class _PiePainter extends CustomPainter {
  _PiePainter({
    required this.slices,
    required this.total,
    required this.ring,
    required this.seam,
  });

  final List<PixelPieSlice> slices;
  final double total;
  final Color ring;
  final Color seam;

  static const double _ringWidth = 4;
  static const double _seamWidth = 2;

  /// Bắt đầu ở 12 giờ rồi quay thuận chiều kim đồng hồ.
  static const double _startAngle = -math.pi / 2;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0 || total <= 0) return;
    // Bán kính lấy theo cạnh ngắn: ô vẽ có thể bị kéo ngang (scroll view ép
    // chặt trục ngang) mà lát cắt vẫn phải là hình tròn thật.
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - _ringWidth / 2;
    if (radius <= 0) return;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final fill = Paint()..isAntiAlias = true;
    final live = slices.where((slice) => slice.value > 0).toList();
    var angle = _startAngle;
    for (final slice in live) {
      final sweep = slice.value / total * 2 * math.pi;
      fill.color = slice.color;
      canvas.drawArc(rect, angle, sweep, true, fill);
      angle += sweep;
    }

    // Kẻ hở giữa hai lát tô lại màu nền panel: màu không được dính vào nhau.
    if (live.length > 1) {
      final gap = Paint()
        ..isAntiAlias = true
        ..style = PaintingStyle.stroke
        ..strokeWidth = _seamWidth
        ..color = seam;
      var seamAngle = _startAngle;
      for (final slice in live) {
        final end = Offset(
          center.dx + radius * math.cos(seamAngle),
          center.dy + radius * math.sin(seamAngle),
        );
        canvas.drawLine(center, end, gap);
        seamAngle += slice.value / total * 2 * math.pi;
      }
    }

    final outline = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeWidth = _ringWidth
      ..color = ring;
    canvas.drawCircle(center, radius, outline);
  }

  @override
  bool shouldRepaint(covariant _PiePainter old) =>
      old.total != total ||
      old.ring != ring ||
      old.seam != seam ||
      old.slices.length != slices.length;
}
