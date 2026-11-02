import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_palette.dart';
import '../../providers/app_settings_provider.dart';

class _Piece {
  const _Piece(this.x, this.lift, this.accent);

  final double x;
  final double lift;
  final int accent;
}

/// 24 ô 4×4, seed cố định nên mỗi lần nổ ra cùng một bố cục.
final List<_Piece> _pieces = () {
  final rng = math.Random(20261102);
  return List<_Piece>.generate(
    24,
    (i) => _Piece(rng.nextDouble(), 0.6 + rng.nextDouble() * 0.4, i % 6),
  );
}();

/// Pháo giấy pixel nổ khi lưu chi tiêu thành công.
class PixelConfetti {
  PixelConfetti._();

  static void burst(BuildContext context) {
    if (!ProviderScope.containerOf(context).read(effectsProvider).confetti) {
      return;
    }
    // root_overlay: điểm nổ nằm trong bottom sheet sắp pop, entry gắn vào
    // overlay của sheet sẽ bị gỡ theo route trước khi kịp vẽ.
    final overlay = Overlay.of(context, rootOverlay: true);
    final still = MediaQuery.of(context).disableAnimations;
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _ConfettiOverlay(
        still: still,
        onDone: () => entry.remove(),
      ),
    );
    overlay.insert(entry);
  }
}

class _ConfettiOverlay extends StatefulWidget {
  const _ConfettiOverlay({required this.still, required this.onDone});

  final bool still;
  final VoidCallback onDone;

  @override
  State<_ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<_ConfettiOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _run = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: widget.still ? 120 : 480),
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
          key: const ValueKey('pixel-confetti'),
          painter: _ConfettiPainter(context.palette.accents, widget.still, _run),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.accents, this.still, this.run) : super(repaint: run);

  final List<Color> accents;
  final bool still;
  final Animation<double> run;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0 || accents.isEmpty) return;
    // 8 bậc rời: 6 bậc bay lên rồi 2 bậc rơi; tắt động thì đứng ở đỉnh.
    final step = still ? 6 : (run.value * 8).floor().clamp(0, 7);
    final up = math.min(step, 6);
    final down = step - up;
    final startY = size.height * 0.62;
    final paint = Paint()..isAntiAlias = false;

    for (final piece in _pieces) {
      final y = startY -
          up * size.height * 0.06 * piece.lift +
          down * size.height * 0.10 * piece.lift;
      paint.color = accents[piece.accent % accents.length];
      canvas.drawRect(
        Rect.fromLTWH(piece.x * (size.width - 4), y, 4, 4),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) =>
      old.run.value != run.value;
}
