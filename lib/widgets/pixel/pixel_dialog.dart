import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';
import 'pixel_button.dart';
import 'pixel_panel.dart';

Future<T?> showPixelDialog<T>({
  required BuildContext context,
  required String title,
  required Widget content,
  List<Widget> actions = const [],
}) {
  final palette = Theme.of(context).extension<AppPalette>() ?? AppPalette.light;
  return showDialog<T>(
    context: context,
    builder: (dialogContext) => Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      backgroundColor: Colors.transparent,
      child: PixelPanel(
        background: palette.surface,
        borderWidth: 3,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(dialogContext).textTheme.headlineSmall
                  ?.copyWith(letterSpacing: 0.9),
            ),
            const SizedBox(height: 12),
            Flexible(child: content),
            if (actions.isNotEmpty) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  for (final action in actions)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: action,
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

/// Dialog xác nhận hai nút dùng chung cho xóa/hủy.
Future<bool> showPixelConfirm(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Xóa',
  String cancelLabel = 'Hủy',
  bool danger = true,
}) async {
  final result = await showPixelDialog<bool>(
    context: context,
    title: title,
    content: Text(message, style: Theme.of(context).textTheme.bodyMedium),
    actions: [
      PixelButton(
        label: cancelLabel,
        variant: PixelButtonVariant.secondary,
        onPressed: () => Navigator.of(context).pop(false),
      ),
      PixelButton(
        label: confirmLabel,
        variant: danger
            ? PixelButtonVariant.danger
            : PixelButtonVariant.primary,
        onPressed: () => Navigator.of(context).pop(true),
      ),
    ],
  );
  return result ?? false;
}
