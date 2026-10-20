import 'dart:math' as math;

/// Percentage display: "50" for whole numbers, "57.5" otherwise.
String formatPercent(double value) {
  return value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(1);
}

/// Parses user input. Accepts a decimal comma, which is common in South African
/// locales. Returns 0 for empty or invalid input.
double parseDecimal(String input) {
  return double.tryParse(input.trim().replaceAll(',', '.')) ?? 0;
}

/// Keeps a percentage inside 0-100.
double clampPercent(double value) => math.min(100, math.max(0, value));

/// Keeps a progress fraction inside 0.0-1.0 as a double (num.clamp returns num).
double clampUnit(double value) => math.min(1.0, math.max(0.0, value));
