import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final fixedClientId = ClientId('client-001');
  final fixedPaymentId = PaymentId('pay-001');
  final fixedCreatedAt = DateTime.utc(2026, 1, 1, 12, 0, 0);
  final fixedReceivedAt = DateTime.utc(2026, 1, 1, 10, 30, 0);

  group('Payment - Construction and Validation', () {
    test('constructs with all valid explicit fields and normalizes notes', () {
      final payment = Payment(
        id: fixedPaymentId,
        clientId: fixedClientId,
        amount: Money.dzd(500, 50),
        receivedAt: fixedReceivedAt,
        notes: '   Check #1042   ',
        createdAt: fixedCreatedAt,
      );

      expect(payment.id, equals(fixedPaymentId));
      expect(payment.clientId, equals(fixedClientId));
      expect(payment.amount, equals(Money.dzd(500, 50)));
      expect(payment.currency, equals(Currency.dzd));
      expect(payment.receivedAt, equals(fixedReceivedAt));
      expect(payment.notes, equals('Check #1042'));
      expect(payment.createdAt, equals(fixedCreatedAt));
    });

    test('rejects zero amount with ArgumentError', () {
      expect(
        () => Payment(
          id: fixedPaymentId,
          clientId: fixedClientId,
          amount: Money.zero(Currency.dzd),
          receivedAt: fixedReceivedAt,
          createdAt: fixedCreatedAt,
        ),
        throwsArgumentError,
      );
    });

    test('rejects negative amount with ArgumentError', () {
      expect(
        () => Payment(
          id: fixedPaymentId,
          clientId: fixedClientId,
          amount: Money.fromSubunits(-100, Currency.dzd),
          receivedAt: fixedReceivedAt,
          createdAt: fixedCreatedAt,
        ),
        throwsArgumentError,
      );
    });

    test('normalizes blank and whitespace-only notes to null', () {
      final paymentNull = Payment(
        id: fixedPaymentId,
        clientId: fixedClientId,
        amount: Money.dzd(100),
        receivedAt: fixedReceivedAt,
        notes: null,
        createdAt: fixedCreatedAt,
      );
      expect(paymentNull.notes, isNull);

      final paymentEmpty = Payment(
        id: fixedPaymentId,
        clientId: fixedClientId,
        amount: Money.dzd(100),
        receivedAt: fixedReceivedAt,
        notes: '',
        createdAt: fixedCreatedAt,
      );
      expect(paymentEmpty.notes, isNull);

      final paymentWhitespace = Payment(
        id: fixedPaymentId,
        clientId: fixedClientId,
        amount: Money.dzd(100),
        receivedAt: fixedReceivedAt,
        notes: '   \t\r\n   ',
        createdAt: fixedCreatedAt,
      );
      expect(paymentWhitespace.notes, isNull);
    });
  });

  group('Payment.create Factory', () {
    test('automatically generates offline-ready ID and sets timestamps', () {
      final payment = Payment.create(
        clientId: fixedClientId,
        amount: Money.dzd(250),
      );

      expect(payment.id.value, isNotEmpty);
      expect(payment.clientId, equals(fixedClientId));
      expect(payment.amount, equals(Money.dzd(250)));
      expect(payment.createdAt, isNotNull);
      expect(payment.receivedAt, equals(payment.createdAt));
      expect(payment.notes, isNull);
    });

    test('respects custom id, receivedAt, notes, and createdAt', () {
      final payment = Payment.create(
        id: fixedPaymentId,
        clientId: fixedClientId,
        amount: Money.dzd(1000),
        receivedAt: fixedReceivedAt,
        notes: 'Custom memo',
        createdAt: fixedCreatedAt,
      );

      expect(payment.id, equals(fixedPaymentId));
      expect(payment.clientId, equals(fixedClientId));
      expect(payment.amount, equals(Money.dzd(1000)));
      expect(payment.receivedAt, equals(fixedReceivedAt));
      expect(payment.notes, equals('Custom memo'));
      expect(payment.createdAt, equals(fixedCreatedAt));
    });
  });

  group('Payment - Immutability & Update Operations', () {
    late Payment original;

    setUp(() {
      original = Payment(
        id: fixedPaymentId,
        clientId: fixedClientId,
        amount: Money.dzd(500),
        receivedAt: fixedReceivedAt,
        notes: 'Original memo',
        createdAt: fixedCreatedAt,
      );
    });

    test(
      'updateNotes returns new instance, trims/normalizes notes, and preserves other fields',
      () {
        final updated = original.updateNotes('   Updated memo   ');

        expect(updated.notes, equals('Updated memo'));
        expect(updated.id, equals(fixedPaymentId));
        expect(updated.clientId, equals(fixedClientId));
        expect(updated.amount, equals(Money.dzd(500)));
        expect(updated.receivedAt, equals(fixedReceivedAt));
        expect(updated.createdAt, equals(fixedCreatedAt));

        // Original instance is unchanged
        expect(original.notes, equals('Original memo'));

        // Normalizes to null
        final cleared = original.updateNotes('   \n  ');
        expect(cleared.notes, isNull);
      },
    );

    test(
      'financial transaction facts (amount, clientId, receivedAt, id, createdAt) remain immutable',
      () {
        final updated = original.updateNotes('New memo');

        expect(updated.id, equals(original.id));
        expect(updated.clientId, equals(original.clientId));
        expect(updated.amount, equals(original.amount));
        expect(updated.receivedAt, equals(original.receivedAt));
        expect(updated.createdAt, equals(original.createdAt));
      },
    );

    test('supports different currencies', () {
      final usdCurrency = Currency(code: 'USD', decimalDigits: 2, symbol: '\$');
      final usdPayment = Payment.create(
        clientId: fixedClientId,
        amount: Money.fromSubunits(1500, usdCurrency),
      );

      expect(usdPayment.amount.subunits, equals(1500));
      expect(usdPayment.currency, equals(usdCurrency));
    });
  });

  group('Payment - Timestamps Flexibility', () {
    test(
      'supports backdated payments where receivedAt is before createdAt',
      () {
        final recordedLater = Payment.create(
          clientId: fixedClientId,
          amount: Money.dzd(100),
          receivedAt: fixedReceivedAt, // 10:30
          createdAt: fixedCreatedAt, // 12:00
        );

        expect(
          recordedLater.receivedAt.isBefore(recordedLater.createdAt),
          isTrue,
        );
      },
    );
  });

  group('Payment - Entity Equality, HashCode, and String Representation', () {
    test(
      'two payments with identical id are equal even with different fields',
      () {
        final payment1 = Payment(
          id: fixedPaymentId,
          clientId: fixedClientId,
          amount: Money.dzd(100),
          receivedAt: fixedReceivedAt,
          createdAt: fixedCreatedAt,
        );

        final payment2 = Payment(
          id: fixedPaymentId,
          clientId: ClientId('client-999'),
          amount: Money.dzd(999),
          receivedAt: fixedReceivedAt.add(const Duration(days: 1)),
          createdAt: fixedCreatedAt.add(const Duration(days: 2)),
        );

        expect(payment1, equals(payment2));
        expect(payment1.hashCode, equals(payment2.hashCode));
      },
    );

    test('two payments with different ids are not equal', () {
      final payment1 = Payment.create(
        id: PaymentId('pay-1'),
        clientId: fixedClientId,
        amount: Money.dzd(100),
      );

      final payment2 = Payment.create(
        id: PaymentId('pay-2'),
        clientId: fixedClientId,
        amount: Money.dzd(100),
      );

      expect(payment1, isNot(equals(payment2)));
    });

    test(
      'toString includes id, clientId, amount, receivedAt, notes, and createdAt',
      () {
        final payment = Payment(
          id: fixedPaymentId,
          clientId: fixedClientId,
          amount: Money.dzd(350, 50),
          receivedAt: fixedReceivedAt,
          notes: 'Deposit',
          createdAt: fixedCreatedAt,
        );

        final str = payment.toString();
        expect(str, contains('pay-001'));
        expect(str, contains('client-001'));
        expect(str, contains('350.50 DZD'));
        expect(str, contains('Deposit'));
      },
    );
  });
}
