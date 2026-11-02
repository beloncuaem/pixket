import 'package:flutter/material.dart';
import 'package:pixket/core/icons/pixel_glyph_data.dart';
import 'package:pixket/core/theme/app_palette.dart';
import 'package:pixket/core/theme/app_theme.dart';
import 'package:pixket/widgets/pixel/app_icon.dart';

void main() {
  runApp(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        backgroundColor: AppPalette.light.canvas,
        body: SafeArea(
          child: GridView.count(
            crossAxisCount: 6,
            children: [
              for (final name in PixelGlyphData.names)
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [AppIcon(name: name, size: 32), Text(name)],
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}
