import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';

enum PixelTone { info, success, warning, danger }

void showPixelSnackBar(
  BuildContext context,
  String message, {
  String? actionLabel,
  VoidCallback? onAction,
  PixelTone tone = PixelTone.info,
  SnackBarAction? action,
  Duration duration = const Duration(seconds: 4),
}) {
  final palette = Theme.of(context).extension<AppPalette>() ?? AppPalette.light;
  final border = switch (tone) {
    PixelTone.info => palette.mint,
    PixelTone.success => palette.mint,
    PixelTone.warning => palette.butter,
    PixelTone.danger => palette.rose,
  };

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        duration: action != null || onAction != null
            ? const Duration(seconds: 5)
            : duration,
        backgroundColor: palette.ink,
        margin: const EdgeInsets.all(12),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(2),
          side: BorderSide(color: border, width: 2),
        ),
        content: Text(
          message,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: palette.canvas),
        ),
        action:
            action ??
            (actionLabel != null && onAction != null
                ? SnackBarAction(
                    label: actionLabel,
                    textColor: palette.butter,
                    onPressed: onAction,
                  )
                : null),
      ),
    );
}
