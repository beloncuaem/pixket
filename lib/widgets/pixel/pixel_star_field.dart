import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_palette.dart';
import '../../providers/app_settings_provider.dart';

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
/// Size đổi. Mật độ 1 ô / 3600 px2; 62% ô 2 px, 38% ô 4 px; 6% nhuốm màu star;
/// 12% nhấp nháy.
List<PixelStar> buildStarField(Size size) {
  final random = math.Random(20261102);
  final count = (size.width * size.height / 3600).round();
  return [
    for (var i = 0; i < count; i++)
      PixelStar(
        x: random.nextDouble() * size.width,
        y: random.nextDouble() * size.height,
        cell: random.nextDouble() < 0.62 ? 2 : 4,
        tinted: random.nextDouble() < 0.06,
        twinkle: random.nextDouble() < 0.12,
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
        Rect.fromLTWH(
          topLeft.dx,
          topLeft.dy,
          box.size.width,
          box.size.height,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    _report();
    return widget.child;
  }
}

/// Nền sao vũ trụ: chỉ theme dark và chỉ khi khoá `fx_stars` bật.
class PixelStarField extends ConsumerStatefulWidget {
  const PixelStarField({super.key});

  @override
  ConsumerState<PixelStarField> createState() => _PixelStarFieldState();
}

class _PixelStarFieldState extends ConsumerState<PixelStarField>
    with SingleTickerProviderStateMixin {
  late final AnimationController _twinkle = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  Size? _cachedSize;
  List<PixelStar> _stars = const [];

  @override
  void dispose() {
    _twinkle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final enabled = ref.watch(effectsProvider).stars;
    if (!isDark || !enabled) return const SizedBox.shrink();

    final still = MediaQuery.of(context).disableAnimations;
    if (still) {
      _twinkle.stop(canceled: false);
    } else if (!_twinkle.isAnimating) {
      _twinkle.repeat();
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
                  _stars,
                  registry,
                  context.palette,
                  box,
                  _twinkle,
                  still,
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
  _StarPainter(
    this.stars,
    this.registry,
    this.palette,
    this.box,
    this.twinkle,
    this.still,
  ) : super(repaint: still ? null : twinkle);

  final List<PixelStar> stars;
  final KeepOutRegistry registry;
  final AppPalette palette;
  final RenderBox? box;
  final Animation<double> twinkle;
  final bool still;

  @override
  void paint(Canvas canvas, Size size) {
    final origin = box?.attached == true
        ? box!.localToGlobal(Offset.zero)
        : Offset.zero;
    final keepOut = [for (final rect in registry.rects) rect.shift(-origin)];
    final paint = Paint()..isAntiAlias = false;

    for (final star in stars) {
      final center = Offset(star.x + star.cell / 2, star.y + star.cell / 2);
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
        Rect.fromLTWH(star.x, star.y, star.cell, star.cell),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _StarPainter old) =>
      old.stars != stars ||
      old.still != still ||
      old.twinkle.value != twinkle.value;
}
