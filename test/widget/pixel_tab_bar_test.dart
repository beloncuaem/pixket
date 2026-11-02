import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixket/core/navigation/app_section.dart';
import 'package:pixket/core/theme/app_palette.dart';
import 'package:pixket/core/theme/app_theme.dart';
import 'package:pixket/widgets/pixel/pixel_tab_bar.dart';

void main() {
  testWidgets('4 mục, đổi tab gọi onSelect đúng một lần', (tester) async {
    final taps = <AppSection>[];
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(
        bottomNavigationBar: PixelTabBar(
          selected: AppSection.feed,
          onSelect: taps.add,
        ),
      ),
    ));

    for (final label in ['CHỤP', 'SỔ', 'BIỂU', 'NGÂN']) {
      expect(find.text(label), findsOneWidget);
    }

    await tester.tap(find.text('BIỂU'));
    await tester.pump();
    expect(taps, [AppSection.statistics]);

    // 'CHỤP' đang là mục được chọn nên không phát callback.
    await tester.tap(find.text('CHỤP'));
    await tester.pump();
    expect(taps, [AppSection.statistics], reason: 'mục đang chọn không gọi lại');
  });

  testWidgets('mục chọn có Semantics selected', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(
        bottomNavigationBar: PixelTabBar(
          selected: AppSection.budget,
          onSelect: (_) {},
        ),
      ),
    ));
    // Đọc thẳng widget Semantics: `tester.getSemantics` cần bật semantics handle,
    // còn `find.ancestor(..., byType(Semantics))` dính nhiều lớp Semantics lồng nhau
    // nên mỗi tab mang một ValueKey riêng để finder trả đúng một widget.
    final palette = AppTheme.dark.extension<AppPalette>()!;
    Semantics semOf(String label) =>
        tester.widget<Semantics>(find.byKey(ValueKey('tab-$label')));
    Color bgOf(String label) => tester
        .widget<ColoredBox>(
          find.descendant(
            of: find.byKey(ValueKey('tab-$label')),
            matching: find.byType(ColoredBox),
          ),
        )
        .color;

    expect(bgOf('NGÂN'), palette.butter);
    expect(bgOf('CHỤP'), palette.surface);
    expect(semOf('NGÂN').properties.selected, isTrue);
    expect(semOf('CHỤP').properties.selected, isFalse);
    expect(semOf('NGÂN').properties.button, isTrue);
  });
}
