import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';

/// Nhấp nháy theo bậc (không shimmer mượt): các khối đổi độ sáng mỗi phần tư chu kỳ.
class PixelLoading extends StatefulWidget {
  final int blocks;
  final String? label;

  const PixelLoading({super.key, this.blocks = 3, this.label});

  @override
  State<PixelLoading> createState() => _PixelLoadingState();
}

class _PixelLoadingState extends State<PixelLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 480),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final disabled =
            MediaQuery.maybeOf(context)?.disableAnimations ?? false;
        final step = disabled ? 0 : (_controller.value * 4).floor() % 4;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Stepped(step: step, blocks: widget.blocks),
            if (widget.label != null) ...[
              const SizedBox(height: 8),
              Text(
                widget.label!,
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ],
          ],
        );
      },
    );
  }
}

class _Stepped extends StatelessWidget {
  final int step;
  final int blocks;

  const _Stepped({required this.step, required this.blocks});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < blocks; i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Container(
              width: 12,
              height: 12,
              color: ((i + step) % blocks == 0)
                  ? palette.mintStrong
                  : palette.surfaceAlt,
            ),
          ),
      ],
    );
  }
}
