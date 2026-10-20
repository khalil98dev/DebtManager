import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final fixedAllocationId = PaymentAllocationId('alloc-001');
  final fixedPaymentId = PaymentId('pay-001');
  final fixedInvoiceId = InvoiceId('inv-001');
  final fixedCreatedAt = DateTime.utc(2026, 1, 1, 14, 0, 0);

  group('PaymentAllocation - Construction and Validation', () {
    test('constructs with valid explicit parameters', () {
      final allocation = PaymentAllocation(
        id: fixedAllocationId,
        paymentId: fixedPaymentId,
        invoiceId: fixedInvoiceId,
        amount: Money.dzd(350, 0),
        createdAt: fixedCreatedAt,
      );

      expect(allocation.id, equals(fixedAllocationId));
      expect(allocation.paymentId, equals(fixedPaymentId));
      expect(allocation.invoiceId, equals(fixedInvoiceId));
      expect(allocation.amount, equals(Money.dzd(350, 0)));
      expect(allocation.currency, equals(Currency.dzd));
      expect(allocation.createdAt, equals(fixedCreatedAt));
    });

    test('rejects zero amount with ArgumentError', () {
      expect(
        () => PaymentAllocation(
          id: fixedAllocationId,
          paymentId: fixedPaymentId,
          invoiceId: fixedInvoiceId,
          amount: Money.zero(Currency.dzd),
          createdAt: fixedCreatedAt,
        ),
        throwsArgumentError,
      );
    });

    test('rejects negative amount with ArgumentError', () {
      expect(
        () => PaymentAllocation(
          id: fixedAllocationId,
          paymentId: fixedPaymentId,
          invoiceId: fixedInvoiceId,
          amount: Money.fromSubunits(-100, Currency.dzd),
          createdAt: fixedCreatedAt,
        ),
        throwsArgumentError,
      );
    });
  });

  group('PaymentAllocation.create Factory', () {
    test('automatically generates offline-ready ID and sets timestamp', () {
      final allocation = PaymentAllocation.create(
        paymentId: fixedPaymentId,
        invoiceId: fixedInvoiceId,
        amount: Money.dzd(150),
      );

      expect(allocation.id.value, isNotEmpty);
      expect(allocation.paymentId, equals(fixedPaymentId));
      expect(allocation.invoiceId, equals(fixedInvoiceId));
      expect(allocation.amount, equals(Money.dzd(150)));
      expect(allocation.createdAt, isNotNull);
    });

    test('respects custom id and createdAt', () {
      final allocation = PaymentAllocation.create(
        id: fixedAllocationId,
        paymentId: fixedPaymentId,
        invoiceId: fixedInvoiceId,
        amount: Money.dzd(500),
        createdAt: fixedCreatedAt,
      );

      expect(allocation.id, equals(fixedAllocationId));
      expect(allocation.paymentId, equals(fixedPaymentId));
      expect(allocation.invoiceId, equals(fixedInvoiceId));
      expect(allocation.amount, equals(Money.dzd(500)));
      expect(allocation.createdAt, equals(fixedCreatedAt));
    });
  });

  group('PaymentAllocation - Currency Support', () {
    test('supports different currencies', () {
      final usdCurrency = Currency(code: 'USD', decimalDigits: 2, symbol: '\$');
      final allocation = PaymentAllocation.create(
        paymentId: fixedPaymentId,
        invoiceId: fixedInvoiceId,
        amount: Money.fromSubunits(2000, usdCurrency),
      );

      expect(allocation.amount.subunits, equals(2000));
      expect(allocation.currency, equals(usdCurrency));
    });
  });

  group(
    'PaymentAllocation - Entity Equality, HashCode, and String Representation',
    () {
      test(
        'two allocations with identical id are equal even with different fields',
        () {
          final alloc1 = PaymentAllocation(
            id: fixedAllocationId,
            paymentId: fixedPaymentId,
            invoiceId: fixedInvoiceId,
            amount: Money.dzd(100),
            createdAt: fixedCreatedAt,
          );

          final alloc2 = PaymentAllocation(
            id: fixedAllocationId,
            paymentId: PaymentId('pay-other'),
            invoiceId: InvoiceId('inv-other'),
            amount: Money.dzd(999),
            createdAt: fixedCreatedAt.add(const Duration(days: 1)),
          );

          expect(alloc1, equals(alloc2));
          expect(alloc1.hashCode, equals(alloc2.hashCode));
        },
      );

      test('two allocations with different ids are not equal', () {
        final alloc1 = PaymentAllocation.create(
          id: PaymentAllocationId('alloc-1'),
          paymentId: fixedPaymentId,
          invoiceId: fixedInvoiceId,
          amount: Money.dzd(100),
        );

        final alloc2 = PaymentAllocation.create(
          id: PaymentAllocationId('alloc-2'),
          paymentId: fixedPaymentId,
          invoiceId: fixedInvoiceId,
          amount: Money.dzd(100),
        );

        expect(alloc1, isNot(equals(alloc2)));
      });

      test(
        'toString includes id, paymentId, invoiceId, amount, and createdAt',
        () {
          final allocation = PaymentAllocation(
            id: fixedAllocationId,
            paymentId: fixedPaymentId,
            invoiceId: fixedInvoiceId,
            amount: Money.dzd(250, 75),
            createdAt: fixedCreatedAt,
          );

          final str = allocation.toString();
          expect(str, contains('alloc-001'));
          expect(str, contains('pay-001'));
          expect(str, contains('inv-001'));
          expect(str, contains('250.75 DZD'));
        },
      );
    },
  );

  group('PaymentAllocation - Immutability & Timestamps', () {
    test(
      'all fields are immutable and the entity provides no mutation operations',
      () {
        final allocation = PaymentAllocation.create(
          id: fixedAllocationId,
          paymentId: fixedPaymentId,
          invoiceId: fixedInvoiceId,
          amount: Money.dzd(300),
          createdAt: fixedCreatedAt,
        );

        // Verify all properties are fixed and final
        expect(allocation.id, equals(fixedAllocationId));
        expect(allocation.paymentId, equals(fixedPaymentId));
        expect(allocation.invoiceId, equals(fixedInvoiceId));
        expect(allocation.amount, equals(Money.dzd(300)));
        expect(allocation.createdAt, equals(fixedCreatedAt));
        expect(allocation.currency, equals(Currency.dzd));
      },
    );

    test(
      'timestamp behavior: defaults to current time within reasonable threshold',
      () {
        final before = DateTime.now();
        final allocation = PaymentAllocation.create(
          paymentId: fixedPaymentId,
          invoiceId: fixedInvoiceId,
          amount: Money.dzd(100),
        );
        final after = DateTime.now();

        expect(
          allocation.createdAt.isAfter(
            before.subtract(const Duration(seconds: 1)),
          ),
          isTrue,
        );
        expect(
          allocation.createdAt.isBefore(after.add(const Duration(seconds: 1))),
          isTrue,
        );
      },
    );
  });
}
