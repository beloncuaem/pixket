import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_palette.dart';

/// Registry keep-out tối giản: widget chữ nằm trực tiếp trên canvas báo rect
/// paint (toạ độ global, đã nở 4 px) để nền sao bỏ các ô rơi vào đó.
class KeepOutRegistry extends ChangeNotifier {
  final Map<Object, Rect> _byId = {};

  List<Rect> get rects => _byId.values.toList(growable: false);

  void report(Object id, Rect? rect) {
    if (rect == null) {
      if (_byId.remove(id) != null) notifyListeners();
      return;
    }
    if (_byId[id] == rect) return;
    _byId[id] = rect;
    notifyListeners();
  }
}

final keepOutRegistryProvider = Provider<KeepOutRegistry>((ref) {
  final registry = KeepOutRegistry();
  ref.onDispose(registry.dispose);
  return registry;
});

class PixelStar {
  const PixelStar({
    required this.x,
    required this.y,
    required this.cell,
    required this.tinted,
    required this.twinkle,
    required this.delay,
  });

  final double x, y, delay;
  final double cell; // 2 hoặc 4 px
  final bool tinted, twinkle;

  double get opacity => cell == 2 ? 0.55 : 0.8;
}

/// Sinh sao thuần: seed cố định nên không nhảy khi setState; chỉ gọi lại khi
/// Size đổi. Mật độ 1 ô / 2200 px2 (tối đa 220 ô); 62% ô 2 px, 38% ô 4 px;
/// 10% nhuốm màu star; 20% nhấp nháy.
List<PixelStar> buildStarField(Size size) {
  final random = math.Random(20261102);
  final count = math.min((size.width * size.height / 2200).round(), 220);
  return [
    for (var i = 0; i < count; i++)
      PixelStar(
        x: random.nextDouble() * size.width,
        y: random.nextDouble() * size.height,
        cell: random.nextDouble() < 0.62 ? 2 : 4,
        tinted: random.nextDouble() < 0.10,
        twinkle: random.nextDouble() < 0.20,
        delay: random.nextDouble(),
      ),
  ];
}

/// Sao bị chặn nếu tâm rơi vào rect keep-out đã nở 4 px.
bool starKeptOut(Offset center, Iterable<Rect> rects) =>
    rects.any((rect) => rect.inflate(4).contains(center));

/// Bọc một widget chữ nằm trực tiếp trên canvas để nền sao tránh rect của nó.
class PixelStarSafe extends ConsumerStatefulWidget {
  const PixelStarSafe({super.key, required this.child, this.id});

  final Widget child;
  final Object? id;

  @override
  ConsumerState<PixelStarSafe> createState() => _PixelStarSafeState();
}

class _PixelStarSafeState extends ConsumerState<PixelStarSafe> {
  late final Object _id = widget.id ?? this;
  late final KeepOutRegistry _registry;

  @override
  void initState() {
    super.initState();
    // Đọc sẵn: `ref` không dùng được trong dispose sau khi element đã huỷ.
    _registry = ref.read(keepOutRegistryProvider);
  }

  @override
  void dispose() {
    _registry.report(_id, null);
    super.dispose();
  }

  void _report() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final box = context.findRenderObject() as RenderBox?;
      if (box == null || !box.attached) return;
      final topLeft = box.localToGlobal(Offset.zero);
      _registry.report(
        _id,
        Rect.fromLTWH(topLeft.dx, topLeft.dy, box.size.width, box.size.height),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    _report();
    return widget.child;
  }
}

/// Nền sao vũ trụ: chỉ hiện ở theme dark. Sao nhấp nháy, trôi chậm và có
/// một sao băng mỗi ~30 s; tắt chuyển động khi hệ thống yêu cầu reduced motion.
class PixelStarField extends ConsumerStatefulWidget {
  const PixelStarField({super.key});

  @override
  ConsumerState<PixelStarField> createState() => _PixelStarFieldState();
}

