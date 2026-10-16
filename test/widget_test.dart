import 'package:budget_buddy/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the BudgetBuddy starter shell', (tester) async {
    await tester.pumpWidget(const BudgetBuddyApp());

    // Verify initial Expenses tab
    expect(find.text('Expenses'), findsWidgets);

    // Tap on Summary tab
    await tester.tap(find.byIcon(Icons.pie_chart_outline_rounded));
    await tester.pumpAndSettle();

    // Verify Summary title
    expect(find.text('Coming soon: Teammates (Analytics & Charts)'), findsOneWidget);
  });
}
