import 'package:application/application.dart';
import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/in_memory_repositories.dart';

void main() {
  group('GetDashboardSummary Query', () {
    late InMemoryClientRepository clientRepo;
    late InMemoryInvoiceRepository invoiceRepo;
    late InMemoryPaymentRepository paymentRepo;
    late InMemoryPaymentAllocationRepository allocRepo;
    late GetDashboardSummary query;

    setUp(() {
      clientRepo = InMemoryClientRepository();
      invoiceRepo = InMemoryInvoiceRepository();
      paymentRepo = InMemoryPaymentRepository();
      allocRepo = InMemoryPaymentAllocationRepository();
      query = GetDashboardSummary(
        clientRepository: clientRepo,
        invoiceRepository: invoiceRepo,
        paymentRepository: paymentRepo,
        paymentAllocationRepository: allocRepo,
      );
    });

    test('returns empty metrics when database is empty', () async {
      final result = await query.execute(const GetDashboardSummaryQuery());

      expect(result.isSuccess, isTrue);
      final summary = result.dataOrNull!;
      expect(summary.totalClients, equals(0));
      expect(summary.totalDraftInvoices, equals(0));
      expect(summary.totalIssuedInvoices, equals(0));
      expect(summary.totalBilled, equals(Money.zero(Currency.dzd)));
      expect(summary.totalOutstandingDebt, equals(Money.zero(Currency.dzd)));
      expect(summary.totalUnallocatedCredit, equals(Money.zero(Currency.dzd)));
      expect(summary.netPosition, equals(Money.zero(Currency.dzd)));
      expect(summary.recentInvoices, isEmpty);
      expect(summary.recentPayments, isEmpty);
    });

    test(
      'correctly aggregates clients, draft/issued invoices, debt, credit, and recent items',
      () async {
        final client = Client.create(name: 'Client One');
        await clientRepo.add(client);

        // Draft invoice: 500 DZD (should NOT count in totalBilled)
        final draft = Invoice.draft(
          clientId: client.id,
          number: 'INV-DRAFT',
          lines: [
            InvoiceLine(
              id: InvoiceLineId.generate(),
              description: 'Draft item',
              quantity: 1,
              unitPrice: Money.fromSubunits(50000, Currency.dzd),
              createdAt: DateTime.now(),
            ),
          ],
        );
        await invoiceRepo.add(draft);

        // Issued invoice: 2000 DZD
        final issued = Invoice.draft(
          clientId: client.id,
          number: 'INV-ISSUED',
          createdAt: DateTime.utc(2026, 3, 1, 9, 0),
          lines: [
            InvoiceLine(
              id: InvoiceLineId.generate(),
              description: 'Issued item',
              quantity: 2,
              unitPrice: Money.fromSubunits(100000, Currency.dzd),
              createdAt: DateTime.utc(2026, 3, 1, 9, 0),
            ),
          ],
        ).issue(issuedAt: DateTime.utc(2026, 3, 1, 10, 0));
        await invoiceRepo.add(issued);

        // Payment: 1500 DZD
        final payment = Payment(
          id: PaymentId.generate(),
          clientId: client.id,
          amount: Money.fromSubunits(150000, Currency.dzd),
          receivedAt: DateTime.utc(2026, 3, 1, 11, 0),
          createdAt: DateTime.utc(2026, 3, 1, 11, 0),
        );
        await paymentRepo.add(payment);

        // Allocation: 1000 DZD from payment to issued invoice
        final alloc = PaymentAllocation(
          id: PaymentAllocationId.generate(),
          paymentId: payment.id,
          invoiceId: issued.id,
          amount: Money.fromSubunits(100000, Currency.dzd),
          createdAt: DateTime.utc(2026, 3, 1, 12, 0),
        );
        await allocRepo.add(alloc);

        final result = await query.execute(const GetDashboardSummaryQuery());

        expect(result.isSuccess, isTrue);
        final summary = result.dataOrNull!;
        expect(summary.totalClients, equals(1));
        expect(summary.totalDraftInvoices, equals(1));
        expect(summary.totalIssuedInvoices, equals(1));
        expect(
          summary.totalBilled,
          equals(Money.fromSubunits(200000, Currency.dzd)),
        );
        expect(
          summary.totalAllocatedPayments,
          equals(Money.fromSubunits(100000, Currency.dzd)),
        );
        // Outstanding debt: 2000 - 1000 = 1000 DZD
        expect(
          summary.totalOutstandingDebt,
          equals(Money.fromSubunits(100000, Currency.dzd)),
        );
        // Unallocated credit: 1500 - 1000 = 500 DZD
        expect(
          summary.totalUnallocatedCredit,
          equals(Money.fromSubunits(50000, Currency.dzd)),
        );
        // Net position: 1000 - 500 = 500 DZD
        expect(
          summary.netPosition,
          equals(Money.fromSubunits(50000, Currency.dzd)),
        );

        expect(summary.recentInvoices.length, equals(2));
        expect(summary.recentPayments.length, equals(1));
      },
    );
  });
}
