import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const maxInt = 9223372036854775807;
  const minInt = -9223372036854775808;

  group('Currency', () {
    test('DZD has 2 decimal digits and code DZD', () {
      expect(Currency.dzd.code, 'DZD');
      expect(Currency.dzd.decimalDigits, 2);
      expect(Currency.dzd.symbol, 'DA');
      expect(Currency.dzd.subunitsPerUnit, 100);
    });

    test('validates decimalDigits bounds at runtime', () {
      // Valid boundaries: 0 and 18
      final jpy = Currency(code: 'JPY', decimalDigits: 0);
      expect(jpy.subunitsPerUnit, 1);

      final btc = Currency(code: 'BTC', decimalDigits: 8);
      expect(btc.subunitsPerUnit, 100000000);

      final maxPrecision = Currency(code: 'MAX', decimalDigits: 18);
      expect(maxPrecision.subunitsPerUnit, 1000000000000000000);

      // Invalid boundaries: negative or exceeding 18
      expect(
        () => Currency(code: 'INVALID', decimalDigits: -1),
        throwsArgumentError,
      );
      expect(
        () => Currency(code: 'INVALID', decimalDigits: 19),
        throwsArgumentError,
      );
      expect(
        () => Currency.fromCode('INVALID', decimalDigits: -5),
        throwsArgumentError,
      );
      expect(
        () => Currency.fromCode('INVALID', decimalDigits: 25),
        throwsArgumentError,
      );
    });

    test('fromCode normalizes code to uppercase and caches DZD', () {
      final dzd = Currency.fromCode('dzd');
      expect(identical(dzd, Currency.dzd), isTrue);

      final eur = Currency.fromCode('eur', decimalDigits: 2, symbol: '€');
      expect(eur.code, 'EUR');
      expect(eur.decimalDigits, 2);
      expect(eur.symbol, '€');
      expect(eur.subunitsPerUnit, 100);
    });

    test('rejects empty or whitespace-only code', () {
      expect(() => Currency(code: ''), throwsArgumentError);
      expect(() => Currency(code: '   '), throwsArgumentError);
      expect(() => Currency.fromCode(''), throwsArgumentError);
      expect(() => Currency.fromCode('   '), throwsArgumentError);
    });

    test('equality and hashCode', () {
      final c1 = Currency.fromCode('usd', decimalDigits: 2);
      final c2 = Currency.fromCode('USD', decimalDigits: 2);
      final c3 = Currency.fromCode('EUR', decimalDigits: 2);

      expect(c1, equals(c2));
      expect(c1.hashCode, equals(c2.hashCode));
      expect(c1, isNot(equals(c3)));
    });
  });

  group('Money - Construction and Precision', () {
    test('stores amounts as integers in minor units (centimes)', () {
      final m1 = Money.dzd(150, 50);
      expect(m1.subunits, 15050);
      expect(m1.minorUnits, 15050);
      expect(m1.majorUnits, 150);
      expect(m1.remainderSubunits, 50);
      expect(m1.currency, Currency.dzd);

      final m2 = Money.dzd(100);
      expect(m2.subunits, 10000);
      expect(m2.majorUnits, 100);
      expect(m2.remainderSubunits, 0);

      final m3 = Money.fromSubunits(5432, Currency.dzd);
      expect(m3.subunits, 5432);
      expect(m3.majorUnits, 54);
      expect(m3.remainderSubunits, 32);

      final mZero = Money.zero();
      expect(mZero.subunits, 0);
      expect(mZero.isZero, isTrue);
    });

    test('handles negative amounts correctly', () {
      final neg = Money.dzd(-150, 50);
      expect(neg.subunits, -15050);
      expect(neg.majorUnits, -150);
      expect(neg.remainderSubunits, 50);
      expect(neg.isNegative, isTrue);
      expect(neg.isPositive, isFalse);

      final pos = neg.abs();
      expect(pos.subunits, 15050);
      expect(pos.isPositive, isTrue);

      final smallNeg = Money.fromSubunits(-5, Currency.dzd);
      expect(smallNeg.subunits, -5);
      expect(smallNeg.majorUnits, 0);
      expect(smallNeg.remainderSubunits, 5);
      expect(smallNeg.format(), '-0.05 DZD');

      final negExactDinar = Money.dzd(-10, 0);
      expect(negExactDinar.subunits, -1000);
      expect(negExactDinar.majorUnits, -10);
      expect(negExactDinar.remainderSubunits, 0);
    });

    test('fromMajorUnits converts major units to subunits without double', () {
      final m = Money.fromMajorUnits(250, Currency.dzd);
      expect(m.subunits, 25000);

      final neg = Money.fromMajorUnits(-75, Currency.dzd);
      expect(neg.subunits, -7500);
    });

    test('dzd constructor rejects invalid centimes', () {
      expect(() => Money.dzd(10, -1), throwsArgumentError);
      expect(() => Money.dzd(10, 100), throwsArgumentError);
      expect(() => Money.dzd(10, 250), throwsArgumentError);
    });
  });

  group('Money - Decimal String Parsing', () {
    test(
      'parses valid positive and negative strings without double arithmetic',
      () {
        expect(Money.fromDecimalString('150.50').subunits, 15050);
        expect(Money.fromDecimalString('150.5').subunits, 15050);
        expect(Money.fromDecimalString('150').subunits, 15000);
        expect(Money.fromDecimalString('150.00').subunits, 15000);
        expect(Money.fromDecimalString('+150.50').subunits, 15050);
        expect(Money.fromDecimalString('  150.50  ').subunits, 15050);
        expect(Money.fromDecimalString('-42.1').subunits, -4210);
        expect(Money.fromDecimalString('0.05').subunits, 5);
        expect(Money.fromDecimalString('-0.05').subunits, -5);
        expect(Money.fromDecimalString('.99').subunits, 99);
        expect(Money.fromDecimalString('-.99').subunits, -99);
        expect(Money.fromDecimalString('0').subunits, 0);
        expect(Money.fromDecimalString('0.00').subunits, 0);
      },
    );

    test('parses at integer boundaries safely', () {
      // 92233720368547758.07 DZD = maxInt subunits
      final maxMoney = Money.fromDecimalString('92233720368547758.07');
      expect(maxMoney.subunits, maxInt);

      // -92233720368547758.08 DZD = minInt subunits
      final minMoney = Money.fromDecimalString('-92233720368547758.08');
      expect(minMoney.subunits, minInt);

      // One centime beyond maxInt throws MoneyOverflowException
      expect(
        () => Money.fromDecimalString('92233720368547758.08'),
        throwsA(isA<MoneyOverflowException>()),
      );

      // One centime below minInt throws MoneyOverflowException
      expect(
        () => Money.fromDecimalString('-92233720368547758.09'),
        throwsA(isA<MoneyOverflowException>()),
      );
    });

    test('rejects malformed and invalid strings', () {
      expect(() => Money.fromDecimalString(''), throwsArgumentError);
      expect(() => Money.fromDecimalString('   '), throwsArgumentError);
      expect(() => Money.fromDecimalString('abc'), throwsFormatException);
      expect(() => Money.fromDecimalString('12.34.56'), throwsFormatException);
      expect(() => Money.fromDecimalString('--12.34'), throwsFormatException);
      expect(() => Money.fromDecimalString('+-12.34'), throwsFormatException);
      expect(
        () => Money.fromDecimalString('150.123', Currency.dzd),
        throwsArgumentError,
      );
    });
  });

  group('Money - Equality, Hashing, and Comparison', () {
    final eur = Currency.fromCode('EUR', decimalDigits: 2);

    test('equality and hashCode based on subunits and currency', () {
      final m1 = Money.dzd(100, 50);
      final m2 = Money.fromSubunits(10050, Currency.dzd);
      final m3 = Money.dzd(100, 51);
      final mEur = Money.fromSubunits(10050, eur);

      expect(m1, equals(m2));
      expect(m1.hashCode, equals(m2.hashCode));

      expect(m1, isNot(equals(m3)));
      expect(m1, isNot(equals(mEur)));
    });

    test('comparison operators work with same currency', () {
      final m1 = Money.dzd(10);
      final m2 = Money.dzd(20);
      final m3 = Money.dzd(20);

      expect(m1 < m2, isTrue);
      expect(m1 <= m2, isTrue);
      expect(m2 > m1, isTrue);
      expect(m2 >= m1, isTrue);
      expect(m2 <= m3, isTrue);
      expect(m2 >= m3, isTrue);
      expect(m1.compareTo(m2), -1);
      expect(m2.compareTo(m1), 1);
      expect(m2.compareTo(m3), 0);
    });

    test(
      'comparison rejects incompatible currencies with CurrencyMismatchException',
      () {
        final dzd = Money.dzd(10);
        final eurMoney = Money.fromSubunits(1000, eur);

        expect(() => dzd < eurMoney, throwsA(isA<CurrencyMismatchException>()));
        expect(
          () => dzd <= eurMoney,
          throwsA(isA<CurrencyMismatchException>()),
        );
        expect(() => dzd > eurMoney, throwsA(isA<CurrencyMismatchException>()));
        expect(
          () => dzd >= eurMoney,
          throwsA(isA<CurrencyMismatchException>()),
        );
        expect(
          () => dzd.compareTo(eurMoney),
          throwsA(isA<CurrencyMismatchException>()),
        );
      },
    );
  });

  group('Money - Arithmetic and Currency Mismatch', () {
    final eur = Currency.fromCode('EUR', decimalDigits: 2);

    test('addition and subtraction with same currency', () {
      final m1 = Money.dzd(100, 50);
      final m2 = Money.dzd(50, 25);

      final sum = m1 + m2;
      expect(sum.subunits, 15075);
      expect(sum.majorUnits, 150);
      expect(sum.remainderSubunits, 75);

      final diff = m1 - m2;
      expect(diff.subunits, 5025);
      expect(diff.majorUnits, 50);
      expect(diff.remainderSubunits, 25);

      final negativeDiff = m2 - m1;
      expect(negativeDiff.subunits, -5025);
      expect(negativeDiff.isNegative, isTrue);
    });

    test('unary negation', () {
      final m = Money.dzd(100, 50);
      final neg = -m;
      expect(neg.subunits, -10050);
      expect(-neg, equals(m));
    });

    test('rejects addition and subtraction with different currencies', () {
      final dzd = Money.dzd(100);
      final eurMoney = Money.fromSubunits(10000, eur);

      expect(
        () => dzd + eurMoney,
        throwsA(
          isA<CurrencyMismatchException>()
              .having((e) => e.expectedCurrency, 'expectedCurrency', 'DZD')
              .having((e) => e.actualCurrency, 'actualCurrency', 'EUR'),
        ),
      );

      expect(() => dzd - eurMoney, throwsA(isA<CurrencyMismatchException>()));
    });
  });

  group('Money - Overflow Protection Boundaries', () {
    test('addition overflow and underflow throw MoneyOverflowException', () {
      final maxMoney = Money.fromSubunits(maxInt);
      final minMoney = Money.fromSubunits(minInt);

      expect(
        () => maxMoney + Money.fromSubunits(1),
        throwsA(isA<MoneyOverflowException>()),
      );
      expect(() => maxMoney + maxMoney, throwsA(isA<MoneyOverflowException>()));

      expect(
        () => minMoney + Money.fromSubunits(-1),
        throwsA(isA<MoneyOverflowException>()),
      );
      expect(() => minMoney + minMoney, throwsA(isA<MoneyOverflowException>()));
    });

    test('subtraction overflow and underflow throw MoneyOverflowException', () {
      final maxMoney = Money.fromSubunits(maxInt);
      final minMoney = Money.fromSubunits(minInt);

      expect(
        () => minMoney - Money.fromSubunits(1),
        throwsA(isA<MoneyOverflowException>()),
      );

      expect(
        () => maxMoney - Money.fromSubunits(-1),
        throwsA(isA<MoneyOverflowException>()),
      );
    });

    test(
      'negation and abs overflow at minInt throw MoneyOverflowException',
      () {
        final minMoney = Money.fromSubunits(minInt);
        expect(() => -minMoney, throwsA(isA<MoneyOverflowException>()));
        expect(() => minMoney.abs(), throwsA(isA<MoneyOverflowException>()));
      },
    );

    test(
      'multiplication overflow at boundaries throw MoneyOverflowException',
      () {
        final largeMoney = Money.fromSubunits(maxInt ~/ 2 + 1);
        // (maxInt ~/ 2 + 1) * -2 lands exactly on minInt without overflowing
        expect((largeMoney * -2).subunits, minInt);
        // Multiplying by -3 exceeds minInt
        expect(() => largeMoney * -3, throwsA(isA<MoneyOverflowException>()));
        // Exceeding by 1 subunit: (maxInt ~/ 2 + 2) * -2 overflows minInt
        expect(
          () => Money.fromSubunits(maxInt ~/ 2 + 2) * -2,
          throwsA(isA<MoneyOverflowException>()),
        );
        final largeNeg = Money.fromSubunits(minInt ~/ 2 - 1);
        expect(() => largeNeg * 2, throwsA(isA<MoneyOverflowException>()));

        final minMoney = Money.fromSubunits(minInt);
        expect(() => minMoney * -1, throwsA(isA<MoneyOverflowException>()));

        final maxMoney = Money.fromSubunits(maxInt);
        expect(
          () => maxMoney.multiplyByRational(2, 1),
          throwsA(isA<MoneyOverflowException>()),
        );

        expect(
          () => Money.fromMajorUnits(maxInt ~/ 50),
          throwsA(isA<MoneyOverflowException>()),
        );
        expect(
          () => Money.dzd(maxInt ~/ 50),
          throwsA(isA<MoneyOverflowException>()),
        );
      },
    );
  });

  group('Money - Rounding Modes and Rational Arithmetic', () {
    test('exact division by zero throws ArgumentError', () {
      final amount = Money.dzd(100);
      expect(() => amount.divide(0), throwsArgumentError);
      expect(() => amount.multiplyByRational(1, 0), throwsArgumentError);
      expect(() => amount.multiplyByFixedPoint(1, -1), throwsArgumentError);
    });

    test('exact division requires no rounding across all modes', () {
      // 10 subunits * 1/2 = 5 subunits (exact)
      final m10 = Money.fromSubunits(10);
      for (final mode in RoundingMode.values) {
        expect(
          m10.multiplyByRational(1, 2, roundingMode: mode).subunits,
          5,
          reason: 'Failed for mode $mode',
        );
      }
    });

    test('all 6 rounding modes on positive exact tie (2.5)', () {
      // 5 subunits * 1/2 = 2.5 subunits
      final m5 = Money.fromSubunits(5);
      expect(
        m5.multiplyByRational(1, 2, roundingMode: RoundingMode.halfUp).subunits,
        3,
      );
      expect(
        m5
            .multiplyByRational(1, 2, roundingMode: RoundingMode.halfEven)
            .subunits,
        2,
      ); // 2 is even
      expect(
        m5.multiplyByRational(1, 2, roundingMode: RoundingMode.down).subunits,
        2,
      );
      expect(
        m5.multiplyByRational(1, 2, roundingMode: RoundingMode.up).subunits,
        3,
      );
      expect(
        m5.multiplyByRational(1, 2, roundingMode: RoundingMode.floor).subunits,
        2,
      );
      expect(
        m5
            .multiplyByRational(1, 2, roundingMode: RoundingMode.ceiling)
            .subunits,
        3,
      );
    });

    test('all 6 rounding modes on positive exact tie with odd floor (3.5)', () {
      // 7 subunits * 1/2 = 3.5 subunits
      final m7 = Money.fromSubunits(7);
      expect(
        m7.multiplyByRational(1, 2, roundingMode: RoundingMode.halfUp).subunits,
        4,
      );
      expect(
        m7
            .multiplyByRational(1, 2, roundingMode: RoundingMode.halfEven)
            .subunits,
        4,
      ); // 4 is even
      expect(
        m7.multiplyByRational(1, 2, roundingMode: RoundingMode.down).subunits,
        3,
      );
      expect(
        m7.multiplyByRational(1, 2, roundingMode: RoundingMode.up).subunits,
        4,
      );
      expect(
        m7.multiplyByRational(1, 2, roundingMode: RoundingMode.floor).subunits,
        3,
      );
      expect(
        m7
            .multiplyByRational(1, 2, roundingMode: RoundingMode.ceiling)
            .subunits,
        4,
      );
    });

    test('all 6 rounding modes on negative exact tie (-2.5)', () {
      // -5 subunits * 1/2 = -2.5 subunits
      final mNeg5 = Money.fromSubunits(-5);
      expect(
        mNeg5
            .multiplyByRational(1, 2, roundingMode: RoundingMode.halfUp)
            .subunits,
        -3,
      );
      expect(
        mNeg5
            .multiplyByRational(1, 2, roundingMode: RoundingMode.halfEven)
            .subunits,
        -2,
      ); // -2 is even
      expect(
        mNeg5
            .multiplyByRational(1, 2, roundingMode: RoundingMode.down)
            .subunits,
        -2,
      );
      expect(
        mNeg5.multiplyByRational(1, 2, roundingMode: RoundingMode.up).subunits,
        -3,
      );
      expect(
        mNeg5
            .multiplyByRational(1, 2, roundingMode: RoundingMode.floor)
            .subunits,
        -3,
      );
      expect(
        mNeg5
            .multiplyByRational(1, 2, roundingMode: RoundingMode.ceiling)
            .subunits,
        -2,
      );
    });

    test(
      'all 6 rounding modes on negative exact tie with odd floor (-3.5)',
      () {
        // -7 subunits * 1/2 = -3.5 subunits
        final mNeg7 = Money.fromSubunits(-7);
        expect(
          mNeg7
              .multiplyByRational(1, 2, roundingMode: RoundingMode.halfUp)
              .subunits,
          -4,
        );
        expect(
          mNeg7
              .multiplyByRational(1, 2, roundingMode: RoundingMode.halfEven)
              .subunits,
          -4,
        ); // -4 is even
        expect(
          mNeg7
              .multiplyByRational(1, 2, roundingMode: RoundingMode.down)
              .subunits,
          -3,
        );
        expect(
          mNeg7
              .multiplyByRational(1, 2, roundingMode: RoundingMode.up)
              .subunits,
          -4,
        );
        expect(
          mNeg7
              .multiplyByRational(1, 2, roundingMode: RoundingMode.floor)
              .subunits,
          -4,
        );
        expect(
          mNeg7
              .multiplyByRational(1, 2, roundingMode: RoundingMode.ceiling)
              .subunits,
          -3,
        );
      },
    );

    test('non-tie fractional rounding (2.4 and -2.4)', () {
      // 12 subunits * 1/5 = 2.4 subunits
      final m12 = Money.fromSubunits(12);
      expect(
        m12
            .multiplyByRational(1, 5, roundingMode: RoundingMode.halfUp)
            .subunits,
        2,
      );
      expect(
        m12
            .multiplyByRational(1, 5, roundingMode: RoundingMode.halfEven)
            .subunits,
        2,
      );
      expect(
        m12.multiplyByRational(1, 5, roundingMode: RoundingMode.down).subunits,
        2,
      );
      expect(
        m12.multiplyByRational(1, 5, roundingMode: RoundingMode.up).subunits,
        3,
      );
      expect(
        m12.multiplyByRational(1, 5, roundingMode: RoundingMode.floor).subunits,
        2,
      );
      expect(
        m12
            .multiplyByRational(1, 5, roundingMode: RoundingMode.ceiling)
            .subunits,
        3,
      );

      // -12 subunits * 1/5 = -2.4 subunits
      final mNeg12 = Money.fromSubunits(-12);
      expect(
        mNeg12
            .multiplyByRational(1, 5, roundingMode: RoundingMode.halfUp)
            .subunits,
        -2,
      );
      expect(
        mNeg12
            .multiplyByRational(1, 5, roundingMode: RoundingMode.halfEven)
            .subunits,
        -2,
      );
      expect(
        mNeg12
            .multiplyByRational(1, 5, roundingMode: RoundingMode.down)
            .subunits,
        -2,
      );
      expect(
        mNeg12.multiplyByRational(1, 5, roundingMode: RoundingMode.up).subunits,
        -3,
      );
      expect(
        mNeg12
            .multiplyByRational(1, 5, roundingMode: RoundingMode.floor)
            .subunits,
        -3,
      );
      expect(
        mNeg12
            .multiplyByRational(1, 5, roundingMode: RoundingMode.ceiling)
            .subunits,
        -2,
      );
    });

    test('fixed-point multiplication', () {
      final price = Money.dzd(100); // 10000 subunits
      final taxed = price.multiplyByFixedPoint(125, 2);
      expect(taxed.subunits, 12500);
      expect(taxed.majorUnits, 125);
    });
  });

  group('Money - Allocation and Zero-Ratio Priority Policy', () {
    test('zero-ratio buckets never receive remainder units', () {
      // 5 subunits split across ratios [0, 1, 1]
      // Base shares: bucket 0 = 0, bucket 1 = 2, bucket 2 = 2. Remainder = 1.
      // Priority policy distributes remainder 1 to bucket 1 (first non-zero bucket).
      final amount = Money.fromSubunits(5);
      final parts1 = amount.allocate([0, 1, 1]);
      expect(parts1[0].subunits, 0); // Must be strictly 0
      expect(parts1[1].subunits, 3);
      expect(parts1[2].subunits, 2);
      expect(parts1[0] + parts1[1] + parts1[2], equals(amount));

      // Middle zero ratio: [1, 0, 1]
      final parts2 = amount.allocate([1, 0, 1]);
      expect(parts2[0].subunits, 3);
      expect(parts2[1].subunits, 0); // Must be strictly 0
      expect(parts2[2].subunits, 2);
      expect(parts2[0] + parts2[1] + parts2[2], equals(amount));

      // Leading zero ratios: [0, 0, 1]
      final parts3 = amount.allocate([0, 0, 1]);
      expect(parts3[0].subunits, 0);
      expect(parts3[1].subunits, 0);
      expect(parts3[2].subunits, 5);
      expect(parts3[0] + parts3[1] + parts3[2], equals(amount));
    });

    test('negative subunits allocation with zero ratios', () {
      final negAmount = Money.fromSubunits(-5);
      final parts = negAmount.allocate([0, 1, 1]);
      expect(parts[0].subunits, 0); // Must be strictly 0
      expect(parts[1].subunits, -3);
      expect(parts[2].subunits, -2);
      expect(parts[0] + parts[1] + parts[2], equals(negAmount));
    });

    test('distributes remainder in priority order from left to right', () {
      // 4 subunits across [1, 1, 1]: shares are [1, 1, 1], remainder 1 goes to index 0 -> [2, 1, 1]
      final parts = Money.fromSubunits(4).allocate([1, 1, 1]);
      expect(parts[0].subunits, 2);
      expect(parts[1].subunits, 1);
      expect(parts[2].subunits, 1);
    });

    test('rejects empty, negative ratios, or zero sum', () {
      final amount = Money.dzd(100);
      expect(() => amount.allocate([]), throwsArgumentError);
      expect(() => amount.allocate([-1, 2]), throwsArgumentError);
      expect(() => amount.allocate([0, 0, 0]), throwsArgumentError);
    });
  });

  group('Money - Formatting and Boundary Representations', () {
    test('formats at minimum supported integer boundary (minInt) safely', () {
      final minMoney = Money.fromSubunits(minInt, Currency.dzd);
      expect(minMoney.format(), '-92233720368547758.08 DZD');
      expect(minMoney.format(includeSymbol: false), '-92233720368547758.08');
      expect(minMoney.toString(), 'Money(-92233720368547758.08 DZD)');
      expect(minMoney.majorUnits, -92233720368547758);
      expect(minMoney.remainderSubunits, 8);

      final zeroDecimalCurrency = Currency(code: 'JPY', decimalDigits: 0);
      final minJpy = Money.fromSubunits(minInt, zeroDecimalCurrency);
      expect(minJpy.format(), '-9223372036854775808 JPY');
    });

    test('formats at maximum supported integer boundary (maxInt) safely', () {
      final maxMoney = Money.fromSubunits(maxInt, Currency.dzd);
      expect(maxMoney.format(), '92233720368547758.07 DZD');
      expect(maxMoney.majorUnits, 92233720368547758);
      expect(maxMoney.remainderSubunits, 7);
    });

    test('formats standard positive and negative values', () {
      expect(Money.dzd(150, 50).format(), '150.50 DZD');
      expect(Money.dzd(150, 50).format(includeSymbol: false), '150.50');
      expect(Money.dzd(150, 5).format(), '150.05 DZD');
      expect(Money.dzd(-150, 50).format(), '-150.50 DZD');
      expect(Money.dzd(-150, 5).format(), '-150.05 DZD');
      expect(Money.zero().format(), '0.00 DZD');
    });
  });
}
