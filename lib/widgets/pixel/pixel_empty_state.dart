import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';
import 'app_icon.dart';
import 'pixel_button.dart';
import 'pixel_panel.dart';

class PixelEmptyState extends StatelessWidget {
  final String glyph;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const PixelEmptyState({
    super.key,
    required this.glyph,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: PixelPanel(
          background: palette.surface,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppIcon(name: glyph, size: 48, color: palette.mintInk),
              const SizedBox(height: 12),
              Text(
                title.toUpperCase(),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: palette.inkMuted),
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 16),
                PixelButton(
                  label: actionLabel!,
                  onPressed: onAction,
                  icon: 'plus',
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
