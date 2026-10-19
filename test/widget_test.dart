import 'package:budget_buddy/utils/money_format.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('CommaNumberInputFormatter formats text input in widget tree',
      (tester) async {
    final controller = TextEditingController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TextFormField(
            controller: controller,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: const [CommaNumberInputFormatter()],
          ),
        ),
      ),
    );

    // Enter numbers without commas
    await tester.enterText(find.byType(TextFormField), '35000');
    await tester.pump();

    // Verify it formatted with commas
    expect(controller.text, '35,000');

    // Add decimal point and decimals
    await tester.enterText(find.byType(TextFormField), '35000.50');
    await tester.pump();

    expect(controller.text, '35,000.50');
  });
}
