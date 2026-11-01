import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';
import '../../core/utils/icon_helper.dart';
import '../../widgets/pixel/app_icon.dart';

/// Lưới chọn biểu tượng pixel cho danh mục; mỗi ô 48×48 dp (bội số của lưới 16).
class CategoryGlyphGrid extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;
  final List<String>? glyphs;

  const CategoryGlyphGrid({
    super.key,
    required this.selected,
    required this.onChanged,
    this.glyphs,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final keys = glyphs ?? IconHelper.availableIcons;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final glyphKey in keys)
          Semantics(
            button: true,
            selected: glyphKey == selected,
            label: 'Biểu tượng $glyphKey',
            child: GestureDetector(
              key: ValueKey('glyph-cell-$glyphKey'),
              behavior: HitTestBehavior.opaque,
              onTap: () => onChanged(glyphKey),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: glyphKey == selected
                      ? palette.mint
                      : palette.surfaceAlt,
                  border: Border.all(
                    color: glyphKey == selected
                        ? palette.mintStrong
                        : palette.line,
                    width: glyphKey == selected ? 3 : 2,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(
                  child: AppIcon(
                    name: glyphKey,
                    size: 32,
                    color: glyphKey == selected
                        ? palette.onAccent
                        : palette.ink,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
