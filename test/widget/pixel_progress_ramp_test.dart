import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixket/core/theme/app_palette.dart';
import 'package:pixket/core/theme/app_theme.dart';
import 'package:pixket/widgets/pixel/pixel_progress.dart';

Color _cellColor(WidgetTester tester, int index) => tester
    .widgetList<Container>(
      find.descendant(
        of: find.byType(PixelProgress),
        matching: find.byType(Container),
      ),
    )
    .elementAt(index)
    .color!;

void main() {
  testWidgets('tô theo bậc mức chi', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(body: PixelProgress(value: 0.3, segments: 4)),
      ),
    );
    expect(_cellColor(tester, 0), AppPalette.light.rampFill(0.3));
  });

  testWidgets('quá hạn mức chuyển rose và nhãn Vượt mức', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: PixelProgress(value: 1.2, segments: 4, showLabel: true),
        ),
      ),
    );
    expect(_cellColor(tester, 0), AppPalette.light.rose);
    expect(find.text('Vượt mức'), findsOneWidget);
    expect(find.text('120%'), findsNothing);
  });

  testWidgets('spendRamp false giữ màu cũ và fillColor vẫn thắng', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: PixelProgress(
            value: 0.3,
            segments: 4,
            spendRamp: false,
            fillColor: Color(0xFF123456),
          ),
        ),
      ),
    );
    expect(_cellColor(tester, 0), const Color(0xFF123456));
  });
}
