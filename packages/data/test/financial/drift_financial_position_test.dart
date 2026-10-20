import 'package:application/application.dart';
import 'package:data/data.dart';
import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late DriftClientRepository clientRepo;
  late DriftInvoiceRepository invoiceRepo;
  late DriftPaymentRepository paymentRepo;
  late DriftPaymentAllocationRepository allocationRepo;
  late GetClientFinancialPosition getFinancialPosition;

  final clientA = Client(
    id: ClientId.fromString('client-fin-a'),
    name: 'Societe Batiment Algerie',
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
  );

  setUp(() async {
    db = AppDatabase.inMemory();
    clientRepo = DriftClientRepository(db);
    invoiceRepo = DriftInvoiceRepository(db);
    paymentRepo = DriftPaymentRepository(db);
    allocationRepo = DriftPaymentAllocationRepository(db);

    getFinancialPosition = GetClientFinancialPosition(
      clientRepository: clientRepo,
      invoiceRepository: invoiceRepo,
      paymentRepository: paymentRepo,
      paymentAllocationRepository: allocationRepo,
    );

    await clientRepo.add(clientA);
  });

  tearDown(() async {
    await db.close();
  });

  group('GetClientFinancialPosition with Drift SQLite Repositories', () {
    test(
      'calculates correct position for net debtor with partial payments and draft invoices',
      () async {
        // 1. Issued Invoice 1: 10,000 DZD
        final inv1Line = InvoiceLine(
          id: InvoiceLineId.fromString('l-1'),
          description: 'Cement bags',
          quantity: 10,
          unitPrice: Money.fromSubunits(
            100000,
            Currency.dzd,
          ), // 1,000 DZD each = 10,000 DZD
          createdAt: DateTime.utc(2026, 1, 5),
        );
        final inv1 = Invoice.draft(
          id: InvoiceId.fromString('inv-1'),
          clientId: clientA.id,
          number: 'INV-2026-001',
          lines: [inv1Line],
          currency: Currency.dzd,
          createdAt: DateTime.utc(2026, 1, 5),
        ).issue(issuedAt: DateTime.utc(2026, 1, 6));
        await invoiceRepo.add(inv1);

        // 2. Issued Invoice 2: 25,000 DZD
        final inv2Line = InvoiceLine(
          id: InvoiceLineId.fromString('l-2'),
          description: 'Steel rods',
          quantity: 5,
          unitPrice: Money.fromSubunits(
            500000,
            Currency.dzd,
          ), // 5,000 DZD each = 25,000 DZD
          createdAt: DateTime.utc(2026, 1, 10),
        );
        final inv2 = Invoice.draft(
          id: InvoiceId.fromString('inv-2'),
          clientId: clientA.id,
          number: 'INV-2026-002',
          lines: [inv2Line],
          currency: Currency.dzd,
          createdAt: DateTime.utc(2026, 1, 10),
        ).issue(issuedAt: DateTime.utc(2026, 1, 11));
        await invoiceRepo.add(inv2);

        // 3. Draft Invoice 3: 50,000 DZD (must be EXCLUDED from debt calculations!)
        final inv3Line = InvoiceLine(
          id: InvoiceLineId.fromString('l-3'),
          description: 'Draft estimate',
          quantity: 1,
          unitPrice: Money.fromSubunits(5000000, Currency.dzd),
          createdAt: DateTime.utc(2026, 1, 15),
        );
        final inv3Draft = Invoice.draft(
          id: InvoiceId.fromString('inv-3-draft'),
          clientId: clientA.id,
          number: 'INV-2026-003',
          lines: [inv3Line],
          currency: Currency.dzd,
          createdAt: DateTime.utc(2026, 1, 15),
        );
        await invoiceRepo.add(inv3Draft);

        // 4. Payment 1: 15,000 DZD
        final payment1 = Payment(
          id: PaymentId.fromString('p-1'),
          clientId: clientA.id,
          amount: Money.fromSubunits(1500000, Currency.dzd), // 15,000 DZD
          receivedAt: DateTime.utc(2026, 1, 12),
          createdAt: DateTime.utc(2026, 1, 12),
        );
        await paymentRepo.add(payment1);

        // 5. Allocate 10,000 DZD from payment1 to inv1 (fully paying inv1)
        final alloc1 = PaymentAllocation(
          id: PaymentAllocationId.fromString('a-1'),
          paymentId: payment1.id,
          invoiceId: inv1.id,
          amount: Money.fromSubunits(1000000, Currency.dzd), // 10,000 DZD
          createdAt: DateTime.utc(2026, 1, 13),
        );
        await allocationRepo.add(alloc1);

        // Now calculate position:
        // totalInvoiced: 10,000 + 25,000 = 35,000 DZD (draft invoice excluded)
        // totalAllocatedPayments: 10,000 DZD
        // outstandingDebt: (10,000 - 10,000) + (25,000 - 0) = 25,000 DZD
        // unallocatedCredit: 15,000 - 10,000 = 5,000 DZD
        // netPosition: 25,000 - 5,000 = 20,000 DZD (positive: debtor)
        final result = await getFinancialPosition.execute(
          GetClientFinancialPositionQuery(clientId: clientA.id),
        );

        expect(result.isSuccess, isTrue);
        final position = result.dataOrNull!;

        expect(
          position.totalInvoiced,
          equals(Money.fromSubunits(3500000, Currency.dzd)),
        );
        expect(
          position.totalAllocatedPayments,
          equals(Money.fromSubunits(1000000, Currency.dzd)),
        );
        expect(
          position.outstandingDebt,
          equals(Money.fromSubunits(2500000, Currency.dzd)),
        );
        expect(
          position.unallocatedCredit,
          equals(Money.fromSubunits(500000, Currency.dzd)),
        );
        expect(
          position.netPosition,
          equals(Money.fromSubunits(2000000, Currency.dzd)),
        );

        expect(position.hasOutstandingDebt, isTrue);
        expect(position.hasUnallocatedCredit, isTrue);
        expect(position.isNetDebtor, isTrue);
        expect(position.isNetCreditor, isFalse);
        expect(position.isBalanced, isFalse);
      },
    );

    test(
      'calculates correct position for net creditor (advance payment)',
      () async {
        // Payment of 50,000 DZD with no issued invoices
        final payment = Payment(
          id: PaymentId.fromString('p-adv'),
          clientId: clientA.id,
          amount: Money.fromSubunits(5000000, Currency.dzd),
          receivedAt: DateTime.utc(2026, 1, 1),
          createdAt: DateTime.utc(2026, 1, 1),
        );
        await paymentRepo.add(payment);

        final result = await getFinancialPosition.execute(
          GetClientFinancialPositionQuery(clientId: clientA.id),
        );

        expect(result.isSuccess, isTrue);
        final position = result.dataOrNull!;

        expect(position.totalInvoiced, equals(Money.zero(Currency.dzd)));
        expect(position.outstandingDebt, equals(Money.zero(Currency.dzd)));
        expect(
          position.unallocatedCredit,
          equals(Money.fromSubunits(5000000, Currency.dzd)),
        );
        expect(
          position.netPosition,
          equals(Money.fromSubunits(-5000000, Currency.dzd)),
        );

        expect(position.isNetCreditor, isTrue);
        expect(position.isNetDebtor, isFalse);
        expect(position.isBalanced, isFalse);
      },
    );

    test(
      'calculates completely balanced position when all invoices are fully paid',
      () async {
        // Invoice: 20,000 DZD
        final line = InvoiceLine(
          id: InvoiceLineId.fromString('l-bal'),
          description: 'Service',
          quantity: 1,
          unitPrice: Money.fromSubunits(2000000, Currency.dzd),
          createdAt: DateTime.utc(2026, 1, 1),
        );
        final invoice = Invoice.draft(
          id: InvoiceId.fromString('inv-bal'),
          clientId: clientA.id,
          number: 'INV-BAL-01',
          lines: [line],
          currency: Currency.dzd,
          createdAt: DateTime.utc(2026, 1, 1),
        ).issue(issuedAt: DateTime.utc(2026, 1, 1));
        await invoiceRepo.add(invoice);

        // Payment: 20,000 DZD
        final payment = Payment(
          id: PaymentId.fromString('p-bal'),
          clientId: clientA.id,
          amount: Money.fromSubunits(2000000, Currency.dzd),
          receivedAt: DateTime.utc(2026, 1, 2),
          createdAt: DateTime.utc(2026, 1, 2),
        );
        await paymentRepo.add(payment);

        // Allocate full 20,000 DZD
        final alloc = PaymentAllocation(
          id: PaymentAllocationId.fromString('a-bal'),
          paymentId: payment.id,
          invoiceId: invoice.id,
          amount: Money.fromSubunits(2000000, Currency.dzd),
          createdAt: DateTime.utc(2026, 1, 2),
        );
        await allocationRepo.add(alloc);

        final result = await getFinancialPosition.execute(
          GetClientFinancialPositionQuery(clientId: clientA.id),
        );

        expect(result.isSuccess, isTrue);
        final position = result.dataOrNull!;

        expect(position.outstandingDebt, equals(Money.zero(Currency.dzd)));
        expect(position.unallocatedCredit, equals(Money.zero(Currency.dzd)));
        expect(position.netPosition, equals(Money.zero(Currency.dzd)));
        expect(position.isBalanced, isTrue);
      },
    );

    test('returns NotFoundFailure when client does not exist', () async {
      final result = await getFinancialPosition.execute(
        GetClientFinancialPositionQuery(
          clientId: ClientId.fromString('non-existent'),
        ),
      );

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<NotFoundFailure>());
    });
  });
}