class _PixelStarFieldState extends ConsumerState<PixelStarField>
    with TickerProviderStateMixin {
  static const Duration _driftCycle = Duration(seconds: 30);

  late final AnimationController _twinkle = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );
  late final AnimationController _drift = AnimationController(
    vsync: this,
    duration: _driftCycle,
  );

  Size? _cachedSize;
  List<PixelStar> _stars = const [];

  @override
  void dispose() {
    _twinkle.dispose();
    _drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (!isDark) return const SizedBox.shrink();

    final still = MediaQuery.of(context).disableAnimations;
    if (still) {
      _twinkle.stop(canceled: false);
      _drift.stop(canceled: false);
    } else {
      if (!_twinkle.isAnimating) _twinkle.repeat();
      if (!_drift.isAnimating) _drift.repeat();
    }

    final registry = ref.watch(keepOutRegistryProvider);
    final box = context.findRenderObject() as RenderBox?;

    return IgnorePointer(
      child: RepaintBoundary(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = Size(constraints.maxWidth, constraints.maxHeight);
            if (_cachedSize != size) {
              _cachedSize = size;
              _stars = buildStarField(size);
            }
            return ListenableBuilder(
              listenable: registry,
              builder: (context, _) => CustomPaint(
                painter: _StarPainter(
                  stars: _stars,
                  registry: registry,
                  palette: context.palette,
                  box: box,
                  twinkle: _twinkle,
                  drift: _drift,
                  still: still,
                ),
                size: size,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _StarPainter extends CustomPainter {
  _StarPainter({
    required this.stars,
    required this.registry,
    required this.palette,
    required this.box,
    required this.twinkle,
    required this.drift,
    required this.still,
  }) : super(repaint: still ? null : Listenable.merge([twinkle, drift]));

  final List<PixelStar> stars;
  final KeepOutRegistry registry;
  final AppPalette palette;
  final RenderBox? box;
  final Animation<double> twinkle;
  final Animation<double> drift;
  final bool still;

  /// Cửa sổ sao băng trong chu kỳ trôi (0..1) — chiếm 6% thời lượng.
  static const double _shootStart = 0.12;
  static const double _shootSpan = 0.06;

  @override
  void paint(Canvas canvas, Size size) {
    final origin = box?.attached == true
        ? box!.localToGlobal(Offset.zero)
        : Offset.zero;
    final keepOut = [for (final rect in registry.rects) rect.shift(-origin)];
    final paint = Paint()..isAntiAlias = false;
    final t = still ? 0.0 : drift.value;

    // Trôi chậm theo vòng sin để không khựng khi chu kỳ lặp lại; snap về
    // lưới pixel nên sao vẫn sắc nét.
    final driftDx = still
        ? 0.0
        : (3 * math.sin(2 * math.pi * t)).roundToDouble();
    final driftDy = still
        ? 0.0
        : (2 * math.cos(2 * math.pi * t)).roundToDouble();

    for (final star in stars) {
      final center = Offset(
        star.x + driftDx + star.cell / 2,
        star.y + driftDy + star.cell / 2,
      );
      if (starKeptOut(center, keepOut)) continue;
      var opacity = star.opacity;
      if (!still && star.twinkle) {
        // steps(2): nửa chu kỳ sáng, nửa chu kỳ mờ; delay riêng theo seed.
        if (((twinkle.value + star.delay) * 2).floor() % 2 == 1) {
          opacity *= 0.35;
        }
      }
      paint.color = (star.tinted ? palette.star : palette.ink).withValues(
        alpha: opacity,
      );
      canvas.drawRect(
        Rect.fromLTWH(
          center.dx - star.cell / 2,
          center.dy - star.cell / 2,
          star.cell,
          star.cell,
        ),
        paint,
      );
    }

    if (still) return;
    if (t < _shootStart || t > _shootStart + _shootSpan) return;
    _paintShootingStar(
      canvas,
      size,
      keepOut,
      paint,
      (t - _shootStart) / _shootSpan,
    );
  }

  /// Sao băng pixel: đầu 4 px kéo theo đuôi 6 ô 2 px, sáng dần rồi tắt dần.
  void _paintShootingStar(
    Canvas canvas,
    Size size,
    List<Rect> keepOut,
    Paint paint,
    double progress,
  ) {
    final start = Offset(size.width * 0.12, size.height * 0.08);
    final end = Offset(size.width * 0.78, size.height * 0.42);
    final head = Offset.lerp(start, end, progress)!;
    final direction = (end - start);
    final unit = direction / direction.distance;
    // Đầu vào/ra mượt: alpha tam giác theo progress.
    final fade = progress < 0.5 ? progress * 2 : (1 - progress) * 2;

    for (var i = 0; i < 7; i++) {
      final cell = i == 0 ? 4.0 : 2.0;
      final pos = head - unit * (i * 4);
      final topLeft = Offset(
        (pos.dx - cell / 2).roundToDouble(),
        (pos.dy - cell / 2).roundToDouble(),
      );
      final center = topLeft + Offset(cell / 2, cell / 2);
      if (starKeptOut(center, keepOut)) continue;
      final alpha = (0.9 - i * 0.12).clamp(0.0, 1.0) * fade;
      if (alpha <= 0) continue;
      paint.color = palette.star.withValues(alpha: alpha);
      canvas.drawRect(Rect.fromLTWH(topLeft.dx, topLeft.dy, cell, cell), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _StarPainter old) =>
      old.stars != stars ||
      old.still != still ||
      old.twinkle.value != twinkle.value ||
      old.drift.value != drift.value;
}
