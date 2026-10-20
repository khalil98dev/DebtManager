import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final fixedId = InvoiceLineId('line-001');
  final fixedCreatedAt = DateTime.utc(2026, 1, 1, 10, 0, 0);
  final usdCurrency = Currency(code: 'USD', decimalDigits: 2, symbol: '\$');

  group('InvoiceLine - Construction and Normalization', () {
    test('creates with all valid explicit fields and trims description', () {
      final line = InvoiceLine(
        id: fixedId,
        description: '   Box of nails   ',
        quantity: 5,
        unitPrice: Money.dzd(120, 50),
        discount: Money.dzd(50, 0),
        createdAt: fixedCreatedAt,
      );

      expect(line.id, equals(fixedId));
      expect(line.description, equals('Box of nails'));
      expect(line.quantity, equals(5));
      expect(line.unitPrice, equals(Money.dzd(120, 50)));
      expect(line.discount, equals(Money.dzd(50, 0)));
      expect(line.currency, equals(Currency.dzd));
      expect(line.createdAt, equals(fixedCreatedAt));
      expect(line.grossTotal, equals(Money.dzd(602, 50)));
      expect(line.lineTotal, equals(Money.dzd(552, 50)));
    });

    test(
      'defaults discount to zero in unitPrice currency when omitted or null',
      () {
        final line = InvoiceLine(
          id: fixedId,
          description: 'Item without discount',
          quantity: 2,
          unitPrice: Money.dzd(75, 25),
          createdAt: fixedCreatedAt,
        );

        expect(line.discount, equals(Money.zero(Currency.dzd)));
        expect(line.grossTotal, equals(Money.dzd(150, 50)));
        expect(line.lineTotal, equals(line.grossTotal));
      },
    );

    test('create factory automatically generates ID and sets timestamp', () {
      final line = InvoiceLine.create(
        description: 'Auto line item',
        quantity: 1,
        unitPrice: Money.dzd(200, 0),
      );

      expect(line.id.value, isNotEmpty);
      expect(line.description, equals('Auto line item'));
      expect(line.quantity, equals(1));
      expect(line.unitPrice, equals(Money.dzd(200, 0)));
      expect(line.discount, equals(Money.zero(Currency.dzd)));
      expect(line.createdAt, isNotNull);
    });

    test('create factory respects custom id and createdAt', () {
      final line = InvoiceLine.create(
        id: fixedId,
        description: 'Custom line item',
        quantity: 2,
        unitPrice: Money.dzd(50, 0),
        discount: Money.dzd(10, 0),
        createdAt: fixedCreatedAt,
      );

      expect(line.id, equals(fixedId));
      expect(line.createdAt, equals(fixedCreatedAt));
      expect(line.grossTotal, equals(Money.dzd(100, 0)));
      expect(line.lineTotal, equals(Money.dzd(90, 0)));
    });
  });

  group('InvoiceLine - Invalid Inputs', () {
    test('rejects empty description with ArgumentError', () {
      expect(
        () => InvoiceLine(
          id: fixedId,
          description: '',
          quantity: 1,
          unitPrice: Money.dzd(10),
          createdAt: fixedCreatedAt,
        ),
        throwsArgumentError,
      );
    });

    test('rejects whitespace-only description with ArgumentError', () {
      expect(
        () => InvoiceLine(
          id: fixedId,
          description: '   \t\n\r  ',
          quantity: 1,
          unitPrice: Money.dzd(10),
          createdAt: fixedCreatedAt,
        ),
        throwsArgumentError,
      );
    });

    test('rejects zero quantity with ArgumentError', () {
      expect(
        () => InvoiceLine(
          id: fixedId,
          description: 'Item',
          quantity: 0,
          unitPrice: Money.dzd(10),
          createdAt: fixedCreatedAt,
        ),
        throwsArgumentError,
      );
    });

    test('rejects negative quantity with ArgumentError', () {
      expect(
        () => InvoiceLine(
          id: fixedId,
          description: 'Item',
          quantity: -3,
          unitPrice: Money.dzd(10),
          createdAt: fixedCreatedAt,
        ),
        throwsArgumentError,
      );
    });

    test('rejects negative unit price with ArgumentError', () {
      expect(
        () => InvoiceLine(
          id: fixedId,
          description: 'Item',
          quantity: 1,
          unitPrice: Money.fromSubunits(-100, Currency.dzd),
          createdAt: fixedCreatedAt,
        ),
        throwsArgumentError,
      );
    });

    test('rejects negative discount with ArgumentError', () {
      expect(
        () => InvoiceLine(
          id: fixedId,
          description: 'Item',
          quantity: 1,
          unitPrice: Money.dzd(100),
          discount: Money.fromSubunits(-10, Currency.dzd),
          createdAt: fixedCreatedAt,
        ),
        throwsArgumentError,
      );
    });
  });

  group('InvoiceLine - Currency Mismatches', () {
    test('rejects discount with different currency than unit price', () {
      expect(
        () => InvoiceLine(
          id: fixedId,
          description: 'Item',
          quantity: 2,
          unitPrice: Money.dzd(100),
          discount: Money.fromSubunits(10, usdCurrency),
          createdAt: fixedCreatedAt,
        ),
        throwsA(
          isA<CurrencyMismatchException>()
              .having((e) => e.expectedCurrency, 'expectedCurrency', 'DZD')
              .having((e) => e.actualCurrency, 'actualCurrency', 'USD'),
        ),
      );
    });
  });

  group('InvoiceLine - Discount Boundaries and Calculated Totals', () {
    test('allows discount equal to zero', () {
      final line = InvoiceLine(
        id: fixedId,
        description: 'Item',
        quantity: 3,
        unitPrice: Money.dzd(50),
        discount: Money.zero(Currency.dzd),
        createdAt: fixedCreatedAt,
      );

      expect(line.grossTotal, equals(Money.dzd(150)));
      expect(line.lineTotal, equals(Money.dzd(150)));
    });

    test('allows discount equal to gross total (100% discount)', () {
      final line = InvoiceLine(
        id: fixedId,
        description: 'Item',
        quantity: 2,
        unitPrice: Money.dzd(50),
        discount: Money.dzd(100),
        createdAt: fixedCreatedAt,
      );

      expect(line.grossTotal, equals(Money.dzd(100)));
      expect(line.lineTotal, equals(Money.zero(Currency.dzd)));
    });

    test('rejects discount strictly greater than gross total', () {
      expect(
        () => InvoiceLine(
          id: fixedId,
          description: 'Item',
          quantity: 2,
          unitPrice: Money.dzd(50),
          discount: Money.fromSubunits(
            10001,
            Currency.dzd,
          ), // 100.01 DZD > 100.00 DZD
          createdAt: fixedCreatedAt,
        ),
        throwsArgumentError,
      );
    });

    test('allows zero unit price with zero discount', () {
      final line = InvoiceLine(
        id: fixedId,
        description: 'Free sample',
        quantity: 10,
        unitPrice: Money.zero(Currency.dzd),
        discount: Money.zero(Currency.dzd),
        createdAt: fixedCreatedAt,
      );

      expect(line.grossTotal, equals(Money.zero(Currency.dzd)));
      expect(line.lineTotal, equals(Money.zero(Currency.dzd)));
    });

    test('rejects positive discount when unit price is zero', () {
      expect(
        () => InvoiceLine(
          id: fixedId,
          description: 'Free sample with discount',
          quantity: 1,
          unitPrice: Money.zero(Currency.dzd),
          discount: Money.fromSubunits(1, Currency.dzd),
          createdAt: fixedCreatedAt,
        ),
        throwsArgumentError,
      );
    });
  });

  group('InvoiceLine - Arithmetic Overflow', () {
    test(
      'throws MoneyOverflowException when grossTotal calculation overflows',
      () {
        final maxMoney = Money.fromSubunits(9223372036854775807, Currency.dzd);
        expect(
          () => InvoiceLine(
            id: fixedId,
            description: 'Huge item',
            quantity: 2,
            unitPrice: maxMoney,
            createdAt: fixedCreatedAt,
          ),
          throwsA(isA<MoneyOverflowException>()),
        );
      },
    );
  });

  group('InvoiceLine - Immutable Updates', () {
    late InvoiceLine original;

    setUp(() {
      original = InvoiceLine(
        id: fixedId,
        description: 'Original description',
        quantity: 4,
        unitPrice: Money.dzd(100, 0),
        discount: Money.dzd(40, 0),
        createdAt: fixedCreatedAt,
      );
    });

    test(
      'updateDescription trims and updates description, preserving other fields',
      () {
        final updated = original.updateDescription('   New Description   ');

        expect(updated.description, equals('New Description'));
        expect(updated.id, equals(fixedId));
        expect(updated.createdAt, equals(fixedCreatedAt));
        expect(updated.quantity, equals(4));
        expect(updated.unitPrice, equals(Money.dzd(100, 0)));
        expect(updated.discount, equals(Money.dzd(40, 0)));

        // Original unchanged
        expect(original.description, equals('Original description'));

        // Alias works
        final aliasUpdated = original.changeDescription('Alias Name');
        expect(aliasUpdated.description, equals('Alias Name'));
      },
    );

    test('updateDescription rejects empty and blank descriptions', () {
      expect(() => original.updateDescription(''), throwsArgumentError);
      expect(() => original.updateDescription('   \t  '), throwsArgumentError);
    });

    test('updateQuantity updates quantity and recalculates totals', () {
      final updated = original.updateQuantity(10);

      expect(updated.quantity, equals(10));
      expect(updated.id, equals(fixedId));
      expect(updated.createdAt, equals(fixedCreatedAt));
      expect(updated.grossTotal, equals(Money.dzd(1000, 0)));
      expect(updated.lineTotal, equals(Money.dzd(960, 0)));

      // Original unchanged
      expect(original.quantity, equals(4));

      // Alias works
      final aliasUpdated = original.changeQuantity(6);
      expect(aliasUpdated.quantity, equals(6));
    });

    test('updateQuantity rejects invalid quantity <= 0', () {
      expect(() => original.updateQuantity(0), throwsArgumentError);
      expect(() => original.updateQuantity(-2), throwsArgumentError);
    });

    test(
      'updateQuantity rejects quantity if existing discount exceeds new gross total',
      () {
        // original gross = 400, discount = 40.
        // If quantity is reduced to 1, but unitPrice is 30, gross is 30, discount is 40 -> invalid.
        final lineWithHighDiscount = InvoiceLine(
          id: fixedId,
          description: 'Item',
          quantity: 2,
          unitPrice: Money.dzd(50),
          discount: Money.dzd(80),
          createdAt: fixedCreatedAt,
        );

        // Reducing quantity to 1 yields gross 50, but discount is 80 -> throws
        expect(
          () => lineWithHighDiscount.updateQuantity(1),
          throwsArgumentError,
        );
      },
    );

    test('updateDiscount updates discount and recalculates lineTotal', () {
      final updated = original.updateDiscount(Money.dzd(100, 0));

      expect(updated.discount, equals(Money.dzd(100, 0)));
      expect(updated.grossTotal, equals(Money.dzd(400, 0)));
      expect(updated.lineTotal, equals(Money.dzd(300, 0)));
      expect(updated.id, equals(fixedId));
      expect(updated.createdAt, equals(fixedCreatedAt));

      // Original unchanged
      expect(original.discount, equals(Money.dzd(40, 0)));

      // Alias works
      final aliasUpdated = original.changeDiscount(Money.dzd(50, 0));
      expect(aliasUpdated.discount, equals(Money.dzd(50, 0)));
    });

    test('updateDiscount rejects invalid discounts', () {
      expect(
        () => original.updateDiscount(Money.fromSubunits(-10, Currency.dzd)),
        throwsArgumentError,
      );
      expect(
        () => original.updateDiscount(Money.dzd(500, 0)), // exceeds gross 400
        throwsArgumentError,
      );
      expect(
        () => original.updateDiscount(Money.fromSubunits(10, usdCurrency)),
        throwsA(isA<CurrencyMismatchException>()),
      );
    });

    group('updateUnitPrice', () {
      test('same currency without new discount retains existing discount', () {
        final updated = original.updateUnitPrice(Money.dzd(150, 0));

        expect(updated.unitPrice, equals(Money.dzd(150, 0)));
        expect(updated.discount, equals(Money.dzd(40, 0)));
        expect(updated.grossTotal, equals(Money.dzd(600, 0)));
        expect(updated.lineTotal, equals(Money.dzd(560, 0)));
        expect(updated.id, equals(fixedId));
        expect(updated.createdAt, equals(fixedCreatedAt));

        // Alias works
        final aliasUpdated = original.changeUnitPrice(Money.dzd(200, 0));
        expect(aliasUpdated.unitPrice, equals(Money.dzd(200, 0)));
      });

      test(
        'same currency with new discount updates both unitPrice and discount',
        () {
          final updated = original.updateUnitPrice(
            Money.dzd(150, 0),
            discount: Money.dzd(100, 0),
          );

          expect(updated.unitPrice, equals(Money.dzd(150, 0)));
          expect(updated.discount, equals(Money.dzd(100, 0)));
          expect(updated.grossTotal, equals(Money.dzd(600, 0)));
          expect(updated.lineTotal, equals(Money.dzd(500, 0)));
        },
      );

      test(
        'same currency rejects new unitPrice if existing discount exceeds new gross',
        () {
          // original discount is 40 DZD, qty is 4.
          // If new unitPrice is 5 DZD, gross is 20 DZD < 40 DZD.
          expect(
            () => original.updateUnitPrice(Money.dzd(5, 0)),
            throwsArgumentError,
          );
        },
      );

      test(
        'different currency without new discount resets discount to zero in new currency',
        () {
          final usdPrice = Money.fromSubunits(500, usdCurrency); // 5.00 USD
          final updated = original.updateUnitPrice(usdPrice);

          expect(updated.unitPrice, equals(usdPrice));
          expect(updated.currency, equals(usdCurrency));
          expect(updated.discount, equals(Money.zero(usdCurrency)));
          expect(
            updated.grossTotal,
            equals(Money.fromSubunits(2000, usdCurrency)),
          );
          expect(
            updated.lineTotal,
            equals(Money.fromSubunits(2000, usdCurrency)),
          );
        },
      );

      test(
        'different currency with explicit new discount in same currency updates successfully',
        () {
          final usdPrice = Money.fromSubunits(500, usdCurrency);
          final usdDiscount = Money.fromSubunits(100, usdCurrency);
          final updated = original.updateUnitPrice(
            usdPrice,
            discount: usdDiscount,
          );

          expect(updated.unitPrice, equals(usdPrice));
          expect(updated.discount, equals(usdDiscount));
          expect(
            updated.grossTotal,
            equals(Money.fromSubunits(2000, usdCurrency)),
          );
          expect(
            updated.lineTotal,
            equals(Money.fromSubunits(1900, usdCurrency)),
          );
        },
      );

      test(
        'different currency with explicit discount in mismatched currency throws CurrencyMismatchException',
        () {
          final usdPrice = Money.fromSubunits(500, usdCurrency);
          final dzdDiscount = Money.dzd(10, 0);

          expect(
            () => original.updateUnitPrice(usdPrice, discount: dzdDiscount),
            throwsA(isA<CurrencyMismatchException>()),
          );
        },
      );
    });

    group('changeCurrency', () {
      test(
        'updates currency and unitPrice, defaulting discount to zero in new currency',
        () {
          final usdPrice = Money.fromSubunits(250, usdCurrency);
          final converted = original.changeCurrency(
            usdCurrency,
            newUnitPrice: usdPrice,
          );

          expect(converted.currency, equals(usdCurrency));
          expect(converted.unitPrice, equals(usdPrice));
          expect(converted.discount, equals(Money.zero(usdCurrency)));
        },
      );

      test('updates currency, unitPrice, and applies newDiscount', () {
        final usdPrice = Money.fromSubunits(250, usdCurrency);
        final usdDiscount = Money.fromSubunits(50, usdCurrency);
        final converted = original.changeCurrency(
          usdCurrency,
          newUnitPrice: usdPrice,
          newDiscount: usdDiscount,
        );

        expect(converted.currency, equals(usdCurrency));
        expect(converted.unitPrice, equals(usdPrice));
        expect(converted.discount, equals(usdDiscount));
      });

      test(
        'throws CurrencyMismatchException if newUnitPrice currency does not match requested currency',
        () {
          expect(
            () => original.changeCurrency(
              usdCurrency,
              newUnitPrice: Money.dzd(100),
            ),
            throwsA(isA<CurrencyMismatchException>()),
          );
        },
      );
    });

    group('copyWith', () {
      test('selectively modifies fields while preserving id and createdAt', () {
        final copied = original.copyWith(
          description: 'Copied item',
          quantity: 6,
        );

        expect(copied.id, equals(fixedId));
        expect(copied.createdAt, equals(fixedCreatedAt));
        expect(copied.description, equals('Copied item'));
        expect(copied.quantity, equals(6));
        expect(copied.unitPrice, equals(original.unitPrice));
        expect(copied.discount, equals(original.discount));
      });

      test(
        'resets discount to zero if unitPrice currency changes and discount is omitted',
        () {
          final usdPrice = Money.fromSubunits(1000, usdCurrency);
          final copied = original.copyWith(unitPrice: usdPrice);

          expect(copied.unitPrice, equals(usdPrice));
          expect(copied.currency, equals(usdCurrency));
          expect(copied.discount, equals(Money.zero(usdCurrency)));
        },
      );
    });
  });

  group('InvoiceLine - Entity Equality, HashCode, and String Representation', () {
    test(
      'two invoice lines with identical id are equal even with different fields',
      () {
        final line1 = InvoiceLine(
          id: fixedId,
          description: 'Item 1',
          quantity: 1,
          unitPrice: Money.dzd(10),
          createdAt: fixedCreatedAt,
        );

        final line2 = InvoiceLine(
          id: fixedId,
          description: 'Item 2',
          quantity: 5,
          unitPrice: Money.dzd(100),
          discount: Money.dzd(50),
          createdAt: fixedCreatedAt.add(const Duration(days: 1)),
        );

        expect(line1, equals(line2));
        expect(line1.hashCode, equals(line2.hashCode));
      },
    );

    test('two invoice lines with different ids are not equal', () {
      final line1 = InvoiceLine(
        id: InvoiceLineId('line-001'),
        description: 'Item',
        quantity: 1,
        unitPrice: Money.dzd(10),
        createdAt: fixedCreatedAt,
      );

      final line2 = InvoiceLine(
        id: InvoiceLineId('line-002'),
        description: 'Item',
        quantity: 1,
        unitPrice: Money.dzd(10),
        createdAt: fixedCreatedAt,
      );

      expect(line1, isNot(equals(line2)));
    });

    test('toString includes all key fields and calculated totals', () {
      final line = InvoiceLine(
        id: fixedId,
        description: 'Widgets',
        quantity: 2,
        unitPrice: Money.dzd(100),
        discount: Money.dzd(20),
        createdAt: fixedCreatedAt,
      );

      final str = line.toString();
      expect(str, contains('line-001'));
      expect(str, contains('Widgets'));
      expect(str, contains('2'));
      expect(str, contains('100.00 DZD'));
      expect(str, contains('20.00 DZD'));
      expect(str, contains('200.00 DZD'));
      expect(str, contains('180.00 DZD'));
    });
  });
}
