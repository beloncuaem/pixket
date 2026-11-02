import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';

/// Iris pixel: 4 góc màn hình khép lại rồi mở ra bằng easing mượt (~260 ms),
/// che kín đúng lúc chuyển cảnh sau khi chụp. Thay cho vệt cầu vồng cũ.
class PixelIris {
  PixelIris._();

  static Future<void> play(
    BuildContext context, {
    required VoidCallback onCovered,
  }) {
    final still = MediaQuery.of(context).disableAnimations;
    final overlay = Overlay.of(context, rootOverlay: true);
    late final OverlayEntry entry;
    var covered = false;
    entry = OverlayEntry(
      builder: (_) => _IrisOverlay(
        still: still,
        onCovered: () {
          if (covered) return;
          covered = true;
          onCovered();
        },
        onDone: () => entry.remove(),
      ),
    );
    overlay.insert(entry);
    return Future<void>.value();
  }
}

class _IrisOverlay extends StatefulWidget {
  const _IrisOverlay({
    required this.still,
    required this.onCovered,
    required this.onDone,
  });

  final bool still;
  final VoidCallback onCovered;
  final VoidCallback onDone;

  @override
  State<_IrisOverlay> createState() => _IrisOverlayState();
}

class _IrisOverlayState extends State<_IrisOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _run = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: widget.still ? 1 : 260),
  );
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _run.addListener(_tick);
    _run.addStatusListener((status) {
      if (status == AnimationStatus.completed && !_done) {
        _done = true;
        // Gọi lại để form luôn mở kể cả khi thiếu tick sát mốc 0.5.
        widget.onCovered();
        widget.onDone();
      }
    });
    _run.forward();
  }

  void _tick() {
    if (_run.value >= 0.5) widget.onCovered();
  }

  @override
  void dispose() {
    _run.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          key: const ValueKey('pixel-iris'),
          painter: _IrisPainter(context.palette.shadow, _run),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _IrisPainter extends CustomPainter {
  _IrisPainter(this.color, this.run) : super(repaint: run);

  final Color color;
  final Animation<double> run;

  /// 0..1: nửa đầu khép (easeIn), nửa sau mở (easeOut).
  double _coverage(double t) {
    if (t < 0.5) {
      final x = t / 0.5;
      return Curves.easeIn.transform(x);
    }
    final x = (t - 0.5) / 0.5;
    return 1 - Curves.easeOut.transform(x);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final c = _coverage(run.value);
    if (c <= 0) return;
    final paint = Paint()
      ..isAntiAlias = false
      ..color = color;
    final side = c * (size.width + size.height) / 2;
    // Mỗi góc là khối vuông + hai bậc thang để ra silhouette pixel.
    for (final corner in const [
      (0.0, 0.0, 1.0, 1.0),
      (1.0, 0.0, -1.0, 1.0),
      (0.0, 1.0, 1.0, -1.0),
      (1.0, 1.0, -1.0, -1.0),
    ]) {
      final ox = corner.$1 * size.width;
      final oy = corner.$2 * size.height;
      final dx = corner.$3;
      final dy = corner.$4;
      canvas.drawRect(
        Rect.fromLTWH(
          dx > 0 ? ox : ox - side,
          dy > 0 ? oy : oy - side,
          side,
          side,
        ),
        paint,
      );
      final step = side * 0.55;
      canvas.drawRect(
        Rect.fromLTWH(
          dx > 0 ? ox + side : ox - side - step,
          dy > 0 ? oy : oy - step,
          step,
          step,
        ),
        paint,
      );
      canvas.drawRect(
        Rect.fromLTWH(
          dx > 0 ? ox : ox - step,
          dy > 0 ? oy + side : oy - side - step,
          step,
          step,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _IrisPainter old) => old.run.value != run.value;
}
