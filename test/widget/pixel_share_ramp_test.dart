import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixket/core/theme/app_palette.dart';
import 'package:pixket/core/theme/app_theme.dart';
import 'package:pixket/widgets/pixel/pixel_share_bar.dart';
import 'package:pixket/widgets/pixel/pixel_stacked_share.dart';

void main() {
  testWidgets('share bar dùng ramp khi có reference, accent khi tắt', (
    tester,
  ) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: const Scaffold(
        body: PixelShareBar(
          label: 'Ăn uống',
          glyph: 'coffee',
          value: 80,
          total: 100,
          valueText: '80₫',
          reference: 100,
        ),
      ),
    ));
    expect(
      find.byWidgetPredicate(
        (w) => w is Container && w.color == AppPalette.light.rampFill(0.8),
      ),
      findsWidgets,
    );
    expect(find.textContaining('Vượt mức'), findsOneWidget);

    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: const Scaffold(
        body: PixelShareBar(
          label: 'Ăn uống',
          glyph: 'coffee',
          value: 80,
          total: 100,
          valueText: '80₫',
          useSpendRamp: false,
        ),
      ),
    ));
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is Container &&
            w.color == AppPalette.light.accentForCategory('Ăn uống'),
      ),
      findsWidgets,
    );
  });

  testWidgets('stacked share tô từng nhóm theo ramp', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: const Scaffold(
        body: PixelStackedShare(
          labels: ['A', 'B'],
          glyphs: ['tag', 'tag'],
          values: [20, 90],
          valueTexts: ['20₫', '90₫'],
          reference: 100,
        ),
      ),
    ));
    expect(
      find.byWidgetPredicate(
        (w) => w is Container && w.color == AppPalette.light.rampFill(0.9),
      ),
      findsWidgets,
    );
  });
}
