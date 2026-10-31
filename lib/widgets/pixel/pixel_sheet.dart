import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';
import 'pixel_panel.dart';

/// Bottom sheet theo phong cách pixel. `fullScreen: true` cho form nhiều field.
Future<R?> showPixelSheet<R>({
  required BuildContext context,
  required String title,
  required Widget Function(BuildContext) builder,
  bool fullScreen = false,
}) {
  final palette = Theme.of(context).extension<AppPalette>() ?? AppPalette.light;
  return showModalBottomSheet<R>(
    context: context,
    isScrollControlled: true,
    backgroundColor: palette.surface,
    shape: const RoundedRectangleBorder(),
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight:
                MediaQuery.sizeOf(sheetContext).height *
                (fullScreen ? 0.92 : 0.8),
          ),
          child: PixelPanel(
            background: palette.surface,
            borderWidth: 0,
            shadowOffset: Offset.zero,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  title,
                  style: Theme.of(sheetContext).textTheme.headlineSmall
                      ?.copyWith(letterSpacing: 0.9),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: SingleChildScrollView(child: builder(sheetContext)),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
