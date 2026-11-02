import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_palette.dart';
import '../../providers/app_settings_provider.dart';

/// Vị trí tâm dải theo % chiều rộng, 8 bậc × 82 ms; bậc 4-5 (giá trị 0) che kín.
const List<double> _positions = [-150, -95, -40, 0, 0, 40, 95, 150];

/// Vệt cầu vồng quét ngang màn hình ngay sau khi chụp, che kín đúng lúc chuyển cảnh.
class RainbowSweep {
  RainbowSweep._();

  static Future<void> play(
    BuildContext context, {
    required VoidCallback onCovered,
  }) {
    final enabled = ProviderScope.containerOf(
      context,
    ).read(effectsProvider).captureSweep;
    if (!enabled) {
      onCovered();
      return Future<void>.value();
    }
    final still = MediaQuery.of(context).disableAnimations;
    final overlay = Overlay.of(context, rootOverlay: true);
    late final OverlayEntry entry;
    var covered = false;
    entry = OverlayEntry(
      builder: (_) => _SweepOverlay(
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

class _SweepOverlay extends StatefulWidget {
  const _SweepOverlay({
    required this.still,
    required this.onCovered,
    required this.onDone,
  });

  final bool still;
  final VoidCallback onCovered;
  final VoidCallback onDone;

  @override
  State<_SweepOverlay> createState() => _SweepOverlayState();
}

class _SweepOverlayState extends State<_SweepOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _run = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: widget.still ? 220 : 660),
  );
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _run.addListener(_tick);
    _run.addStatusListener((status) {
      if (status == AnimationStatus.completed && !_done) {
        _done = true;
        widget.onDone();
      }
    });
    _run.forward();
  }

  void _tick() {
    final steps = widget.still ? 2 : _positions.length;
    final step = (_run.value * steps).floor().clamp(0, steps - 1);
    // still: bậc 0 đã che kín; động: bậc 3 (đầu cửa sổ 165 ms che kín).
    if (step >= (widget.still ? 0 : 3)) widget.onCovered();
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
          key: const ValueKey('rainbow-sweep'),
          painter: _SweepPainter(
            context.palette.accents,
            widget.still ? const <double>[0, 150] : _positions,
            _run,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _SweepPainter extends CustomPainter {
  _SweepPainter(this.accents, this.positions, this.run) : super(repaint: run);

  final List<Color> accents;
  final List<double> positions;
  final Animation<double> run;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0 || accents.isEmpty) return;
    final step = (run.value * positions.length).floor().clamp(
      0,
      positions.length - 1,
    );
    final bandWidth = size.width * 1.7;
    final x0 = (positions[step] / 100) * size.width - bandWidth * 0.35;
    final column = bandWidth / accents.length;
    final paint = Paint()..isAntiAlias = false;

    canvas.save();
    // skewX(-12°): x' = x + y·tan(-12°).
    canvas.transform(
      (Matrix4.identity()..setEntry(0, 1, math.tan(-12 * math.pi / 180)))
          .storage,
    );
    for (var i = 0; i < accents.length; i++) {
      paint.color = accents[i];
      canvas.drawRect(
        Rect.fromLTWH(
          x0 + i * column,
          -size.height * 0.24,
          column + 0.2,
          size.height * 1.48,
        ),
        paint,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SweepPainter old) => old.run.value != run.value;
}
