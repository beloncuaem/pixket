import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pixket/core/theme/app_theme.dart';
import 'package:pixket/widgets/pixel/pixel_bar_chart.dart';
import 'package:pixket/widgets/pixel/pixel_pie_chart.dart';
import 'package:pixket/widgets/pixel/pixel_share_row.dart';

Widget _wrap(Widget child) => MaterialApp(
  theme: AppTheme.light,
  home: Scaffold(
    body: SizedBox(width: 380, child: SingleChildScrollView(child: child)),
  ),
);

const _slices = [
  PixelPieSlice(
    label: 'Ăn uống',
    value: 500000,
    valueText: '500.000 đ',
    color: Color(0xFFFF6B6B),
  ),
  PixelPieSlice(
    label: 'Đi lại',
    value: 250000,
    valueText: '250.000 đ',
    color: Color(0xFF6FB7FF),
  ),
];

void main() {
  testWidgets('PixelPieChart vẽ tròn và không ném lỗi', (tester) async {
    await tester.pumpWidget(
      _wrap(const Center(child: PixelPieChart(slices: _slices))),
    );
    final pie = find.byKey(const ValueKey('pixel-pie'));
    expect(pie, findsOneWidget);
    expect(tester.getSize(pie), const Size(132, 132));
    expect(tester.takeException(), isNull);
  });

  testWidgets('PixelPieChart total = 0 không chia cho 0', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const PixelPieChart(
          slices: [
            PixelPieSlice(
              label: 'Khác',
              value: 0,
              valueText: '0 đ',
              color: Color(0xFF6FB7FF),
            ),
          ],
        ),
      ),
    );
    expect(find.byKey(const ValueKey('pixel-pie')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('pixelPieSemantics tóm tắt từng lát kèm % và số tiền', () {
    final label = pixelPieSemantics(_slices, 750000);
    expect(label, contains('Ăn uống 67% 500.000 đ'));
    expect(label, contains('Đi lại 33% 250.000 đ'));
    expect(pixelPieSemantics(const [], 0), isEmpty);
  });

  testWidgets('PixelShareRow hiện nhãn, % và số tiền', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const PixelShareRow(
          label: 'Ăn uống',
          color: Color(0xFFFF6B6B),
          value: 500000,
          total: 1000000,
          valueText: '500.000 đ',
        ),
      ),
    );
    expect(find.text('Ăn uống'), findsOneWidget);
    expect(find.text('50%'), findsOneWidget);
    expect(find.text('500.000 đ'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('PixelShareRow total = 0 thì hiện 0%', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const PixelShareRow(
          label: 'Khác',
          color: Color(0xFF6FB7FF),
          value: 0,
          total: 0,
          valueText: '0 đ',
        ),
      ),
    );
    expect(find.text('0%'), findsOneWidget);
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
    // Số tiền rút gọn và ngày in ngay trên cột, không cần chạm.
    expect(find.text('10 K'), findsOneWidget);
    expect(find.text('20 K'), findsOneWidget);
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
