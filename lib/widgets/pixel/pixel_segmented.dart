import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';
import 'app_icon.dart';

class PixelSegmentItem<T> {
  final T value;
  final String label;
  final String? glyph;

  const PixelSegmentItem({
    required this.value,
    required this.label,
    this.glyph,
  });
}

/// Nhóm chọn loại (ngày/tuần/tháng...) dạng khối pixel liền nhau.
class PixelSegmented<T> extends StatelessWidget {
  final List<PixelSegmentItem<T>> items;
  final T selected;
  final ValueChanged<T> onChanged;

  const PixelSegmented({
    super.key,
    required this.items,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Row(
      children: [
        for (final item in items)
          Expanded(
            child: Semantics(
              selected: item.value == selected,
              button: true,
              label: item.label,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(item.value),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: item.value == selected
                        ? palette.mint
                        : palette.surface,
                    border: Border.all(color: palette.lineStrong, width: 2),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (item.glyph != null) ...[
                        AppIcon(
                          name: item.glyph!,
                          size: 16,
                          color: item.value == selected
                              ? palette.onAccent
                              : palette.ink,
                        ),
                        const SizedBox(width: 6),
                      ],
                      Flexible(
                        child: Text(
                          item.label.toUpperCase(),
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(
                                color: item.value == selected
                                    ? palette.onAccent
                                    : palette.ink,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
