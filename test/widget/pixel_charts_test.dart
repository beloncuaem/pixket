import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chi_tieu/core/theme/app_theme.dart';
import 'package:chi_tieu/widgets/pixel/pixel_bar_chart.dart';
import 'package:chi_tieu/widgets/pixel/pixel_share_bar.dart';
import 'package:chi_tieu/widgets/pixel/pixel_stacked_share.dart';

Widget _wrap(Widget child) => MaterialApp(
  theme: AppTheme.light,
  home: Scaffold(
    body: SizedBox(width: 380, child: SingleChildScrollView(child: child)),
  ),
);

void main() {
  testWidgets('PixelShareBar hiện nhãn, số tiền, % và đủ 14 ô', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const PixelShareBar(
          label: 'Ăn uống',
          glyph: 'forkKnife',
          value: 500000,
          total: 1000000,
          valueText: '500.000 đ',
        ),
      ),
    );
    expect(find.text('Ăn uống'), findsOneWidget);
    expect(find.text('500.000 đ'), findsOneWidget);
    expect(find.text('50%'), findsOneWidget);
    expect(find.byKey(const ValueKey('share-cells-Ăn uống')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('PixelShareBar total = 0 không chia cho 0', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const PixelShareBar(
          label: 'Khác',
          glyph: 'receipt',
          value: 0,
          total: 0,
          valueText: '0 đ',
        ),
      ),
    );
    expect(find.text('0%'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('PixelStackedShare hiện legend đủ 4 mức', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const PixelStackedShare(
          labels: ['Cần thiết', 'Nên có', 'Muốn có', 'Không cần'],
          glyphs: ['check', 'sparkle', 'gift', 'close'],
          values: [3, 1, 1, 1],
          colors: [
            Color(0xFF2F9E6E),
            Color(0xFF3D8BFD),
            Color(0xFFF5C24A),
            Color(0xFFE5484D),
          ],
          valueTexts: ['300 đ', '100 đ', '100 đ', '100 đ'],
          cells: 24,
        ),
      ),
    );
    expect(find.text('Cần thiết'), findsOneWidget);
    expect(find.text('Không cần'), findsOneWidget);
    expect(find.text('50%'), findsOneWidget);
    expect(find.text('17%'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('PixelBarChart vẽ và chạm hiện tooltip', (tester) async {
    await tester.pumpWidget(
      _wrap(
        PixelBarChart(
          dates: [DateTime(2026, 11, 1), DateTime(2026, 11, 2)],
          values: [10000, 20000],
          valueTexts: ['10.000 đ', '20.000 đ'],
        ),
      ),
    );
    expect(find.byKey(const ValueKey('bar-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('bar-1')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('bar-1')));
    await tester.pump();
    expect(find.textContaining('20.000 đ'), findsWidgets);
  });

  testWidgets('PixelBarChart rỗng hiện dòng chữ hướng dẫn', (tester) async {
    await tester.pumpWidget(
      _wrap(const PixelBarChart(dates: [], values: [], valueTexts: [])),
    );
    expect(find.text('Chưa có dữ liệu trong khoảng này.'), findsOneWidget);
  });

  testWidgets('PixelBarChart cắt về maxBars cuối', (tester) async {
    final dates = [
      for (var i = 0; i < 40; i++) DateTime(2026, 10, 1).add(Duration(days: i)),
    ];
    await tester.pumpWidget(
      _wrap(
        PixelBarChart(
          dates: dates,
          values: [for (var i = 0; i < 40; i++) 1000.0 * i],
          valueTexts: [for (var i = 0; i < 40; i++) '$i đ'],
          maxBars: 10,
        ),
      ),
    );
    expect(find.byKey(const ValueKey('bar-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('bar-9')), findsOneWidget);
    expect(find.byKey(const ValueKey('bar-10')), findsNothing);
  });
}
