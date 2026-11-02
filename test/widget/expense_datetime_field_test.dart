import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixket/core/theme/app_theme.dart';
import 'package:pixket/screens/camera/expense_datetime_field.dart';

void main() {
  DateTime? captured;
  final fixed = DateTime(2026, 5, 20, 8, 5);

  Future<void> pump(WidgetTester tester) async {
    captured = null;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: ExpenseDateTimeField(
            value: fixed,
            maxNow: DateTime(2026, 10, 26, 14, 30),
            onChanged: (v) => captured = v,
          ),
        ),
      ),
    );
  }

  testWidgets('shows the stored date and time', (tester) async {
    await pump(tester);
    expect(find.text('20/05/2026'), findsOneWidget);
    expect(find.text('08:05'), findsOneWidget);
    expect(find.text('Bây giờ'), findsOneWidget);
  });

  testWidgets('Bây giờ emits a clamped timestamp', (tester) async {
    await pump(tester);
    await tester.tap(find.text('Bây giờ'));
    await tester.pump();
    expect(captured, DateTime(2026, 10, 26, 14, 30));
  });

  testWidgets('date and time are separate tap targets of at least 48dp', (
    tester,
  ) async {
    await pump(tester);
    expect(find.byType(OutlinedButton), findsNWidgets(2));
    for (final button in tester.widgetList<OutlinedButton>(
      find.byType(OutlinedButton),
    )) {
      final size = tester.getSize(find.byWidget(button));
      expect(size.height, greaterThanOrEqualTo(48));
    }
    expect(tester.getSize(find.text('Bây giờ')).height, greaterThan(0));
  });
}
