import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_palette.dart';
import '../../providers/app_settings_provider.dart';

/// Gạch chân cầu vồng 6 ô trượt ngang 14 bậc rời trong 1,6 s; tĩnh khi tắt.
class RainbowRule extends ConsumerStatefulWidget {
  const RainbowRule({super.key, this.height = 5});

  final double height;

  @override
  ConsumerState<RainbowRule> createState() => _RainbowRuleState();
}

class _RainbowRuleState extends ConsumerState<RainbowRule>
    with SingleTickerProviderStateMixin {
  late final AnimationController _slide = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  bool _ran = false;

  @override
  void dispose() {
    _slide.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final animate =
        ref.watch(effectsProvider).rainbowRule &&
        !MediaQuery.of(context).disableAnimations;
    // Chạy MỘT lượt rồi nghỉ (spec §6: "chạy ngang trong 1,6 s"). Loop vô hạn
    // dưới mọi PixelScreenHeader sẽ làm `pumpAndSettle` của ~8 test cũ timeout
    // và tốn pin trên máy thật; bậc 14 kết thúc ở đúng vị trí dải tĩnh.
    if (animate && !_ran) {
      _ran = true;
      _slide.forward(from: 0);
    } else if (!animate && _slide.isAnimating) {
      _slide.stop(canceled: false);
    }

    return SizedBox(
      height: widget.height,
      child: CustomPaint(
        painter: _RainbowPainter(context.palette.accents, _slide, animate),
        size: Size.infinite,
      ),
    );
  }
}

class _RainbowPainter extends CustomPainter {
  _RainbowPainter(this.accents, this.slide, this.animate)
    : super(repaint: animate ? slide : null);

  final List<Color> accents;
  final Animation<double> slide;
  final bool animate;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0 || accents.isEmpty) return;
    // Vẽ dải gấp đôi chiều rộng để phần trượt quấn vòng không để hở mép.
    final step = animate ? (slide.value * 14).floor() % 14 : 0;
    final shift = -(step / 14) * size.width;
    final band = size.width / accents.length;
    final paint = Paint()..isAntiAlias = false;
    for (var pass = 0; pass < 2; pass++) {
      for (var i = 0; i < accents.length; i++) {
        paint.color = accents[i];
        canvas.drawRect(
          Rect.fromLTWH(
            shift + pass * size.width + i * band,
            0,
            band + 0.2,
            size.height,
          ),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RainbowPainter old) =>
      old.animate != animate || old.slide.value != slide.value;
}
