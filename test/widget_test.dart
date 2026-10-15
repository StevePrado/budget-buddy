import 'package:budget_buddy/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the BudgetBuddy starter shell', (tester) async {
    await tester.pumpWidget(const BudgetBuddyApp());

    expect(find.text('BudgetBuddy — Expenses'), findsOneWidget);

    expect(find.text('Expense features will be added here.'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.pie_chart_outline));
    await tester.pumpAndSettle();

    expect(find.text('BudgetBuddy — Summary'), findsOneWidget);
  });
}
