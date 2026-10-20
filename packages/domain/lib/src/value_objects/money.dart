import 'package:meta/meta.dart';

import 'currency.dart';

export 'currency.dart';

class CurrencyMismatchException extends ArgumentError {
  CurrencyMismatchException(this.expectedCurrency, this.actualCurrency)
    : super(
        'Cannot perform monetary operation between incompatible currencies: '
        '$expectedCurrency and $actualCurrency.',
      );

  /// Expected currency code.
  final String expectedCurrency;

  /// Actual currency code encountered.
  final String actualCurrency;
}

/// Thrown when a monetary arithmetic operation causes integer overflow or underflow.
class MoneyOverflowException extends StateError {
  /// Creates a [MoneyOverflowException].
  MoneyOverflowException(super.message);
}

/// Defines the rounding policy for monetary division and rational multiplication.
enum RoundingMode {
  /// Rounds towards nearest neighbor; if equidistant, rounds away from zero.
  halfUp,

  /// Rounds towards nearest neighbor; if equidistant, rounds to nearest even number (Banker's rounding).
  halfEven,

  /// Rounds towards zero (truncation).
  down,

  /// Rounds away from zero.
  up,

  /// Rounds towards negative infinity.
  floor,

  /// Rounds towards positive infinity.
  ceiling,
}

@immutable
class Money implements Comparable<Money> {
  /// Internal const constructor for instantiating [Money].
  const Money._(this.subunits, this.currency);

  /// Creates a [Money] instance from [subunits] (minor units).
  ///
  /// For DZD, 100 subunits = 1.00 DZD.
  const Money.fromSubunits(int subunits, [Currency currency = Currency.dzd])
    : this._(subunits, currency);

  /// Default constructor creating [Money] from minor units ([subunits]).
  const factory Money(int subunits, [Currency currency]) = Money.fromSubunits;

  /// Convenience factory creating a zero amount in the specified [currency].
  factory Money.zero([Currency currency = Currency.dzd]) =>
      Money._(0, currency);

  factory Money.dzd(int dinars, [int centimes = 0]) {
    if (centimes < 0 || centimes >= 100) {
      throw ArgumentError.value(
        centimes,
        'centimes',
        'Centimes must be between 0 and 99 for DZD.',
      );
    }
    final dinarsBig = BigInt.from(dinars);
    final centimesBig = BigInt.from(centimes);
    final totalBig = dinars >= 0
        ? (dinarsBig * BigInt.from(100) + centimesBig)
        : -(dinarsBig.abs() * BigInt.from(100) + centimesBig);
    return Money.fromSubunits(
      _bigIntToIntWithOverflowCheck(totalBig),
      Currency.dzd,
    );
  }

  /// Creates a [Money] instance from [majorUnits] (e.g., whole Dinars).
  factory Money.fromMajorUnits(
    int majorUnits, [
    Currency currency = Currency.dzd,
  ]) {
    final majorBig = BigInt.from(majorUnits);
    final factorBig = BigInt.from(currency.subunitsPerUnit);
    final totalBig = majorBig * factorBig;
    return Money.fromSubunits(
      _bigIntToIntWithOverflowCheck(totalBig),
      currency,
    );
  }

