import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pixket/core/theme/app_palette.dart';
import 'package:pixket/core/theme/app_theme.dart';

void main() {
  testWidgets('light theme cung cấp AppPalette và font bundle', (tester) async {
    late BuildContext captured;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (context) {
            captured = context;
            return const SizedBox();
          },
        ),
      ),
    );

    expect(captured.palette, isA<AppPalette>());
    final textTheme = Theme.of(captured).textTheme;
    expect(textTheme.displayLarge!.fontFamily, 'VT323');
    expect(textTheme.titleLarge!.fontFamily, 'VT323');
    expect(textTheme.bodyLarge!.fontFamily, 'BeVietnamPro');
    expect(
      textTheme.bodyLarge!.fontVariations,
      contains(const FontVariation('wght', 400)),
    );
    expect(
      textTheme.titleLarge!.fontVariations,
      isNull,
    ); // VT323 chỉ có một weight, không cần variation
  });

  test('light và dark giữ màu muted riêng cho bodySmall', () {
    final light = AppTheme.light.textTheme;
    expect(light.bodySmall!.color, AppPalette.light.inkMuted);
    expect(light.bodyLarge!.color, AppPalette.light.ink);
    expect(AppTheme.dark.textTheme.bodySmall!.color, AppPalette.dark.inkMuted);
  });

  test('dark theme dùng palette dark', () {
    final theme = AppTheme.dark;
    final palette = theme.extension<AppPalette>()!;
    expect(palette.canvas, AppPalette.dark.canvas);
    expect(theme.scaffoldBackgroundColor, AppPalette.dark.canvas);
  });

  test('không còn tham chiếu google_fonts', () {
    final source = File('lib/core/theme/app_theme.dart').readAsStringSync();
    expect(source.contains('GoogleFonts'), isFalse);
  });
}
