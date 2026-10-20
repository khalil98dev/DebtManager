import 'package:application/application.dart';
import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/in_memory_repositories.dart';

void main() {
  group('GetClientFinancialPosition Query', () {
    late InMemoryUnitOfWork unitOfWork;
    late GetClientFinancialPosition getClientFinancialPosition;
    late Client client;

    setUp(() async {
      unitOfWork = InMemoryUnitOfWork();
      getClientFinancialPosition = GetClientFinancialPosition(
        clientRepository: unitOfWork.clients,
        invoiceRepository: unitOfWork.invoices,
        paymentRepository: unitOfWork.payments,
        paymentAllocationRepository: unitOfWork.paymentAllocations,
      );

      client = Client.create(name: 'Financial Client');
      await unitOfWork.clients.add(client);
    });

    test(
      'calculates accurate financial position with issued invoices, payments, and allocations',
      () async {
        // 1. Create two issued invoices (10,000 DZD and 5,000 DZD) and one draft invoice (20,000 DZD)
        final line1 = InvoiceLine.create(
          description: 'Item 1',
          quantity: 1,
          unitPrice: Money.dzd(10000),
        );
        final line2 = InvoiceLine.create(
          description: 'Item 2',
          quantity: 1,
          unitPrice: Money.dzd(5000),
        );
        final draftLine = InvoiceLine.create(
          description: 'Draft item',
          quantity: 1,
          unitPrice: Money.dzd(20000),
        );

        final inv1 = Invoice.draft(
          clientId: client.id,
          number: 'INV-1',
          lines: [line1],
        ).issue();
        final inv2 = Invoice.draft(
          clientId: client.id,
          number: 'INV-2',
          lines: [line2],
        ).issue();
        final draftInv = Invoice.draft(
          clientId: client.id,
          number: 'INV-DRAFT',
          lines: [draftLine],
        );

        await unitOfWork.invoices.add(inv1);
        await unitOfWork.invoices.add(inv2);
        await unitOfWork.invoices.add(draftInv);

        // 2. Create payment of 12,000 DZD
        final payment = Payment.create(
          clientId: client.id,
          amount: Money.dzd(12000),
        );
        await unitOfWork.payments.add(payment);

        // 3. Allocate 8,000 DZD to inv1 and 2,000 DZD to inv2 (total allocated: 10,000 DZD)
        final alloc1 = PaymentAllocation.create(
          paymentId: payment.id,
          invoiceId: inv1.id,
          amount: Money.dzd(8000),
        );
        final alloc2 = PaymentAllocation.create(
          paymentId: payment.id,
          invoiceId: inv2.id,
          amount: Money.dzd(2000),
        );
        await unitOfWork.paymentAllocations.add(alloc1);
        await unitOfWork.paymentAllocations.add(alloc2);

        final result = await getClientFinancialPosition.execute(
          GetClientFinancialPositionQuery(clientId: client.id),
        );

        expect(result.isSuccess, isTrue);
        final pos = result.dataOrNull!;
        expect(pos.clientId, client.id);
        expect(pos.currency, Currency.dzd);
        // Total invoiced across issued invoices: 10,000 + 5,000 = 15,000 DZD (draft 20,000 excluded)
        expect(pos.totalInvoiced, equals(Money.dzd(15000)));
        // Total allocated payments: 8,000 + 2,000 = 10,000 DZD
        expect(pos.totalAllocatedPayments, equals(Money.dzd(10000)));
        // Outstanding debt: 15,000 - 10,000 = 5,000 DZD
        expect(pos.outstandingDebt, equals(Money.dzd(5000)));
        // Unallocated credit: 12,000 - 10,000 = 2,000 DZD
        expect(pos.unallocatedCredit, equals(Money.dzd(2000)));
        // Net position: 5,000 - 2,000 = +3,000 DZD (net debtor)
        expect(pos.netPosition, equals(Money.dzd(3000)));
        expect(pos.isNetDebtor, isTrue);
      },
    );

    test('returns NotFoundFailure when client does not exist', () async {
      final missingClientId = ClientId.generate();
      final result = await getClientFinancialPosition.execute(
        GetClientFinancialPositionQuery(clientId: missingClientId),
      );

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<NotFoundFailure>());
      final nf = result.failureOrNull! as NotFoundFailure;
      expect(nf.entityType, 'Client');
      expect(nf.entityId, missingClientId);
    });

    test(
      'returns zero financial position for client with no records',
      () async {
        final result = await getClientFinancialPosition.execute(
          GetClientFinancialPositionQuery(
            clientId: client.id,
            currency: Currency.dzd,
          ),
        );

        expect(result.isSuccess, isTrue);
        final pos = result.dataOrNull!;
        expect(pos.totalInvoiced, equals(Money.zero(Currency.dzd)));
        expect(pos.totalAllocatedPayments, equals(Money.zero(Currency.dzd)));
        expect(pos.outstandingDebt, equals(Money.zero(Currency.dzd)));
        expect(pos.unallocatedCredit, equals(Money.zero(Currency.dzd)));
        expect(pos.netPosition, equals(Money.zero(Currency.dzd)));
        expect(pos.isBalanced, isTrue);
      },
    );

    test(
      'returns ValidationFailure when client records have mismatched currencies',
      () async {
        final eur = Currency(code: 'EUR');
        final line = InvoiceLine.create(
          description: 'DZD service',
          quantity: 1,
          unitPrice: Money.dzd(5000),
        );
        final inv = Invoice.draft(
          clientId: client.id,
          number: 'INV-DZD',
          lines: [line],
        ).issue();
        await unitOfWork.invoices.add(inv);

        final eurPayment = Payment.create(
          clientId: client.id,
          amount: Money.fromSubunits(5000, eur),
        );
        await unitOfWork.payments.add(eurPayment);

        final result = await getClientFinancialPosition.execute(
          GetClientFinancialPositionQuery(clientId: client.id),
        );

        expect(result.isFailure, isTrue);
        expect(result.failureOrNull, isA<ValidationFailure>());
        expect(
          result.failureOrNull!.message,
          contains('mismatched currencies'),
        );
      },
    );

    test(
      'computes position for pure debtor with only issued invoices',
      () async {
        final line = InvoiceLine.create(
          description: 'Unpaid service',
          quantity: 1,
          unitPrice: Money.dzd(30000),
        );
        final inv = Invoice.draft(
          clientId: client.id,
          number: 'INV-DEBTOR',
          lines: [line],
        ).issue();
        await unitOfWork.invoices.add(inv);

        final result = await getClientFinancialPosition.execute(
          GetClientFinancialPositionQuery(clientId: client.id),
        );

        expect(result.isSuccess, isTrue);
        final pos = result.dataOrNull!;
        expect(pos.totalInvoiced, equals(Money.dzd(30000)));
        expect(pos.totalAllocatedPayments, equals(Money.zero(Currency.dzd)));
        expect(pos.outstandingDebt, equals(Money.dzd(30000)));
        expect(pos.unallocatedCredit, equals(Money.zero(Currency.dzd)));
        expect(pos.netPosition, equals(Money.dzd(30000)));
        expect(pos.isNetDebtor, isTrue);
        expect(pos.isNetCreditor, isFalse);
      },
    );

    test(
      'computes position for pure creditor with only unallocated payments',
      () async {
        final payment = Payment.create(
          clientId: client.id,
          amount: Money.dzd(15000),
        );
        await unitOfWork.payments.add(payment);

        final result = await getClientFinancialPosition.execute(
          GetClientFinancialPositionQuery(clientId: client.id),
        );

        expect(result.isSuccess, isTrue);
        final pos = result.dataOrNull!;
        expect(pos.totalInvoiced, equals(Money.zero(Currency.dzd)));
        expect(pos.totalAllocatedPayments, equals(Money.zero(Currency.dzd)));
        expect(pos.outstandingDebt, equals(Money.zero(Currency.dzd)));
        expect(pos.unallocatedCredit, equals(Money.dzd(15000)));
        expect(pos.netPosition, equals(Money.dzd(-15000)));
        expect(pos.isNetCreditor, isTrue);
        expect(pos.isNetDebtor, isFalse);
      },
    );
  });
}
