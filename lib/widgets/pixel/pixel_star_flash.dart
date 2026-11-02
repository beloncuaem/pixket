import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';

class _FlashStar {
  const _FlashStar(this.dx, this.dy, this.accent);

  final double dx, dy;
  final int accent;
}

/// 5 sao pixel lóe rồi tan trong ~350 ms tại vị trí lưu; seed cố định.
final List<_FlashStar> _stars = () {
  final rng = math.Random(20261103);
  return List<_FlashStar>.generate(
    5,
    (i) => _FlashStar(
      (rng.nextDouble() - 0.5) * 96,
      (rng.nextDouble() - 0.5) * 72,
      i % 6,
    ),
  );
}();

/// Feedback khi lưu khoản chi thành công (thay pháo giấy cũ).
class PixelStarFlash {
  PixelStarFlash._();

  static void burst(BuildContext context, {Offset? at}) {
    final overlay = Overlay.of(context, rootOverlay: true);
    final still = MediaQuery.of(context).disableAnimations;
    final center =
        at ??
        Offset(
          MediaQuery.sizeOf(context).width / 2,
          MediaQuery.sizeOf(context).height * 0.4,
        );
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _FlashOverlay(
        center: center,
        still: still,
        onDone: () => entry.remove(),
      ),
    );
    overlay.insert(entry);
  }
}

class _FlashOverlay extends StatefulWidget {
  const _FlashOverlay({
    required this.center,
    required this.still,
    required this.onDone,
  });

  final Offset center;
  final bool still;
  final VoidCallback onDone;

  @override
  State<_FlashOverlay> createState() => _FlashOverlayState();
}

class _FlashOverlayState extends State<_FlashOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _run = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: widget.still ? 120 : 350),
  );
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _run.addStatusListener((status) {
      if (status == AnimationStatus.completed && !_done) {
        _done = true;
        widget.onDone();
      }
    });
    _run.forward();
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
          key: const ValueKey('pixel-star-flash'),
          painter: _FlashPainter(
            context.palette.accents,
            widget.center,
            widget.still,
            _run,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _FlashPainter extends CustomPainter {
  _FlashPainter(this.accents, this.center, this.still, this.run)
    : super(repaint: run);

  final List<Color> accents;
  final Offset center;
  final bool still;
  final Animation<double> run;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0 || accents.isEmpty) return;
    // Nở nhanh rồi tan chậm: opacity đỉnh ở 30% lượt chạy.
    final t = still ? 0.3 : run.value;
    final grow = Curves.easeOut.transform(math.min(1.0, t / 0.3));
    final fade = t <= 0.3
        ? 1.0
        : 1.0 - Curves.easeIn.transform((t - 0.3) / 0.7);
    if (fade <= 0) return;
    final paint = Paint()..isAntiAlias = false;

    for (final star in _stars) {
      final arm = 2 + 4 * grow;
      final cx = center.dx + star.dx * (0.6 + 0.4 * grow);
      final cy = center.dy + star.dy * (0.6 + 0.4 * grow);
      paint.color = accents[star.accent % accents.length].withValues(
        alpha: fade,
      );
      canvas.drawRect(Rect.fromLTWH(cx - arm, cy - 2, arm * 2, 4), paint);
      canvas.drawRect(Rect.fromLTWH(cx - 2, cy - arm, 4, arm * 2), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _FlashPainter old) => old.run.value != run.value;
}
