import 'package:meta/meta.dart';

@immutable
class Currency {
  static const int maxDecimalDigits = 18;

  const Currency._({
    required this.code,
    this.decimalDigits = 2,
    this.symbol = '',
  });

  static const Currency dzd = Currency._(
    code: 'DZD',
    decimalDigits: 2,
    symbol: 'DA',
  );

  static const Currency eur = Currency._(
    code: 'EUR',
    decimalDigits: 2,
    symbol: '€',
  );

  static const Currency usd = Currency._(
    code: 'USD',
    decimalDigits: 2,
    symbol: '\$',
  );

  factory Currency({
    required String code,
    int decimalDigits = 2,
    String symbol = '',
  }) {
    final trimmedCode = code.trim().toUpperCase();
    if (trimmedCode.isEmpty) {
      throw ArgumentError.value(code, 'code', 'Currency code cannot be empty.');
    }
    if (decimalDigits < 0 || decimalDigits > maxDecimalDigits) {
      throw ArgumentError.value(
        decimalDigits,
        'decimalDigits',
        'Currency decimalDigits must be between 0 and $maxDecimalDigits.',
      );
    }
    if (trimmedCode == 'DZD' && decimalDigits == 2) {
      return Currency.dzd;
    }
    return Currency._(
      code: trimmedCode,
      decimalDigits: decimalDigits,
      symbol: symbol.trim(),
    );
  }

  factory Currency.fromCode(
    String code, {
    int decimalDigits = 2,
    String? symbol,
  }) => Currency(
    code: code,
    decimalDigits: decimalDigits,
    symbol: symbol ?? code,
  );

  /// ISO 4217 3-letter currency code (e.g., 'DZD', 'EUR', 'USD').
  final String code;

  /// Number of decimal places for the minor unit (e.g., 2 for centimes/cents).
  final int decimalDigits;

  /// Display symbol (e.g., 'DA', '€', '$').
  final String symbol;

  int get subunitsPerUnit {
    var factor = 1;
    for (var i = 0; i < decimalDigits; i++) {
      factor *= 10;
    }
    return factor;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Currency &&
          code.toUpperCase() == other.code.toUpperCase() &&
          decimalDigits == other.decimalDigits);

  @override
  int get hashCode => Object.hash(code.toUpperCase(), decimalDigits);

  @override
  String toString() => code;
}
