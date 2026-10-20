import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/in_memory_repositories.dart';

void main() {
  group('Generic & Specialized Repository Hierarchy', () {
    late InMemoryClientRepository clientRepo;
    late InMemoryInvoiceRepository invoiceRepo;
    late InMemoryPaymentRepository paymentRepo;
    late InMemoryPaymentAllocationRepository allocationRepo;
    late InMemoryUnitOfWork unitOfWork;

    setUp(() {
      clientRepo = InMemoryClientRepository();
      invoiceRepo = InMemoryInvoiceRepository();
      paymentRepo = InMemoryPaymentRepository();
      unitOfWork = InMemoryUnitOfWork(
        clientRepository: clientRepo,
        invoiceRepository: invoiceRepo,
        paymentRepository: paymentRepo,
      );
      allocationRepo = unitOfWork.paymentAllocations;
    });

    test(
      'ClientRepository common operations: add, getById, existsById, getAll, deleteById',
      () async {
        final client = Client.create(name: 'Ali Baba', phone: '+2135550001');

        expect(await clientRepo.existsById(client.id), isFalse);
        expect(await clientRepo.getById(client.id), isNull);
        expect(await clientRepo.getAll(), isEmpty);

        await clientRepo.add(client);

        expect(await clientRepo.existsById(client.id), isTrue);
        expect(await clientRepo.getById(client.id), equals(client));
        expect(await clientRepo.getAll(), hasLength(1));

        // Specialized queries
        expect(await clientRepo.getByName('ali baba'), equals(client));
        expect(await clientRepo.existsByName('Ali Baba'), isTrue);
        expect(await clientRepo.existsByName('Unknown'), isFalse);

        await clientRepo.deleteById(client.id);
        expect(await clientRepo.existsById(client.id), isFalse);
        expect(await clientRepo.getAll(), isEmpty);
      },
    );

    test(
      'InvoiceRepository specialized queries: getByClientId and getByNumber',
      () async {
        final clientId = ClientId.generate();
        final line = InvoiceLine.create(
          description: 'Service',
          quantity: 1,
          unitPrice: Money.dzd(10000),
        );
        final draftInvoice = Invoice.draft(
          clientId: clientId,
          number: 'INV-001',
          lines: [line],
        );
        final issuedInvoice = Invoice.draft(
          clientId: clientId,
          number: 'INV-002',
          lines: [line],
        ).issue();

        await invoiceRepo.add(draftInvoice);
        await invoiceRepo.add(issuedInvoice);

        final clientInvoices = await invoiceRepo.getByClientId(clientId);
        expect(clientInvoices, hasLength(2));

        final drafts = await invoiceRepo.getByClientId(
          clientId,
          status: InvoiceStatus.draft,
        );
        expect(drafts, hasLength(1));
        expect(drafts.first.number, 'INV-001');

        final issued = await invoiceRepo.getByClientId(
          clientId,
          status: InvoiceStatus.issued,
        );
        expect(issued, hasLength(1));
        expect(issued.first.number, 'INV-002');

        final byNumber = await invoiceRepo.getByNumber('INV-001');
        expect(byNumber, equals(draftInvoice));

        final notFound = await invoiceRepo.getByNumber('NON-EXISTENT');
        expect(notFound, isNull);
      },
    );

    test('PaymentRepository specialized query: getByClientId', () async {
      final client1 = ClientId.generate();
      final client2 = ClientId.generate();

      final p1 = Payment.create(clientId: client1, amount: Money.dzd(5000));
      final p2 = Payment.create(clientId: client1, amount: Money.dzd(3000));
      final p3 = Payment.create(clientId: client2, amount: Money.dzd(10000));

      await paymentRepo.add(p1);
      await paymentRepo.add(p2);
      await paymentRepo.add(p3);

      final client1Payments = await paymentRepo.getByClientId(client1);
      expect(client1Payments, hasLength(2));
      expect(client1Payments, containsAll([p1, p2]));

      final client2Payments = await paymentRepo.getByClientId(client2);
      expect(client2Payments, hasLength(1));
      expect(client2Payments.first, equals(p3));
    });

    test(
      'PaymentAllocationRepository queries by payment, invoice, and pair',
      () async {
        final pId = PaymentId.generate();
        final inv1 = InvoiceId.generate();
        final inv2 = InvoiceId.generate();

        final a1 = PaymentAllocation.create(
          paymentId: pId,
          invoiceId: inv1,
          amount: Money.dzd(2000),
        );
        final a2 = PaymentAllocation.create(
          paymentId: pId,
          invoiceId: inv2,
          amount: Money.dzd(3000),
        );

        await allocationRepo.add(a1);
        await allocationRepo.add(a2);

        final byPayment = await allocationRepo.getByPaymentId(pId);
        expect(byPayment, hasLength(2));

        final byInvoice = await allocationRepo.getByInvoiceId(inv1);
        expect(byInvoice, hasLength(1));
        expect(byInvoice.first, equals(a1));

        final pair = await allocationRepo.getByPaymentAndInvoice(pId, inv1);
        expect(pair, equals(a1));

        final noPair = await allocationRepo.getByPaymentAndInvoice(
          pId,
          InvoiceId.generate(),
        );
        expect(noPair, isNull);
      },
    );

    test(
      'UnitOfWork executes atomically and rolls back on exception',
      () async {
        final client = Client.create(name: 'Transaction Test');

        await expectLater(
          () => unitOfWork.saveChangesAsync((scope) async {
            await scope.clients.add(client);
            throw Exception('Simulated DB failure during transaction');
          }),
          throwsA(isA<Exception>()),
        );

        // Verify that add was rolled back
        expect(await clientRepo.existsById(client.id), isFalse);
      },
    );
  });
}
