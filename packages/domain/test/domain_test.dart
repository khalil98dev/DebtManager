import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

class _SampleEntity {}

void main() {
  test('domain library exports Client, ClientId, and EntityId', () {
    final clientId = ClientId.generate();
    expect(clientId, isA<EntityId<Client>>());

    final sampleId = EntityId<_SampleEntity>.generate();
    expect(sampleId, isA<EntityId<_SampleEntity>>());

    final client = Client.create(id: clientId, name: 'Public Export Test');

    expect(client.id, equals(clientId));
    expect(client.name, equals('Public Export Test'));
  });

  test(
    'domain library exports Money, Currency, RoundingMode, and exceptions',
    () {
      expect(Currency.dzd.code, 'DZD');
      expect(Currency.dzd.decimalDigits, 2);

      final customCurrency = Currency(
        code: 'USD',
        decimalDigits: 2,
        symbol: '\$',
      );
      expect(customCurrency.code, 'USD');

      final money = Money.dzd(100, 50);
      expect(money.subunits, 10050);
      expect(money.currency, Currency.dzd);

      final halved = money.multiplyByRational(
        1,
        2,
        roundingMode: RoundingMode.halfUp,
      );
      expect(halved.subunits, 5025);

      expect(
        () => money + Money.fromSubunits(10, customCurrency),
        throwsA(isA<CurrencyMismatchException>()),
      );
    },
  );

  test('domain library exports InvoiceLine and InvoiceLineId', () {
    final lineId = InvoiceLineId.generate();
    expect(lineId, isA<EntityId<InvoiceLine>>());

    final line = InvoiceLine.create(
      id: lineId,
      description: 'Public Line Export Test',
      quantity: 3,
      unitPrice: Money.dzd(50, 0),
    );

    expect(line.id, equals(lineId));
    expect(line.description, equals('Public Line Export Test'));
    expect(line.grossTotal, equals(Money.dzd(150, 0)));
    expect(line.lineTotal, equals(Money.dzd(150, 0)));
  });

  test('domain library exports Invoice, InvoiceId, and InvoiceStatus', () {
    final invoiceId = InvoiceId.generate();
    expect(invoiceId, isA<EntityId<Invoice>>());
    expect(InvoiceStatus.draft.name, 'draft');
    expect(InvoiceStatus.issued.name, 'issued');

    final invoice = Invoice.draft(
      id: invoiceId,
      clientId: ClientId.generate(),
      number: 'INV-EXPORT-001',
    );

    expect(invoice.id, equals(invoiceId));
    expect(invoice.number, equals('INV-EXPORT-001'));
    expect(invoice.status, equals(InvoiceStatus.draft));
    expect(invoice.total, equals(Money.zero(Currency.dzd)));
  });

  test('domain library exports ValidationUtils', () {
    expect(
      ValidationUtils.validateAndTrimRequired('  trimmed  '),
      equals('trimmed'),
    );
    expect(
      ValidationUtils.validateAndTrimNumber('  INV-123  '),
      equals('INV-123'),
    );
    expect(ValidationUtils.normalizeOptionalString('   '), isNull);
  });

  test('domain library exports Payment and PaymentId', () {
    final paymentId = PaymentId.generate();
    expect(paymentId, isA<EntityId<Payment>>());

    final payment = Payment.create(
      id: paymentId,
      clientId: ClientId.generate(),
      amount: Money.dzd(100),
    );

    expect(payment.id, equals(paymentId));
    expect(payment.amount, equals(Money.dzd(100)));
  });

  test('domain library exports PaymentAllocation and PaymentAllocationId', () {
    final allocationId = PaymentAllocationId.generate();
    expect(allocationId, isA<EntityId<PaymentAllocation>>());

    final allocation = PaymentAllocation.create(
      id: allocationId,
      paymentId: PaymentId.generate(),
      invoiceId: InvoiceId.generate(),
      amount: Money.dzd(50),
    );

    expect(allocation.id, equals(allocationId));
    expect(allocation.amount, equals(Money.dzd(50)));
  });

  test(
    'domain library exports ClientFinancialPosition and ClientFinancialCalculator',
    () {
      final clientId = ClientId.generate();
      final position = ClientFinancialCalculator.calculate(clientId: clientId);

      expect(position, isA<ClientFinancialPosition>());
      expect(position.clientId, equals(clientId));
      expect(position.isBalanced, isTrue);
    },
  );
}
