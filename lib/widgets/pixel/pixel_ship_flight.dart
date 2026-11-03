import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';

/// Sprite phi thuyền 16×8 ô: H thân kem, W cửa sổ xanh, F cánh đỏ. Mũi hướng
/// phải nên đuôi cầu vồng nối vào cạnh trái.
const List<String> _shipSprite = [
  '......HHH.......',
  '....HHHHHHH.....',
  '.FFHHHWWHHHHH...',
  'FFHHHHWWHHHHHHHH',
  'FFHHHHWWHHHHHHHH',
  '.FFHHHWWHHHHH...',
  '....HHHHHHH.....',
  '......HHH.......',
];

/// Hiệu ứng lúc chụp: phi thuyền pixel bay ngang màn hình kéo theo đuôi cầu
/// vồng sáu màu (~700 ms). Không chặn luồng chụp và tự gỡ khỏi Overlay.
class PixelShipFlight {
  PixelShipFlight._();

  static void launch(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) return;
    final overlay = Overlay.of(context, rootOverlay: true);
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _ShipOverlay(onDone: () => entry.remove()),
    );
    overlay.insert(entry);
  }
}

class _ShipOverlay extends StatefulWidget {
  const _ShipOverlay({required this.onDone});

  final VoidCallback onDone;

  @override
  State<_ShipOverlay> createState() => _ShipOverlayState();
}

class _ShipOverlayState extends State<_ShipOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _run = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );

  @override
  void initState() {
    super.initState();
    _run.addStatusListener((status) {
      if (status == AnimationStatus.completed) widget.onDone();
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
          key: const ValueKey('pixel-ship-flight'),
          painter: _ShipPainter(context.palette, _run),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _ShipPainter extends CustomPainter {
  _ShipPainter(this.palette, this.run) : super(repaint: run);

  final AppPalette palette;
  final Animation<double> run;

  static const double _cell = 4;
  static const double _shipWidth = 16 * _cell;
  static const double _shipHeight = 8 * _cell;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final t = run.value;
    // Vào nhanh, bay rõ, tan dần ở 25% cuối để không khựng khi gỡ overlay.
    final fade = t < 0.08
        ? t / 0.08
        : t > 0.75
        ? 1 - (t - 0.75) / 0.25
        : 1.0;
    if (fade <= 0) return;

    final x = -_shipWidth + t * (size.width + _shipWidth * 2);
    // Nhích lên dần cộng nhấp nhô hai nhịp, snap lưới pixel cho sắc nét.
    final bob = (4 * math.sin(2 * math.pi * t * 2)).roundToDouble();
    final y = size.height * 0.30 - size.height * 0.06 * t + bob;

    _paintTail(canvas, t, x, y + _shipHeight / 2, fade);
    _paintShip(canvas, x, y, fade);
  }

  void _paintTail(
    Canvas canvas,
    double t,
    double shipX,
    double centerY,
    double fade,
  ) {
    final accents = palette.accents;
    if (accents.isEmpty) return;
    final stripes = math.min(6, accents.length);
    final top = centerY - stripes * _cell / 2;
    final paint = Paint()
      ..isAntiAlias = false
      ..color = accents.first.withValues(alpha: fade);

    for (var i = 0; i < stripes; i++) {
      // Mép đuôi so le: mỗi dải thụt theo một nhịp sin riêng.
      final wobble = (3 * math.sin(2 * math.pi * (t * 3 + i * 0.16)))
          .roundToDouble();
      final right = (shipX + wobble).roundToDouble();
      if (right <= 0) continue;
      paint.color = accents[i].withValues(alpha: fade);
      canvas.drawRect(
        Rect.fromLTRB(
          0,
          (top + i * _cell).roundToDouble(),
          right,
          (top + (i + 1) * _cell).roundToDouble(),
        ),
        paint,
      );
    }
  }

  void _paintShip(Canvas canvas, double x, double y, double fade) {
    final paint = Paint()..isAntiAlias = false;
    final hull = palette.feedInk.withValues(alpha: fade);
    final window = palette.sky.withValues(alpha: fade);
    final fin = palette.rose.withValues(alpha: fade);

    for (var row = 0; row < _shipSprite.length; row++) {
      final line = _shipSprite[row];
      for (var col = 0; col < line.length; col++) {
        final char = line[col];
        if (char == '.') continue;
        paint.color = switch (char) {
          'W' => window,
          'F' => fin,
          _ => hull,
        };
        canvas.drawRect(
          Rect.fromLTWH(
            (x + col * _cell).roundToDouble(),
            (y + row * _cell).roundToDouble(),
            _cell,
            _cell,
          ),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ShipPainter old) => old.run.value != run.value;
}
