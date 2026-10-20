import 'package:application/application.dart';
import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/in_memory_repositories.dart';

void main() {
  group('Application Package Exports & End-to-End Orchestration', () {
    test(
      'orchestrates full debt lifecycle across application use cases',
      () async {
        final unitOfWork = InMemoryUnitOfWork();
        final createClient = CreateClient(unitOfWork.clients);
        final createInvoice = CreateInvoice(
          clientRepository: unitOfWork.clients,
          invoiceRepository: unitOfWork.invoices,
        );
        final issueInvoice = IssueInvoice(unitOfWork.invoices);
        final recordPayment = RecordPayment(
          clientRepository: unitOfWork.clients,
          paymentRepository: unitOfWork.payments,
        );
        final allocatePayment = AllocatePayment(unitOfWork);
        final getFinancialPosition = GetClientFinancialPosition(
          clientRepository: unitOfWork.clients,
          invoiceRepository: unitOfWork.invoices,
          paymentRepository: unitOfWork.payments,
          paymentAllocationRepository: unitOfWork.paymentAllocations,
        );

        // 1. Create Client
        final clientResult = await createClient.execute(
          const CreateClientCommand(name: 'Enterprise Client Corp'),
        );
        expect(clientResult.isSuccess, isTrue);
        final client = clientResult.dataOrNull!;

        // 2. Create Draft Invoice
        final line = InvoiceLine.create(
          description: 'Monthly Maintenance',
          quantity: 2,
          unitPrice: Money.dzd(25000), // 250.00 DZD * 2 = 500.00 DZD
        );
        final invoiceResult = await createInvoice.execute(
          CreateInvoiceCommand(
            clientId: client.id,
            number: 'INV-2026-E2E',
            lines: [line],
          ),
        );
        expect(invoiceResult.isSuccess, isTrue);
        final draftInvoice = invoiceResult.dataOrNull!;
        expect(draftInvoice.isDraft, isTrue);

        // 3. Issue Invoice
        final issueResult = await issueInvoice.execute(
          IssueInvoiceCommand(invoiceId: draftInvoice.id),
        );
        expect(issueResult.isSuccess, isTrue);
        final issuedInvoice = issueResult.dataOrNull!;
        expect(issuedInvoice.isIssued, isTrue);

        // 4. Record Payment
        final paymentResult = await recordPayment.execute(
          RecordPaymentCommand(
            clientId: client.id,
            amount: Money.dzd(60000), // 600.00 DZD
          ),
        );
        expect(paymentResult.isSuccess, isTrue);
        final payment = paymentResult.dataOrNull!;

        // 5. Allocate Payment to Invoice
        final allocResult = await allocatePayment.execute(
          AllocatePaymentCommand(
            paymentId: payment.id,
            invoiceId: issuedInvoice.id,
            amount: Money.dzd(50000), // Fully pays off the 50,000 DZD invoice
          ),
        );
        expect(allocResult.isSuccess, isTrue);

        // 6. Get Client Financial Position
        final posResult = await getFinancialPosition.execute(
          GetClientFinancialPositionQuery(clientId: client.id),
        );
        expect(posResult.isSuccess, isTrue);
        final pos = posResult.dataOrNull!;

        // Total Invoiced: 50,000 DZD
        expect(pos.totalInvoiced, equals(Money.dzd(50000)));
        // Total Allocated: 50,000 DZD
        expect(pos.totalAllocatedPayments, equals(Money.dzd(50000)));
        // Outstanding Debt: 0 DZD (fully paid)
        expect(pos.outstandingDebt, equals(Money.zero(Currency.dzd)));
        // Unallocated Credit: 60,000 - 50,000 = 10,000 DZD
        expect(pos.unallocatedCredit, equals(Money.dzd(10000)));
        // Net Position: 0 - 10,000 = -10,000 DZD (net creditor)
        expect(pos.netPosition, equals(Money.dzd(-10000)));
        expect(pos.isNetCreditor, isTrue);
      },
    );
  });
}
