import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final clientA = ClientId('client-A');
  final clientB = ClientId('client-B');
  final usdCurrency = Currency(code: 'USD', decimalDigits: 2, symbol: '\$');

  Invoice createInvoice({
    required String id,
    required ClientId clientId,
    required Money unitPrice,
    int quantity = 1,
    bool isIssued = true,
  }) {
    final invoice = Invoice.draft(
      id: InvoiceId(id),
      clientId: clientId,
      number: 'INV-$id',
      lines: [
        InvoiceLine.create(
          id: InvoiceLineId('line-$id'),
          description: 'Item $id',
          quantity: quantity,
          unitPrice: unitPrice,
        ),
      ],
    );
    return isIssued ? invoice.issue() : invoice;
  }

  Payment createPayment({
    required String id,
    required ClientId clientId,
    required Money amount,
  }) {
    return Payment.create(
      id: PaymentId(id),
      clientId: clientId,
      amount: amount,
    );
  }

  PaymentAllocation createAllocation({
    required String id,
    required Payment payment,
    required Invoice invoice,
    required Money amount,
  }) {
    return PaymentAllocation.create(
      id: PaymentAllocationId(id),
      paymentId: payment.id,
      invoiceId: invoice.id,
      amount: amount,
    );
  }

  group('ClientFinancialCalculator - Empty Accounts', () {
    test('returns all zero metrics for client with no records', () {
      final position = ClientFinancialCalculator.calculate(clientId: clientA);

      expect(position.clientId, equals(clientA));
      expect(position.currency, equals(Currency.dzd));
      expect(position.totalInvoiced, equals(Money.zero(Currency.dzd)));
      expect(position.totalAllocatedPayments, equals(Money.zero(Currency.dzd)));
      expect(position.outstandingDebt, equals(Money.zero(Currency.dzd)));
      expect(position.unallocatedCredit, equals(Money.zero(Currency.dzd)));
      expect(position.netPosition, equals(Money.zero(Currency.dzd)));
      expect(position.isBalanced, isTrue);
      expect(position.isNetDebtor, isFalse);
      expect(position.isNetCreditor, isFalse);
      expect(position.hasOutstandingDebt, isFalse);
      expect(position.hasUnallocatedCredit, isFalse);
    });

    test('respects explicitly provided currency for empty account', () {
      final position = ClientFinancialCalculator.calculate(
        clientId: clientA,
        currency: usdCurrency,
      );

      expect(position.currency, equals(usdCurrency));
      expect(position.netPosition, equals(Money.zero(usdCurrency)));
    });
  });

  group('ClientFinancialCalculator - Draft and Issued Invoices', () {
    test('excludes draft invoices from totalInvoiced and outstandingDebt', () {
      final draftInvoice = createInvoice(
        id: 'draft-1',
        clientId: clientA,
        unitPrice: Money.dzd(500),
        isIssued: false,
      );
      final issuedInvoice = createInvoice(
        id: 'issued-1',
        clientId: clientA,
        unitPrice: Money.dzd(300),
        isIssued: true,
      );

      final position = ClientFinancialCalculator.calculate(
        clientId: clientA,
        invoices: [draftInvoice, issuedInvoice],
      );

      expect(position.totalInvoiced, equals(Money.dzd(300)));
      expect(position.outstandingDebt, equals(Money.dzd(300)));
      expect(position.netPosition, equals(Money.dzd(300)));
      expect(position.isNetDebtor, isTrue);
    });

    test(
      'rejects allocations referencing draft invoices with ArgumentError',
      () {
        final draftInvoice = createInvoice(
          id: 'draft-1',
          clientId: clientA,
          unitPrice: Money.dzd(500),
          isIssued: false,
        );
        final payment = createPayment(
          id: 'pay-1',
          clientId: clientA,
          amount: Money.dzd(500),
        );
        final allocation = createAllocation(
          id: 'alloc-1',
          payment: payment,
          invoice: draftInvoice,
          amount: Money.dzd(500),
        );

        expect(
          () => ClientFinancialCalculator.calculate(
            clientId: clientA,
            invoices: [draftInvoice],
            payments: [payment],
            allocations: [allocation],
          ),
          throwsArgumentError,
        );
      },
    );
  });

  group('ClientFinancialCalculator - Invoice Payment States', () {
    test('calculates unpaid invoices', () {
      final invoice = createInvoice(
        id: 'inv-1',
        clientId: clientA,
        unitPrice: Money.dzd(1000),
      );

      final position = ClientFinancialCalculator.calculate(
        clientId: clientA,
        invoices: [invoice],
      );

      expect(position.totalInvoiced, equals(Money.dzd(1000)));
      expect(position.totalAllocatedPayments, equals(Money.zero(Currency.dzd)));
      expect(position.outstandingDebt, equals(Money.dzd(1000)));
      expect(position.unallocatedCredit, equals(Money.zero(Currency.dzd)));
      expect(position.netPosition, equals(Money.dzd(1000)));
    });

    test('calculates partially paid invoices', () {
      final invoice = createInvoice(
        id: 'inv-1',
        clientId: clientA,
        unitPrice: Money.dzd(1000),
      );
      final payment = createPayment(
        id: 'pay-1',
        clientId: clientA,
        amount: Money.dzd(400),
      );
      final allocation = createAllocation(
        id: 'alloc-1',
        payment: payment,
        invoice: invoice,
        amount: Money.dzd(400),
      );

      final position = ClientFinancialCalculator.calculate(
        clientId: clientA,
        invoices: [invoice],
        payments: [payment],
        allocations: [allocation],
      );

      expect(position.totalInvoiced, equals(Money.dzd(1000)));
      expect(position.totalAllocatedPayments, equals(Money.dzd(400)));
      expect(position.outstandingDebt, equals(Money.dzd(600)));
      expect(position.unallocatedCredit, equals(Money.zero(Currency.dzd)));
      expect(position.netPosition, equals(Money.dzd(600)));
      expect(position.hasOutstandingDebt, isTrue);
    });

    test('calculates fully paid invoices', () {
      final invoice = createInvoice(
        id: 'inv-1',
        clientId: clientA,
        unitPrice: Money.dzd(1000),
      );
      final payment = createPayment(
        id: 'pay-1',
        clientId: clientA,
        amount: Money.dzd(1000),
      );
      final allocation = createAllocation(
        id: 'alloc-1',
        payment: payment,
        invoice: invoice,
        amount: Money.dzd(1000),
      );

      final position = ClientFinancialCalculator.calculate(
        clientId: clientA,
        invoices: [invoice],
        payments: [payment],
        allocations: [allocation],
      );

      expect(position.totalInvoiced, equals(Money.dzd(1000)));
      expect(position.totalAllocatedPayments, equals(Money.dzd(1000)));
      expect(position.outstandingDebt, equals(Money.zero(Currency.dzd)));
      expect(position.unallocatedCredit, equals(Money.zero(Currency.dzd)));
      expect(position.netPosition, equals(Money.zero(Currency.dzd)));
      expect(position.isBalanced, isTrue);
    });
  });

  group(
    'ClientFinancialCalculator - Multi-Invoice Allocations and Credits',
    () {
      test('one payment allocated across multiple invoices', () {
        final inv1 = createInvoice(
          id: 'inv-1',
          clientId: clientA,
          unitPrice: Money.dzd(600),
        );
        final inv2 = createInvoice(
          id: 'inv-2',
          clientId: clientA,
          unitPrice: Money.dzd(500),
        );
        final payment = createPayment(
          id: 'pay-1',
          clientId: clientA,
          amount: Money.dzd(1000),
        );

        final alloc1 = createAllocation(
          id: 'a-1',
          payment: payment,
          invoice: inv1,
          amount: Money.dzd(600),
        );
        final alloc2 = createAllocation(
          id: 'a-2',
          payment: payment,
          invoice: inv2,
          amount: Money.dzd(400),
        );

        final position = ClientFinancialCalculator.calculate(
          clientId: clientA,
          invoices: [inv1, inv2],
          payments: [payment],
          allocations: [alloc1, alloc2],
        );

        expect(position.totalInvoiced, equals(Money.dzd(1100)));
        expect(position.totalAllocatedPayments, equals(Money.dzd(1000)));
        expect(position.outstandingDebt, equals(Money.dzd(100))); // 500 - 400
        expect(position.unallocatedCredit, equals(Money.zero(Currency.dzd)));
        expect(position.netPosition, equals(Money.dzd(100)));
      });

      test('partially unallocated payment creates unallocatedCredit', () {
        final inv = createInvoice(
          id: 'inv-1',
          clientId: clientA,
          unitPrice: Money.dzd(400),
        );
        final payment = createPayment(
          id: 'pay-1',
          clientId: clientA,
          amount: Money.dzd(1000),
        );
        final alloc = createAllocation(
          id: 'a-1',
          payment: payment,
          invoice: inv,
          amount: Money.dzd(400),
        );

        final position = ClientFinancialCalculator.calculate(
          clientId: clientA,
          invoices: [inv],
          payments: [payment],
          allocations: [alloc],
        );

        expect(position.totalInvoiced, equals(Money.dzd(400)));
        expect(position.totalAllocatedPayments, equals(Money.dzd(400)));
        expect(position.outstandingDebt, equals(Money.zero(Currency.dzd)));
        expect(position.unallocatedCredit, equals(Money.dzd(600)));
        expect(
          position.netPosition,
          equals(Money.fromSubunits(-60000, Currency.dzd)),
        );
        expect(position.isNetCreditor, isTrue);
        expect(position.hasUnallocatedCredit, isTrue);
      });

      test('fully unallocated payment with no invoices', () {
        final payment = createPayment(
          id: 'pay-1',
          clientId: clientA,
          amount: Money.dzd(800),
        );

        final position = ClientFinancialCalculator.calculate(
          clientId: clientA,
          payments: [payment],
        );

        expect(position.totalInvoiced, equals(Money.zero(Currency.dzd)));
        expect(
          position.totalAllocatedPayments,
          equals(Money.zero(Currency.dzd)),
        );
        expect(position.outstandingDebt, equals(Money.zero(Currency.dzd)));
        expect(position.unallocatedCredit, equals(Money.dzd(800)));
        expect(
          position.netPosition,
          equals(Money.fromSubunits(-80000, Currency.dzd)),
        );
        expect(position.isNetCreditor, isTrue);
      });
    },
  );

  group('ClientFinancialCalculator - Client Isolation', () {
    test('ignores invoices, payments, and allocations of other clients', () {
      final invA = createInvoice(
        id: 'inv-A',
        clientId: clientA,
        unitPrice: Money.dzd(500),
      );
      final payA = createPayment(
        id: 'pay-A',
        clientId: clientA,
        amount: Money.dzd(500),
      );
      final allocA = createAllocation(
        id: 'a-A',
        payment: payA,
        invoice: invA,
        amount: Money.dzd(500),
      );

      final invB = createInvoice(
        id: 'inv-B',
        clientId: clientB,
        unitPrice: Money.dzd(2000),
      );
      final payB = createPayment(
        id: 'pay-B',
        clientId: clientB,
        amount: Money.dzd(1000),
      );
      final allocB = createAllocation(
        id: 'a-B',
        payment: payB,
        invoice: invB,
        amount: Money.dzd(1000),
      );

      final positionA = ClientFinancialCalculator.calculate(
        clientId: clientA,
        invoices: [invA, invB],
        payments: [payA, payB],
        allocations: [allocA, allocB],
      );

      expect(positionA.totalInvoiced, equals(Money.dzd(500)));
      expect(positionA.totalAllocatedPayments, equals(Money.dzd(500)));
      expect(positionA.outstandingDebt, equals(Money.zero(Currency.dzd)));
      expect(positionA.netPosition, equals(Money.zero(Currency.dzd)));
      expect(positionA.isBalanced, isTrue);
    });
  });

  group(
    'ClientFinancialCalculator - Validation of References & Cross-Client Violations',
    () {
      test('rejects allocation referencing non-existent payment', () {
        final inv = createInvoice(
          id: 'inv-1',
          clientId: clientA,
          unitPrice: Money.dzd(100),
        );
        final nonExistentPay = createPayment(
          id: 'ghost-pay',
          clientId: clientA,
          amount: Money.dzd(100),
        );
        final alloc = createAllocation(
          id: 'a-1',
          payment: nonExistentPay,
          invoice: inv,
          amount: Money.dzd(100),
        );

        expect(
          () => ClientFinancialCalculator.calculate(
            clientId: clientA,
            invoices: [inv],
            payments: const [], // payment missing!
            allocations: [alloc],
          ),
          throwsArgumentError,
        );
      });

      test('rejects allocation referencing non-existent invoice', () {
        final pay = createPayment(
          id: 'pay-1',
          clientId: clientA,
          amount: Money.dzd(100),
        );
        final nonExistentInv = createInvoice(
          id: 'ghost-inv',
          clientId: clientA,
          unitPrice: Money.dzd(100),
        );
        final alloc = createAllocation(
          id: 'a-1',
          payment: pay,
          invoice: nonExistentInv,
          amount: Money.dzd(100),
        );

        expect(
          () => ClientFinancialCalculator.calculate(
            clientId: clientA,
            invoices: const [], // invoice missing!
            payments: [pay],
            allocations: [alloc],
          ),
          throwsArgumentError,
        );
      });

      test(
        'rejects allocation where payment and invoice belong to different clients',
        () {
          final invA = createInvoice(
            id: 'inv-A',
            clientId: clientA,
            unitPrice: Money.dzd(100),
          );
          final payB = createPayment(
            id: 'pay-B',
            clientId: clientB,
            amount: Money.dzd(100),
          );
          final crossAlloc = createAllocation(
            id: 'cross-a',
            payment: payB,
            invoice: invA,
            amount: Money.dzd(100),
          );

          expect(
            () => ClientFinancialCalculator.calculate(
              clientId: clientA,
              invoices: [invA],
              payments: [payB],
              allocations: [crossAlloc],
            ),
            throwsArgumentError,
          );
        },
      );
    },
  );

  group(
    'ClientFinancialCalculator - Currency Consistency and Mismatch Rejection',
    () {
      test(
        'rejects allocation with currency different from payment currency',
        () {
          final inv = createInvoice(
            id: 'inv-1',
            clientId: clientA,
            unitPrice: Money.dzd(100),
          );
          final pay = createPayment(
            id: 'pay-1',
            clientId: clientA,
            amount: Money.dzd(100),
          );
          final usdAlloc = PaymentAllocation.create(
            id: PaymentAllocationId('a-usd'),
            paymentId: pay.id,
            invoiceId: inv.id,
            amount: Money.fromSubunits(100, usdCurrency),
          );

          expect(
            () => ClientFinancialCalculator.calculate(
              clientId: clientA,
              invoices: [inv],
              payments: [pay],
              allocations: [usdAlloc],
            ),
            throwsA(isA<CurrencyMismatchException>()),
          );
        },
      );

      test('rejects mixed currencies between client invoices and payments', () {
        final invDzd = createInvoice(
          id: 'inv-1',
          clientId: clientA,
          unitPrice: Money.dzd(100),
        );
        final payUsd = createPayment(
          id: 'pay-1',
          clientId: clientA,
          amount: Money.fromSubunits(100, usdCurrency),
        );

        expect(
          () => ClientFinancialCalculator.calculate(
            clientId: clientA,
            invoices: [invDzd],
            payments: [payUsd],
          ),
          throwsA(isA<CurrencyMismatchException>()),
        );
      });
    },
  );

  group('ClientFinancialCalculator - Over-Allocation and Duplicate Allocations', () {
    test(
      'rejects payment over-allocation when allocation amount exceeds payment amount',
      () {
        final inv = createInvoice(
          id: 'inv-1',
          clientId: clientA,
          unitPrice: Money.dzd(1000),
        );
        final pay = createPayment(
          id: 'pay-1',
          clientId: clientA,
          amount: Money.dzd(500),
        );
        final overAlloc = createAllocation(
          id: 'a-1',
          payment: pay,
          invoice: inv,
          amount: Money.dzd(600),
        );

        expect(
          () => ClientFinancialCalculator.calculate(
            clientId: clientA,
            invoices: [inv],
            payments: [pay],
            allocations: [overAlloc],
          ),
          throwsArgumentError,
        );
      },
    );

    test(
      'rejects invoice over-allocation when allocation amount exceeds invoice total',
      () {
        final inv = createInvoice(
          id: 'inv-1',
          clientId: clientA,
          unitPrice: Money.dzd(500),
        );
        final pay = createPayment(
          id: 'pay-1',
          clientId: clientA,
          amount: Money.dzd(1000),
        );
        final overAlloc = createAllocation(
          id: 'a-1',
          payment: pay,
          invoice: inv,
          amount: Money.dzd(600),
        );

        expect(
          () => ClientFinancialCalculator.calculate(
            clientId: clientA,
            invoices: [inv],
            payments: [pay],
            allocations: [overAlloc],
          ),
          throwsArgumentError,
        );
      },
    );

    test('rejects duplicate allocation IDs with ArgumentError', () {
      final inv1 = createInvoice(
        id: 'inv-1',
        clientId: clientA,
        unitPrice: Money.dzd(500),
      );
      final inv2 = createInvoice(
        id: 'inv-2',
        clientId: clientA,
        unitPrice: Money.dzd(500),
      );
      final pay = createPayment(
        id: 'pay-1',
        clientId: clientA,
        amount: Money.dzd(1000),
      );

      final alloc1 = PaymentAllocation(
        id: PaymentAllocationId('same-id'),
        paymentId: pay.id,
        invoiceId: inv1.id,
        amount: Money.dzd(200),
        createdAt: DateTime.now(),
      );
      final alloc2 = PaymentAllocation(
        id: PaymentAllocationId('same-id'),
        paymentId: pay.id,
        invoiceId: inv2.id,
        amount: Money.dzd(200),
        createdAt: DateTime.now(),
      );

      expect(
        () => ClientFinancialCalculator.calculate(
          clientId: clientA,
          invoices: [inv1, inv2],
          payments: [pay],
          allocations: [alloc1, alloc2],
        ),
        throwsArgumentError,
      );
    });

    test(
      'rejects duplicate active allocations for the same payment-invoice pair',
      () {
        final inv = createInvoice(
          id: 'inv-1',
          clientId: clientA,
          unitPrice: Money.dzd(500),
        );
        final pay = createPayment(
          id: 'pay-1',
          clientId: clientA,
          amount: Money.dzd(1000),
        );

        final alloc1 = createAllocation(
          id: 'a-1',
          payment: pay,
          invoice: inv,
          amount: Money.dzd(200),
        );
        final alloc2 = createAllocation(
          id: 'a-2',
          payment: pay,
          invoice: inv,
          amount: Money.dzd(200),
        );

        expect(
          () => ClientFinancialCalculator.calculate(
            clientId: clientA,
            invoices: [inv],
            payments: [pay],
            allocations: [alloc1, alloc2],
          ),
          throwsArgumentError,
        );
      },
    );
  });

  group(
    'ClientFinancialPosition - Value Equality and String Representation',
    () {
      test('value equality and hashCode match for identical properties', () {
        final pos1 = ClientFinancialPosition(
          clientId: clientA,
          currency: Currency.dzd,
          totalInvoiced: Money.dzd(1000),
          totalAllocatedPayments: Money.dzd(400),
          outstandingDebt: Money.dzd(600),
          unallocatedCredit: Money.zero(Currency.dzd),
          netPosition: Money.dzd(600),
        );

        final pos2 = ClientFinancialPosition(
          clientId: clientA,
          currency: Currency.dzd,
          totalInvoiced: Money.dzd(1000),
          totalAllocatedPayments: Money.dzd(400),
          outstandingDebt: Money.dzd(600),
          unallocatedCredit: Money.zero(Currency.dzd),
          netPosition: Money.dzd(600),
        );

        expect(pos1, equals(pos2));
        expect(pos1.hashCode, equals(pos2.hashCode));
      });

      test('toString contains all financial position fields', () {
        final pos = ClientFinancialPosition(
          clientId: clientA,
          currency: Currency.dzd,
          totalInvoiced: Money.dzd(1000),
          totalAllocatedPayments: Money.dzd(400),
          outstandingDebt: Money.dzd(600),
          unallocatedCredit: Money.zero(Currency.dzd),
          netPosition: Money.dzd(600),
        );

        final str = pos.toString();
        expect(str, contains('client-A'));
        expect(str, contains('DZD'));
        expect(str, contains('1000.00 DZD'));
        expect(str, contains('400.00 DZD'));
        expect(str, contains('600.00 DZD'));
      });
    },
  );
}
