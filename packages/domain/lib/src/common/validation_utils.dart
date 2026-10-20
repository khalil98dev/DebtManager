/// Reusable domain validation and string normalization utilities.
///
/// Keeps validation logic pure Dart, with no dependencies on Flutter,
/// UI, or persistence frameworks.
abstract final class ValidationUtils {
  /// Validates that [value] is non-empty after trimming, returning the trimmed string.
  ///
  /// Throws [ArgumentError] if [value] is empty or whitespace-only.
  static String validateAndTrimRequired(
    String value, {
    String name = 'value',
    String? message,
  }) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(
        value,
        name,
        message ?? '$name cannot be empty.',
      );
    }
    return trimmed;
  }

  /// Validates and trims an identifier or number string (such as an invoice number).
  ///
  /// Throws [ArgumentError] if [value] is empty or whitespace-only.
  static String validateAndTrimNumber(
    String value, {
    String name = 'number',
    String message = 'Invoice number cannot be empty.',
  }) => validateAndTrimRequired(value, name: name, message: message);

  /// Normalizes an optional string [value].
  ///
  /// Returns `null` if [value] is `null` or contains only whitespace.
  /// Otherwise, returns the trimmed string.
  static String? normalizeOptionalString(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
