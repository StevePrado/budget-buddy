// Small helpers for showing and reading Philippine Peso amounts.

/// 12345.5 -> ₱12,345.50   (negative values -> -₱12,345.50)
String peso(num value) {
  final fixed = value.abs().toStringAsFixed(2);
  final parts = fixed.split('.');
  final whole = parts[0].replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (match) => ',',
  );
  final sign = value < 0 ? '-' : '';
  return '$sign₱$whole.${parts[1]}';
}

/// "1,250.50" -> 1250.5, empty or invalid text -> null
double? parseAmount(String text) {
  final cleaned = text.replaceAll(',', '').trim();
  if (cleaned.isEmpty) return null;
  return double.tryParse(cleaned);
}

/// 150.0 -> "150", 150.5 -> "150.50" (for filling text fields)
String plainAmount(double value) {
  if (value <= 0) return '';
  return value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(2);
}
