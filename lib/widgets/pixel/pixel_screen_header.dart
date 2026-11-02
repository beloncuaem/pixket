import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';
import 'app_icon.dart';
import 'pixel_logo.dart';

/// Header pixel dùng cho mọi màn trừ feed/camera (màn đó có HUD tối riêng).
class PixelScreenHeader extends StatelessWidget {
  const PixelScreenHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onMenuTap,
    this.onBackTap,
    this.leading,
    this.trailing,
    this.background,
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onMenuTap;
  final VoidCallback? onBackTap;
  final Widget? leading;
  final Widget? trailing;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;

    return Container(
      constraints: const BoxConstraints(minHeight: 64),
      padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
      decoration: BoxDecoration(
        color: background ?? palette.canvas,
        border: Border(bottom: BorderSide(color: palette.lineStrong, width: 3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          leading ?? _buildLeading(palette),
          const SizedBox(width: 8),
          // Màn push (có nút back) không gắn mark để hàng không chật.
          if (onBackTap == null) ...[
            const PixelLogo(size: 24),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(title, style: text.headlineSmall),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodySmall?.copyWith(color: palette.inkMuted),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }

  Widget _buildLeading(AppPalette palette) {
    final isBack = onMenuTap == null && onBackTap != null;
    final onTap = onMenuTap ?? onBackTap;
    if (onTap == null) return const SizedBox(width: 8);
    return SizedBox(
      width: 48,
      height: 48,
      child: IconButton(
        onPressed: onTap,
        tooltip: isBack ? 'Quay lại' : 'Mở menu',
        padding: EdgeInsets.zero,
        icon: AppIcon(
          name: isBack ? 'back' : 'menu',
          size: 32,
          color: palette.ink,
        ),
      ),
    );
  }
}

Widget pixelGroupHeader(String label) {
  return Builder(
    builder: (context) {
      final palette = context.palette;
      return Padding(
        padding: const EdgeInsets.fromLTRB(4, 14, 4, 6),
        child: Row(
          children: [
            AppIcon(name: 'chevronRight', size: 16, color: palette.mintInk),
            const SizedBox(width: 6),
            // Expanded + FittedBox: nhãn nhóm dài (vd 'GIAO DIỆN & BIỂU ĐỒ')
            // phải co lại chứ không tràn Row ở text scale 1.3x.
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  label.toUpperCase(),
                  style: Theme.of(context).textTheme.labelMedium
                      ?.copyWith(color: palette.inkMuted),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}
