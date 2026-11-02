import 'package:flutter/material.dart';

import '../../core/navigation/app_section.dart';
import '../../core/theme/app_palette.dart';
import 'app_icon.dart';

/// Tab bar đáy 4 mục; màu không đủ mang nghĩa nên mỗi mục giữ Semantics selected.
class PixelTabBar extends StatelessWidget {
  const PixelTabBar({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  final AppSection selected;
  final ValueChanged<AppSection> onSelect;

  static const _items = <AppSection, (String, String)>{
    AppSection.feed: ('CHỤP', 'camera'),
    AppSection.dashboard: ('SỔ', 'receipt'),
    AppSection.statistics: ('BIỂU', 'chart'),
    AppSection.budget: ('NGÂN', 'wallet'),
  };

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;

    return Container(
      color: palette.surface,
      child: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: palette.lineStrong, width: 3)),
          ),
          child: Row(
            children: [
              for (final entry in _items.entries)
                Expanded(
                  child: _TabItem(
                    label: entry.value.$1,
                    glyph: entry.value.$2,
                    isSelected: entry.key == selected,
                    palette: palette,
                    labelStyle: text.labelLarge,
                    onTap: () {
                      if (entry.key != selected) onSelect(entry.key);
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.label,
    required this.glyph,
    required this.isSelected,
    required this.palette,
    required this.labelStyle,
    required this.onTap,
  });

  final String label;
  final String glyph;
  final bool isSelected;
  final AppPalette palette;
  final TextStyle? labelStyle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = isSelected ? palette.butter : palette.surface;
    final fg = isSelected ? palette.onAccent : palette.inkMuted;

    return Semantics(
      key: ValueKey('tab-$label'),
      button: true,
      selected: isSelected,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ColoredBox(
          color: bg,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppIcon(name: glyph, size: 24, color: fg),
                const SizedBox(height: 2),
                Text(label, style: labelStyle?.copyWith(color: fg)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
