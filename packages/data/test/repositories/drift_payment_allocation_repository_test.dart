import 'package:application/application.dart';
import 'package:data/data.dart';
import 'package:domain/domain.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late DriftClientRepository clientRepo;
  late DriftInvoiceRepository invoiceRepo;
  late DriftPaymentRepository paymentRepo;
  late DriftPaymentAllocationRepository allocationRepo;
  late DriftUnitOfWork unitOfWork;

  final testClient = Client(
    id: ClientId.fromString('client-alloc-1'),
    name: 'Mustapha Dali',
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
  );

  setUp(() async {
    db = AppDatabase.inMemory();
    clientRepo = DriftClientRepository(db);
    invoiceRepo = DriftInvoiceRepository(db);
    paymentRepo = DriftPaymentRepository(db);
    allocationRepo = DriftPaymentAllocationRepository(db);
    unitOfWork = DriftUnitOfWork(db);

    await clientRepo.add(testClient);
  });

  tearDown(() async {
    await db.close();
  });

  // Helper to create an issued invoice
  Future<Invoice> createIssuedInvoice({
    required String id,
    required String number,
    required int amountSubunits,
  }) async {
    final line = InvoiceLine(
      id: InvoiceLineId.fromString('line-$id'),
      description: 'Invoice service',
      quantity: 1,
      unitPrice: Money.fromSubunits(amountSubunits, Currency.dzd),
      createdAt: DateTime.utc(2026, 1, 1),
    );
    final invoice = Invoice.draft(
      id: InvoiceId.fromString(id),
      clientId: testClient.id,
      number: number,
      lines: [line],
      currency: Currency.dzd,
      createdAt: DateTime.utc(2026, 1, 1),
    ).issue(issuedAt: DateTime.utc(2026, 1, 2));

    await invoiceRepo.add(invoice);
    return invoice;
  }

  // Helper to create a payment
  Future<Payment> createPayment({
    required String id,
    required int amountSubunits,
  }) async {
    final payment = Payment(
      id: PaymentId.fromString(id),
      clientId: testClient.id,
      amount: Money.fromSubunits(amountSubunits, Currency.dzd),
      receivedAt: DateTime.utc(2026, 1, 3),
      createdAt: DateTime.utc(2026, 1, 3),
    );
    await paymentRepo.add(payment);
    return payment;
  }

  group('DriftUnitOfWork - Atomic Transaction Boundaries', () {
    test(
      'commits changes across multiple repositories when action succeeds',
      () async {
        await unitOfWork.saveChangesAsync((scope) async {
          final newClient = Client(
            id: ClientId.fromString('c-uow-1'),
            name: 'UOW Client',
            createdAt: DateTime.utc(2026, 1, 1),
            updatedAt: DateTime.utc(2026, 1, 1),
          );
          await scope.clients.add(newClient);

          final newPayment = Payment(
            id: PaymentId.fromString('p-uow-1'),
            clientId: newClient.id,
            amount: Money.fromSubunits(50000, Currency.dzd),
            receivedAt: DateTime.utc(2026, 1, 2),
            createdAt: DateTime.utc(2026, 1, 2),
          );
          await scope.payments.add(newPayment);
        });

        expect(
          await clientRepo.existsById(ClientId.fromString('c-uow-1')),
          isTrue,
        );
        expect(
          await paymentRepo.existsById(PaymentId.fromString('p-uow-1')),
          isTrue,
        );
      },
    );

    test(
      'rolls back entire transaction across repositories when exception is thrown',
      () async {
        try {
          await unitOfWork.saveChangesAsync((scope) async {
            final newClient = Client(
              id: ClientId.fromString('c-uow-rollback'),
              name: 'Rollback Client',
              createdAt: DateTime.utc(2026, 1, 1),
              updatedAt: DateTime.utc(2026, 1, 1),
            );
            await scope.clients.add(newClient);

            // Force an intentional failure after inserting client
            throw StateError(
              'Simulated unexpected network or validation failure',
            );
          });
        } catch (_) {}

        // Verify client was NOT persisted due to rollback
        expect(
          await clientRepo.existsById(ClientId.fromString('c-uow-rollback')),
          isFalse,
        );
      },
    );
  });

  group('DriftPaymentAllocationRepository - Queries & Integrity', () {
    test(
      'persists allocation and queries by payment, invoice, and pair',
      () async {
        final invoice = await createIssuedInvoice(
          id: 'inv-a-1',
          number: 'INV-A-001',
          amountSubunits: 100000,
        );
        final payment = await createPayment(
          id: 'pay-a-1',
          amountSubunits: 100000,
        );

        final allocation = PaymentAllocation(
          id: PaymentAllocationId.fromString('alloc-1'),
          paymentId: payment.id,
          invoiceId: invoice.id,
          amount: Money.fromSubunits(60000, Currency.dzd),
          createdAt: DateTime.utc(2026, 1, 5),
        );

        await allocationRepo.add(allocation);

        final retrieved = await allocationRepo.getById(allocation.id);
        expect(retrieved, isNotNull);
        expect(retrieved!.id, equals(allocation.id));
        expect(
          retrieved.amount,
          equals(Money.fromSubunits(60000, Currency.dzd)),
        );

        // Query by payment ID
        final byPayment = await allocationRepo.getByPaymentId(payment.id);
        expect(byPayment.length, equals(1));
        expect(byPayment.first.id, equals(allocation.id));

        // Query by invoice ID
        final byInvoice = await allocationRepo.getByInvoiceId(invoice.id);
        expect(byInvoice.length, equals(1));
        expect(byInvoice.first.id, equals(allocation.id));

        // Query by pair
        final byPair = await allocationRepo.getByPaymentAndInvoice(
          payment.id,
          invoice.id,
        );
        expect(byPair, isNotNull);
        expect(byPair!.id, equals(allocation.id));

        // Query by client ID (via join)
        final byClient = await allocationRepo.getByClientId(testClient.id);
        expect(byClient.length, equals(1));
        expect(byClient.first.id, equals(allocation.id));
      },
    );

    test(
      'rejects duplicate allocation between same payment and invoice via unique constraint',
      () async {
        final invoice = await createIssuedInvoice(
          id: 'inv-dup',
          number: 'INV-DUP-01',
          amountSubunits: 50000,
        );
        final payment = await createPayment(
          id: 'pay-dup',
          amountSubunits: 50000,
        );

        final alloc1 = PaymentAllocation(
          id: PaymentAllocationId.fromString('alloc-dup-1'),
          paymentId: payment.id,
          invoiceId: invoice.id,
          amount: Money.fromSubunits(20000, Currency.dzd),
          createdAt: DateTime.utc(2026, 1, 5),
        );
        final alloc2 = PaymentAllocation(
          id: PaymentAllocationId.fromString('alloc-dup-2'),
          paymentId: payment.id,
          invoiceId: invoice.id,
          amount: Money.fromSubunits(10000, Currency.dzd),
          createdAt: DateTime.utc(2026, 1, 6),
        );

        await allocationRepo.add(alloc1);

        expect(
          () => allocationRepo.add(alloc2),
          throwsA(isA<SqliteException>()),
        );
      },
    );

    test(
      'foreign key restrict prevents deleting payment or invoice that has allocations',
      () async {
        final invoice = await createIssuedInvoice(
          id: 'inv-fk-alloc',
          number: 'INV-FK-ALLOC',
          amountSubunits: 50000,
        );
        final payment = await createPayment(
          id: 'pay-fk-alloc',
          amountSubunits: 50000,
        );

        final allocation = PaymentAllocation(
          id: PaymentAllocationId.fromString('alloc-fk'),
          paymentId: payment.id,
          invoiceId: invoice.id,
          amount: Money.fromSubunits(20000, Currency.dzd),
          createdAt: DateTime.utc(2026, 1, 5),
        );
        await allocationRepo.add(allocation);

        // Attempting to delete payment must fail due to ON DELETE RESTRICT
        expect(
          () => paymentRepo.deleteById(payment.id),
          throwsA(isA<SqliteException>()),
        );

        // Attempting to delete invoice must fail
        expect(
          () => invoiceRepo.deleteById(invoice.id),
          throwsA(
            isA<StateError>(),
          ), // Issued invoices are immutable and protected
        );
      },
    );
  });

  group(
    'DriftUnitOfWork + AllocatePayment Application Use Case Integration',
    () {
      test(
        'AllocatePayment coordinates validation and atomic persistence',
        () async {
          final allocatePayment = AllocatePayment(unitOfWork);

          final invoice = await createIssuedInvoice(
            id: 'inv-app-alloc',
            number: 'INV-APP-ALLOC',
            amountSubunits: 100000,
          );
          final payment = await createPayment(
            id: 'pay-app-alloc',
            amountSubunits: 70000,
          );

          final command = AllocatePaymentCommand(
            paymentId: payment.id,
            invoiceId: invoice.id,
            amount: Money.fromSubunits(50000, Currency.dzd),
          );

          final result = await allocatePayment.execute(command);
          expect(result.isSuccess, isTrue);

          final allocation = result.dataOrNull!;
          expect(
            allocation.amount,
            equals(Money.fromSubunits(50000, Currency.dzd)),
          );

          // Verify in SQLite
          final fromDb = await allocationRepo.getById(allocation.id);
          expect(fromDb, isNotNull);
          expect(fromDb!.amount, equals(allocation.amount));
        },
      );

      test(
        'AllocatePayment rejects over-allocation of payment capacity',
        () async {
          final allocatePayment = AllocatePayment(unitOfWork);

          final invoice = await createIssuedInvoice(
            id: 'inv-over-pay',
            number: 'INV-OVER-PAY',
            amountSubunits: 100000,
          );
          final payment = await createPayment(
            id: 'pay-over-pay',
            amountSubunits: 30000, // Payment is only 30,000
          );

          final command = AllocatePaymentCommand(
            paymentId: payment.id,
            invoiceId: invoice.id,
            amount: Money.fromSubunits(
              50000,
              Currency.dzd,
            ), // Requesting 50,000!
          );

          final result = await allocatePayment.execute(command);
          expect(result.isFailure, isTrue);
          expect(result.failureOrNull, isA<ValidationFailure>());
          expect(
            result.failureOrNull!.message,
            contains('Payment capacity exceeded'),
          );
        },
      );

      test(
        'AllocatePayment rejects over-allocation of invoice balance',
        () async {
          final allocatePayment = AllocatePayment(unitOfWork);

          final invoice = await createIssuedInvoice(
            id: 'inv-over-inv',
            number: 'INV-OVER-INV',
            amountSubunits: 20000, // Invoice total is only 20,000
          );
          final payment = await createPayment(
            id: 'pay-over-inv',
            amountSubunits: 80000,
          );

          final command = AllocatePaymentCommand(
            paymentId: payment.id,
            invoiceId: invoice.id,
            amount: Money.fromSubunits(
              50000,
              Currency.dzd,
            ), // Requesting 50,000!
          );

          final result = await allocatePayment.execute(command);
          expect(result.isFailure, isTrue);
          expect(result.failureOrNull, isA<ValidationFailure>());
          expect(
            result.failureOrNull!.message,
            contains('Invoice balance exceeded'),
          );
        },
      );

      test('AllocatePayment rejects allocation to a draft invoice', () async {
        final allocatePayment = AllocatePayment(unitOfWork);

        // Create draft invoice without issuing
        final draftInvoice = Invoice.draft(
          id: InvoiceId.fromString('inv-draft-alloc'),
          clientId: testClient.id,
          number: 'INV-DRAFT-ALLOC',
          currency: Currency.dzd,
          createdAt: DateTime.utc(2026, 1, 1),
        );
        await invoiceRepo.add(draftInvoice);

        final payment = await createPayment(
          id: 'pay-draft-alloc',
          amountSubunits: 50000,
        );

        final command = AllocatePaymentCommand(
          paymentId: payment.id,
          invoiceId: draftInvoice.id,
          amount: Money.fromSubunits(10000, Currency.dzd),
        );

        final result = await allocatePayment.execute(command);
        expect(result.isFailure, isTrue);
        expect(result.failureOrNull, isA<ValidationFailure>());
        expect(
          result.failureOrNull!.message,
          contains('Cannot allocate payment to draft invoice'),
        );
      });
    },
  );
}
