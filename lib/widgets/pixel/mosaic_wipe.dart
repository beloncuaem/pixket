import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../core/theme/app_palette.dart';

/// Lật lưới mosaic khi đổi mục: che nội dung cũ, thay con ở giữa lượt lật.
class MosaicWipe extends StatefulWidget {
  const MosaicWipe({
    super.key,
    required this.transitionKey,
    required this.child,
    required this.enabled,
  });

  final Object transitionKey;
  final Widget child;
  final bool enabled;

  @override
  State<MosaicWipe> createState() => _MosaicWipeState();
}

class _MosaicWipeState extends State<MosaicWipe>
    with SingleTickerProviderStateMixin {
  late final AnimationController _run = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  );
  late Widget _shown = widget.child;
  bool _running = false;
  bool _swapped = true;

  @override
  void initState() {
    super.initState();
    _run.addListener(_tick);
    _run.addStatusListener((status) {
      if (status == AnimationStatus.completed && _running) {
        setState(() {
          _running = false;
          _shown = widget.child;
        });
      }
    });
  }

  void _tick() {
    if (!_swapped && _run.value >= 0.5) {
      _swapped = true;
      setState(() => _shown = widget.child);
    }
  }

  @override
  void didUpdateWidget(MosaicWipe oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.transitionKey == widget.transitionKey) return;
    _swapped = true;
    _shown = widget.child;
    if (!widget.enabled) {
      _run.stop();
      _running = false;
      return;
    }
    // didUpdateWidget luôn được nối bằng một lượt build nên khỏi setState.
    _swapped = false;
    _running = true;
    _shown = oldWidget.child;
    _run
      ..reset()
      ..forward();
  }

  @override
  void dispose() {
    _run.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_running) return _shown;
    return Stack(
      children: [
        _shown,
        IgnorePointer(
          child: RepaintBoundary(
            child: CustomPaint(
              key: const ValueKey('mosaic-wipe'),
              painter: _MosaicPainter(context.palette, _run),
              size: Size.infinite,
            ),
          ),
        ),
      ],
    );
  }
}

class _MosaicPainter extends CustomPainter {
  _MosaicPainter(this.palette, this.run) : super(repaint: run);

  static const _rows = 8;
  static const _cols = 14;
  static const _cells = _rows * _cols;

  /// Thứ tự lật cố định (seed) để mọi lần đổi mục trông giống nhau.
  static final List<int> _order =
      List<int>.generate(_cells, (i) => i)
        ..shuffle(math.Random(20261102));

  final AppPalette palette;
  final Animation<double> run;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final cellW = size.width / _cols;
    final cellH = size.height / _rows;
    // 2 × _cells bậc rời: nửa đầu bật lên che nội dung cũ, nửa sau tắt dần.
    final step = (run.value * _cells * 2).floor().clamp(0, _cells * 2);
    final paint = Paint()..isAntiAlias = false;

    for (var k = 0; k < _cells; k++) {
      final covered = step <= _cells ? k < step : k >= step - _cells;
      if (!covered) continue;
      final index = _order[k];
      final x = index % _cols;
      final y = index ~/ _cols;
      paint.color = (x + y).isEven ? palette.surface : palette.canvas;
      canvas.drawRect(
        Rect.fromLTWH(x * cellW, y * cellH, cellW + 0.5, cellH + 0.5),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MosaicPainter old) => old.run.value != run.value;
}