  /// Parses a decimal string (e.g. `"150.50"`, `"-42.1"`) without floating-point arithmetic.
  ///
  /// Throws [ArgumentError] if fractional digits exceed currency precision or if input is empty.
  /// Throws [FormatException] if the string is not a valid decimal number.
  factory Money.fromDecimalString(
    String value, [
    Currency currency = Currency.dzd,
  ]) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(
        value,
        'value',
        'Decimal string cannot be empty.',
      );
    }

    final isNegative = trimmed.startsWith('-');
    final cleanStr = isNegative
        ? trimmed.substring(1).trim()
        : (trimmed.startsWith('+') ? trimmed.substring(1).trim() : trimmed);

    final parts = cleanStr.split('.');
    if (parts.length > 2) {
      throw FormatException('Invalid decimal number format: $value');
    }

    final majorStr = parts[0].isEmpty ? '0' : parts[0];
    if (!RegExp(r'^\d+$').hasMatch(majorStr)) {
      throw FormatException('Invalid integer part in monetary string: $value');
    }

    final majorUnits = BigInt.parse(majorStr);
    final minorStr = parts.length == 2 ? parts[1] : '';

    if (parts.length == 2 && !RegExp(r'^\d*$').hasMatch(minorStr)) {
      throw FormatException(
        'Invalid fractional part in monetary string: $value',
      );
    }

    if (minorStr.length > currency.decimalDigits) {
      throw ArgumentError.value(
        value,
        'value',
        'Fractional digits (${minorStr.length}) exceed currency ${currency.code} precision (${currency.decimalDigits}).',
      );
    }

    final paddedMinorStr = minorStr.padRight(currency.decimalDigits, '0');
    final minorUnits = paddedMinorStr.isEmpty
        ? BigInt.zero
        : BigInt.parse(paddedMinorStr);

    var totalSubunits =
        majorUnits * BigInt.from(currency.subunitsPerUnit) + minorUnits;
    if (isNegative) {
      totalSubunits = -totalSubunits;
    }

    return Money.fromSubunits(
      _bigIntToIntWithOverflowCheck(totalSubunits),
      currency,
    );
  }

  /// The amount in minor units (subunits/centimes).
  final int subunits;

  /// Alias for [subunits].
  int get minorUnits => subunits;

  /// The currency associated with this monetary amount.
  final Currency currency;

  /// Major unit component (e.g. Dinars for DZD).
  int get majorUnits =>
      (BigInt.from(subunits) ~/ BigInt.from(currency.subunitsPerUnit)).toInt();

  /// Fractional subunit remainder (0..subunitsPerUnit - 1).
  int get remainderSubunits => (BigInt.from(
    subunits,
  ).remainder(BigInt.from(currency.subunitsPerUnit))).abs().toInt();

  /// Whether the amount is zero.
  bool get isZero => subunits == 0;

  /// Whether the amount is strictly positive (> 0).
  bool get isPositive => subunits > 0;

  /// Whether the amount is strictly negative (< 0).
  bool get isNegative => subunits < 0;

  /// Returns the absolute value of this [Money].
  Money abs() {
    if (subunits >= 0) return this;
    return Money.fromSubunits(_negateWithOverflowCheck(subunits), currency);
  }

  /// Returns the negation of this [Money].
  Money operator -() {
    return Money.fromSubunits(_negateWithOverflowCheck(subunits), currency);
  }

  /// Adds [other] to this amount.
  ///
  /// Throws [CurrencyMismatchException] if currencies differ.
  /// Throws [MoneyOverflowException] if integer overflow occurs.
  Money operator +(Money other) {
    _assertMatchingCurrency(other);
    return Money.fromSubunits(
      _addWithOverflowCheck(subunits, other.subunits),
      currency,
    );
  }

  /// Subtracts [other] from this amount.
  ///
  /// Throws [CurrencyMismatchException] if currencies differ.
  /// Throws [MoneyOverflowException] if integer overflow occurs.
  Money operator -(Money other) {
    _assertMatchingCurrency(other);
    return Money.fromSubunits(
      _subtractWithOverflowCheck(subunits, other.subunits),
      currency,
    );
  }

  /// Multiplies this amount by an integer [quantity].
  ///
  /// Does not require rounding. Throws [MoneyOverflowException] if integer overflow occurs.
  Money operator *(int quantity) {
    return Money.fromSubunits(
      _multiplyWithOverflowCheck(subunits, quantity),
      currency,
    );
  }

  /// Alias for [operator *].
  Money multiplyByQuantity(int quantity) => this * quantity;

  /// Multiplies this amount by a rational factor ([numerator] / [denominator])
  /// using exact integer math and the specified [roundingMode].
  ///
  /// Throws [ArgumentError] if [denominator] is zero.
  /// Throws [MoneyOverflowException] if the resulting amount exceeds 64-bit integer limits.
  Money multiplyByRational(
    int numerator,
    int denominator, {
    RoundingMode roundingMode = RoundingMode.halfUp,
  }) {
    if (denominator == 0) {
      throw ArgumentError.value(
        denominator,
        'denominator',
        'Denominator cannot be zero.',
      );
    }
    final numBig = BigInt.from(subunits) * BigInt.from(numerator);
    final denBig = BigInt.from(denominator);
    final rounded = _roundDivisionBigInt(numBig, denBig, roundingMode);
    return Money.fromSubunits(_bigIntToIntWithOverflowCheck(rounded), currency);
  }

  /// Multiplies this amount by a fixed-point factor ([unscaledValue] * 10^-[scale])
  /// with explicit [roundingMode].
  ///
  /// Example: 1.25x factor has `unscaledValue = 125, scale = 2`.
  Money multiplyByFixedPoint(
    int unscaledValue,
    int scale, {
    RoundingMode roundingMode = RoundingMode.halfUp,
  }) {
    if (scale < 0) {
      throw ArgumentError.value(scale, 'scale', 'Scale cannot be negative.');
    }
    var den = BigInt.one;
    for (var i = 0; i < scale; i++) {
      den *= BigInt.from(10);
    }
    final numBig = BigInt.from(subunits) * BigInt.from(unscaledValue);
    final rounded = _roundDivisionBigInt(numBig, den, roundingMode);
    return Money.fromSubunits(_bigIntToIntWithOverflowCheck(rounded), currency);
  }

  /// Divides this amount by an integer [divisor] using explicit [roundingMode].
  ///
  /// Throws [ArgumentError] if [divisor] is zero.
  Money divide(int divisor, {RoundingMode roundingMode = RoundingMode.halfUp}) {
    return multiplyByRational(1, divisor, roundingMode: roundingMode);
  }

  /// Allocates this monetary amount across integer [ratios] without losing or creating subunits.
  ///
  /// ### Allocation Priority Policy
  /// 1. **Proportional Base Allocation**: Each bucket receives its proportional floor share:
  ///    `share_i = (totalSubunits * ratio_i) ~/ totalRatio`.
  /// 2. **Zero-Ratio Exclusion**: Buckets with a ratio of `0` receive exactly `0` subunits
  ///    and are strictly excluded from receiving any remainder units.
  /// 3. **Remainder Distribution**: Any non-divisible remainder (positive or negative)
  ///    is distributed one subunit at a time (`+1` or `-1`) across non-zero ratio buckets
  ///    in order of appearance (left-to-right, starting at index 0) until exhausted.
  ///
  /// Throws [ArgumentError] if [ratios] is empty, contains negative values, or sums to zero.
  List<Money> allocate(List<int> ratios) {
    if (ratios.isEmpty) {
      throw ArgumentError.value(
        ratios,
        'ratios',
        'Ratios list cannot be empty.',
      );
    }

    var totalRatio = BigInt.zero;
    final nonZeroIndices = <int>[];
    for (var i = 0; i < ratios.length; i++) {
      final ratio = ratios[i];
      if (ratio < 0) {
        throw ArgumentError.value(
          ratios,
          'ratios',
          'Ratio cannot be negative: $ratio at index $i.',
        );
      }
      if (ratio > 0) {
        nonZeroIndices.add(i);
      }
      totalRatio += BigInt.from(ratio);
    }

    if (totalRatio == BigInt.zero) {
      throw ArgumentError.value(
        ratios,
        'ratios',
        'Sum of ratios cannot be zero.',
      );
    }

    final totalSubunits = BigInt.from(subunits);
    var remainder = totalSubunits;
    final results = List<BigInt>.filled(ratios.length, BigInt.zero);

    for (var i = 0; i < ratios.length; i++) {
      final ratio = ratios[i];
      if (ratio > 0) {
        final share = (totalSubunits * BigInt.from(ratio)) ~/ totalRatio;
        results[i] = share;
        remainder -= share;
      }
    }

    final step = remainder < BigInt.zero ? -BigInt.one : BigInt.one;
    var nonZeroIdx = 0;
    while (remainder != BigInt.zero) {
      final targetBucket = nonZeroIndices[nonZeroIdx];
      results[targetBucket] += step;
      remainder -= step;
      nonZeroIdx = (nonZeroIdx + 1) % nonZeroIndices.length;
    }

    return results
        .map(
          (val) =>
              Money.fromSubunits(_bigIntToIntWithOverflowCheck(val), currency),
        )
        .toList();
  }

  @override
  int compareTo(Money other) {
    _assertMatchingCurrency(other);
    return subunits.compareTo(other.subunits);
  }

  /// Returns true if this amount is strictly less than [other].
  bool operator <(Money other) => compareTo(other) < 0;

  /// Returns true if this amount is less than or equal to [other].
  bool operator <=(Money other) => compareTo(other) <= 0;

  /// Returns true if this amount is strictly greater than [other].
  bool operator >(Money other) => compareTo(other) > 0;

  /// Returns true if this amount is greater than or equal to [other].
  bool operator >=(Money other) => compareTo(other) >= 0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Money &&
          other.currency == currency &&
          other.subunits == subunits);

  @override
  int get hashCode => Object.hash(subunits, currency);

  /// Formats this monetary amount into a human-readable decimal string.
  ///
  /// Safely handles the minimum 64-bit integer boundary (`_minInt`) without overflow.
  /// Example: `"150.50 DZD"` or `"150.50"` if [includeSymbol] is false.
  String format({bool includeSymbol = true}) {
    final absBig = BigInt.from(subunits).abs();
    final factorBig = BigInt.from(currency.subunitsPerUnit);
    final major = absBig ~/ factorBig;
    final minor = absBig % factorBig;
    final minorStr = minor.toString().padLeft(currency.decimalDigits, '0');
    final sign = subunits < 0 ? '-' : '';
    final amountStr = currency.decimalDigits > 0
        ? '$sign$major.$minorStr'
        : '$sign$major';
    if (!includeSymbol) return amountStr;
    return '$amountStr ${currency.code}';
  }

  @override
  String toString() => 'Money(${format()})';

  void _assertMatchingCurrency(Money other) {
    if (currency != other.currency) {
      throw CurrencyMismatchException(currency.code, other.currency.code);
    }
  }

  static const int _maxInt = 9223372036854775807;
  static const int _minInt = -9223372036854775808;

  static int _addWithOverflowCheck(int a, int b) {
    final sum = BigInt.from(a) + BigInt.from(b);
    if (sum < BigInt.from(_minInt) || sum > BigInt.from(_maxInt)) {
      throw MoneyOverflowException(
        'Addition overflow/underflow: $a + $b exceeds 64-bit integer limit.',
      );
    }
    return sum.toInt();
  }

  static int _subtractWithOverflowCheck(int a, int b) {
    final diff = BigInt.from(a) - BigInt.from(b);
    if (diff < BigInt.from(_minInt) || diff > BigInt.from(_maxInt)) {
      throw MoneyOverflowException(
        'Subtraction overflow/underflow: $a - $b exceeds 64-bit integer limit.',
      );
    }
    return diff.toInt();
  }

  static int _negateWithOverflowCheck(int a) {
    if (a == _minInt) {
      throw MoneyOverflowException(
        'Negation overflow: -($a) exceeds 64-bit integer limit.',
      );
    }
    return -a;
  }

  static int _multiplyWithOverflowCheck(int a, int b) {
    if (a == 0 || b == 0) return 0;
    final prod = BigInt.from(a) * BigInt.from(b);
    if (prod < BigInt.from(_minInt) || prod > BigInt.from(_maxInt)) {
      throw MoneyOverflowException(
        'Multiplication overflow/underflow: $a * $b exceeds 64-bit integer limit.',
      );
    }
    return prod.toInt();
  }

  static BigInt _roundDivisionBigInt(
    BigInt numerator,
    BigInt denominator,
    RoundingMode mode,
  ) {
    if (denominator == BigInt.zero) {
      throw ArgumentError('Denominator cannot be zero.');
    }
    if (denominator < BigInt.zero) {
      numerator = -numerator;
      denominator = -denominator;
    }

    final quotient = numerator ~/ denominator;
    final remainder = numerator.remainder(denominator);

    if (remainder == BigInt.zero) {
      return quotient;
    }

    final sign = numerator < BigInt.zero ? -1 : 1;
    final absRem = remainder.abs();
    final absQ = quotient.abs();
    final twoRem = absRem * BigInt.from(2);

    switch (mode) {
      case RoundingMode.down:
        return sign > 0 ? absQ : -absQ;
      case RoundingMode.up:
        return sign > 0 ? absQ + BigInt.one : -(absQ + BigInt.one);
      case RoundingMode.floor:
        return sign > 0 ? absQ : -(absQ + BigInt.one);
      case RoundingMode.ceiling:
        return sign > 0 ? absQ + BigInt.one : -absQ;
      case RoundingMode.halfUp:
        if (twoRem >= denominator) {
          return sign > 0 ? absQ + BigInt.one : -(absQ + BigInt.one);
        }
        return sign > 0 ? absQ : -absQ;
      case RoundingMode.halfEven:
        if (twoRem > denominator) {
          return sign > 0 ? absQ + BigInt.one : -(absQ + BigInt.one);
        } else if (twoRem < denominator) {
          return sign > 0 ? absQ : -absQ;
        } else {
          if (absQ.isOdd) {
            return sign > 0 ? absQ + BigInt.one : -(absQ + BigInt.one);
          }
          return sign > 0 ? absQ : -absQ;
        }
    }
  }

  static int _bigIntToIntWithOverflowCheck(BigInt value) {
    final minBig = BigInt.from(_minInt);
    final maxBig = BigInt.from(_maxInt);
    if (value < minBig || value > maxBig) {
      throw MoneyOverflowException(
        'Result $value exceeds 64-bit integer limit.',
      );
    }
    return value.toInt();
  }
}
