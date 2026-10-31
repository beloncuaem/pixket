import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chi_tieu/core/utils/amount_input_formatter.dart';
import 'package:chi_tieu/core/utils/currency_formatter.dart';

void main() {
  Future<TextEditingController> pumpAmountField(
    WidgetTester tester, {
    String initial = '',
  }) async {
    final controller = TextEditingController(text: initial);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: const [ThousandsSeparatorInputFormatter()],
          ),
        ),
      ),
    );
    return controller;
  }

  testWidgets('typing 1500000 shows grouped digits', (tester) async {
    final controller = await pumpAmountField(tester);
    await tester.enterText(find.byType(TextField), '1500000');
    await tester.pump();
    expect(controller.text, '1.500.000');
  });

  testWidgets('existing value seeds grouped and still parses', (tester) async {
    final controller = await pumpAmountField(
      tester,
      initial: CurrencyFormatter.toEditableText(35000),
    );
    expect(controller.text, '35.000');
    expect(CurrencyFormatter.parseInput(controller.text), 35000);
  });

  testWidgets('empty field parses to null, not zero', (tester) async {
    final controller = await pumpAmountField(tester);
    await tester.enterText(find.byType(TextField), '');
    await tester.pump();
    expect(controller.text, '');
    expect(CurrencyFormatter.parseInput(controller.text), isNull);
  });
}
