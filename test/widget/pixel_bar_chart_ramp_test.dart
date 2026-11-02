import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixket/core/theme/app_palette.dart';
import 'package:pixket/core/theme/app_theme.dart';
import 'package:pixket/widgets/pixel/pixel_bar_chart.dart';

void main() {
  final dates = [DateTime(2026, 11, 1), DateTime(2026, 11, 2)];

  testWidgets('mỗi cột tô theo bậc của value/reference', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: PixelBarChart(
            dates: dates,
            values: const [10, 90],
            valueTexts: const ['10₫', '90₫'],
            reference: 100,
          ),
        ),
      ),
    );
    final containers = tester
        .widgetList<Container>(find.byType(Container))
        .where((c) => c.color != null)
        .map((c) => c.color)
        .toList();
    expect(containers, contains(AppPalette.light.rampFill(0.1)));
    expect(containers, contains(AppPalette.light.rampFill(0.9)));
  });

  testWidgets('không có reference thì giữ màu barColor', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: PixelBarChart(
            dates: dates,
            values: const [90],
            valueTexts: const ['90₫'],
            barColor: const Color(0xFF123456),
          ),
        ),
      ),
    );
    final containers = tester
        .widgetList<Container>(find.byType(Container))
        .where((c) => c.color != null)
        .map((c) => c.color)
        .toList();
    expect(containers, contains(const Color(0xFF123456)));
  });

  testWidgets('tooltip kèm nhãn bậc mức chi', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: PixelBarChart(
            dates: dates,
            values: const [90],
            valueTexts: const ['90₫'],
            reference: 100,
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('bar-0')));
    await tester.pump();
    expect(find.textContaining('Vượt mức'), findsOneWidget);
  });
}
