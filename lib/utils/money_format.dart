import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Standard currency formatter for Philippine Peso (₱)
/// Example: 35000 -> ₱35,000.00
String formatPeso(num v) =>
    NumberFormat.currency(symbol: '₱', decimalDigits: 2).format(v);

/// Formats spending amounts with a negative sign and comma formatting
/// Example: 1250 -> -₱1,250.00
String formatSpent(num v) => '-${formatPeso(v.abs())}';

/// Strips commas and whitespace from an amount string
String stripCommas(String text) => text.replaceAll(',', '').trim();

/// Parses an amount string that may contain commas into a double
double? parsePeso(String? text) {
  if (text == null) return null;
  final cleaned = stripCommas(text);
  if (cleaned.isEmpty) return null;
  return double.tryParse(cleaned);
}

/// Formats a numeric value for text editing fields with commas and optional decimals
String formatAmountForInput(num v) {
  if (v == 0) return '';
  final hasDecimals = (v % 1) != 0;
  if (hasDecimals) {
    return NumberFormat('#,##0.00').format(v);
  } else {
    return NumberFormat('#,##0').format(v);
  }
}

/// A TextInputFormatter that formats numbers with commas while typing.
/// Allows only digits and at most one decimal point with up to 2 decimal places.
class CommaNumberInputFormatter extends TextInputFormatter {
  const CommaNumberInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    String newText = newValue.text;
    int selectionEnd = newValue.selection.end;

    // Handle backspace when cursor was directly after a comma
    if (oldValue.text.length > newValue.text.length &&
        oldValue.selection.isCollapsed &&
        oldValue.selection.end > 0 &&
        oldValue.text[oldValue.selection.end - 1] == ',' &&
        oldValue.selection.end - 1 < oldValue.text.length) {
      // The user hit backspace on a comma, delete the digit before the comma instead
      final deleteIndex = oldValue.selection.end - 2;
      if (deleteIndex >= 0) {
        newText = oldValue.text.substring(0, deleteIndex) +
            oldValue.text.substring(oldValue.selection.end);
        selectionEnd = deleteIndex;
      }
    }

    // Strip commas for raw numeric validation
    final rawClean = newText.replaceAll(',', '');

    // Allow only digits and at most one decimal point, with max 2 decimals
    final regExp = RegExp(r'^\d*\.?\d{0,2}$');
    if (!regExp.hasMatch(rawClean)) {
      return oldValue;
    }

    final parts = rawClean.split('.');
    final integerPart = parts[0];
    final decimalPart = parts.length > 1 ? parts[1] : null;

    // Format integer part with thousands commas
    final formattedInt = integerPart.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ',',
    );

    final formatted =
        decimalPart != null ? '$formattedInt.$decimalPart' : formattedInt;

    // Compute new cursor position based on non-comma count
    int nonCommaCharsBeforeCursor = 0;
    final safeEnd = selectionEnd.clamp(0, newText.length);
    for (int i = 0; i < safeEnd; i++) {
      if (newText[i] != ',') {
        nonCommaCharsBeforeCursor++;
      }
    }

    int newCursorPos = 0;
    int nonCommaCount = 0;
    while (newCursorPos < formatted.length &&
        nonCommaCount < nonCommaCharsBeforeCursor) {
      if (formatted[newCursorPos] != ',') {
        nonCommaCount++;
      }
      newCursorPos++;
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: newCursorPos),
    );
  }
}
