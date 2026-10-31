import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';

/// Đường kẻ ngang 2px phân tách nội dung trong panel pixel.
class PixelDivider extends StatelessWidget {
  final EdgeInsetsGeometry margin;

  const PixelDivider({
    super.key,
    this.margin = const EdgeInsets.symmetric(vertical: 8),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin,
      child: ExcludeSemantics(
        child: ColoredBox(
          color: context.palette.line,
          child: const SizedBox(height: 2, width: double.infinity),
        ),
      ),
    );
  }
}
