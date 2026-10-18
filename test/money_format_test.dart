import 'package:budget_buddy/utils/money_format.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Money formatting tests', () {
    test('formatPeso formats numbers with ₱ and 2 decimal digits', () {
      expect(formatPeso(35000), '₱35,000.00');
      expect(formatPeso(0), '₱0.00');
      expect(formatPeso(1234.5), '₱1,234.50');
      expect(formatPeso(-50), '-₱50.00');
    });

    test('stripCommas removes commas and whitespace', () {
      expect(stripCommas('35,000.00'), '35000.00');
      expect(stripCommas('  1,234,567.89  '), '1234567.89');
    });

    test('parsePeso parses formatted strings', () {
      expect(parsePeso('35,000.00'), 35000.00);
      expect(parsePeso('  1,234.56 '), 1234.56);
      expect(parsePeso(''), null);
      expect(parsePeso('abc'), null);
    });

    test('formatAmountForInput formats correctly', () {
      expect(formatAmountForInput(35000), '35,000');
      expect(formatAmountForInput(35000.5), '35,000.50');
      expect(formatAmountForInput(0), '');
    });
  });

  group('CommaNumberInputFormatter tests', () {
    const formatter = CommaNumberInputFormatter();

    test('adds commas while typing integers', () {
      const oldValue = TextEditingValue.empty;
      const newValue = TextEditingValue(
        text: '35000',
        selection: TextSelection.collapsed(offset: 5),
      );

      final result = formatter.formatEditUpdate(oldValue, newValue);
      expect(result.text, '35,000');
      expect(result.selection.end, 6);
    });

    test('allows single decimal point with up to 2 decimals', () {
      const oldValue = TextEditingValue(
        text: '35,000',
        selection: TextSelection.collapsed(offset: 6),
      );
      const newValue = TextEditingValue(
        text: '35,000.50',
        selection: TextSelection.collapsed(offset: 9),
      );

      final result = formatter.formatEditUpdate(oldValue, newValue);
      expect(result.text, '35,000.50');
    });

    test('rejects more than 2 decimal digits', () {
      const oldValue = TextEditingValue(
        text: '35,000.50',
        selection: TextSelection.collapsed(offset: 9),
      );
      const newValue = TextEditingValue(
        text: '35,000.509',
        selection: TextSelection.collapsed(offset: 10),
      );

      final result = formatter.formatEditUpdate(oldValue, newValue);
      expect(result.text, '35,000.50'); // rejected, returns oldValue
    });

    test('rejects non-numeric characters', () {
      const oldValue = TextEditingValue(
        text: '35,000',
        selection: TextSelection.collapsed(offset: 6),
      );
      const newValue = TextEditingValue(
        text: '35,000a',
        selection: TextSelection.collapsed(offset: 7),
      );

      final result = formatter.formatEditUpdate(oldValue, newValue);
      expect(result.text, '35,000'); // rejected
    });

    test('rejects multiple decimal points', () {
      const oldValue = TextEditingValue(
        text: '35,000.5',
        selection: TextSelection.collapsed(offset: 8),
      );
      const newValue = TextEditingValue(
        text: '35,000.5.',
        selection: TextSelection.collapsed(offset: 9),
      );

      final result = formatter.formatEditUpdate(oldValue, newValue);
      expect(result.text, '35,000.5'); // rejected
    });
  });
}
