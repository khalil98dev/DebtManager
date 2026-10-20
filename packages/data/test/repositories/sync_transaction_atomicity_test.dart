import 'package:data/data.dart';
import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:synco/synco.dart';

void main() {
  late AppDatabase db;
  late DriftUnitOfWork uow;

  setUp(() {
    db = AppDatabase.inMemory();
    uow = DriftUnitOfWork(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('Sync Transaction Atomicity - Unit of Work with Sync Outbox', () {
    test(
      'commits business mutations and outbox entries together in the same SQLite transaction',
      () async {
        final clientId = ClientId.fromString('client-atom-1');
        final client = Client(
          id: clientId,
          name: 'Atomic Client',
          phone: '0555999888',
          notes: 'Test client for atomic sync',
          createdAt: DateTime.utc(2026, 3, 1, 10, 0),
          updatedAt: DateTime.utc(2026, 3, 1, 10, 0),
        );

        final invoiceId = InvoiceId.fromString('inv-atom-1');
        final line = InvoiceLine(
          id: InvoiceLineId.fromString('line-atom-1'),
          description: 'Atomic Item',
          quantity: 2,
          unitPrice: Money.fromSubunits(500000, Currency.dzd),
          createdAt: DateTime.utc(2026, 3, 1, 10, 5),
        );
        final invoice = Invoice.draft(
          id: invoiceId,
          clientId: clientId,
          number: 'INV-ATOM-001',
          lines: [line],
          currency: Currency.dzd,
          createdAt: DateTime.utc(2026, 3, 1, 10, 5),
        ).issue(issuedAt: DateTime.utc(2026, 3, 1, 10, 6));

        final paymentId = PaymentId.fromString('pay-atom-1');
        final payment = Payment(
          id: paymentId,
          clientId: clientId,
          amount: Money.fromSubunits(1000000, Currency.dzd),
          receivedAt: DateTime.utc(2026, 3, 1, 10, 10),
          createdAt: DateTime.utc(2026, 3, 1, 10, 10),
        );

        final allocId = PaymentAllocationId.fromString('alloc-atom-1');
        final allocation = PaymentAllocation(
          id: allocId,
          paymentId: paymentId,
          invoiceId: invoiceId,
          amount: Money.fromSubunits(1000000, Currency.dzd),
          createdAt: DateTime.utc(2026, 3, 1, 10, 15),
        );

        // Execute all 4 business entities + 4 outbox operations atomically
        await uow.saveChangesWithSyncAsync((scope) async {
          // 1. Client
          await scope.clients.add(client);
          await scope.syncOutbox.enqueue(
            SyncChangeTracker.trackClientCreated(
              client,
              localSequence: await scope.syncOutbox.getNextLocalSequence(),
            ),
          );

          // 2. Invoice
          await scope.invoices.add(invoice);
          await scope.syncOutbox.enqueue(
            SyncChangeTracker.trackInvoiceIssued(
              invoice,
              localSequence: await scope.syncOutbox.getNextLocalSequence(),
              entityVersion: 1,
            ),
          );

          // 3. Payment
          await scope.payments.add(payment);
          await scope.syncOutbox.enqueue(
            SyncChangeTracker.trackPaymentRecorded(
              payment,
              localSequence: await scope.syncOutbox.getNextLocalSequence(),
            ),
          );

          // 4. Payment Allocation
          await scope.paymentAllocations.add(allocation);
          await scope.syncOutbox.enqueue(
            SyncChangeTracker.trackPaymentAllocated(
              allocation,
              localSequence: await scope.syncOutbox.getNextLocalSequence(),
            ),
          );
        });

        // Verify all 4 business entities are persisted in SQLite
        final clientRepo = DriftClientRepository(db);
        final invRepo = DriftInvoiceRepository(db);
        final payRepo = DriftPaymentRepository(db);
        final allocRepo = DriftPaymentAllocationRepository(db);
        final outboxRepo = DriftSyncOutboxRepository(db);

        expect(await clientRepo.getById(clientId), isNotNull);
        expect(await invRepo.getById(invoiceId), isNotNull);
        expect(await payRepo.getById(paymentId), isNotNull);
        expect(await allocRepo.getById(allocId), isNotNull);

        // Verify outbox contains all 4 operations in exact FIFO sequence
        final pending = await outboxRepo.getPending();
        expect(pending.length, equals(4));

        expect(pending[0].entityType, equals(SyncEntityType.client));
        expect(pending[0].entityId, equals(clientId.value));
        expect(pending[0].localSequence, equals(1));

        expect(pending[1].entityType, equals(SyncEntityType.invoice));
        expect(pending[1].entityId, equals(invoiceId.value));
        expect(pending[1].localSequence, equals(2));

        expect(pending[2].entityType, equals(SyncEntityType.payment));
        expect(pending[2].entityId, equals(paymentId.value));
        expect(pending[2].localSequence, equals(3));

        expect(pending[3].entityType, equals(SyncEntityType.paymentAllocation));
        expect(pending[3].entityId, equals(allocId.value));
        expect(pending[3].localSequence, equals(4));
      },
    );

    test(
      'rolls back business mutations and outbox entries if an error is thrown inside transaction',
      () async {
        final clientId = ClientId.fromString('client-rollback-1');
        final client = Client(
          id: clientId,
          name: 'Rollback Client',
          createdAt: DateTime.utc(2026, 3, 1),
          updatedAt: DateTime.utc(2026, 3, 1),
        );

        expect(
          () async => await uow.saveChangesWithSyncAsync((scope) async {
            await scope.clients.add(client);
            await scope.syncOutbox.enqueue(
              SyncChangeTracker.trackClientCreated(
                client,
                localSequence: await scope.syncOutbox.getNextLocalSequence(),
              ),
            );

            // Deliberate failure inside transaction
            throw StateError('Simulated unexpected business logic error');
          }),
          throwsA(isA<StateError>()),
        );

        // Verify neither client nor outbox entry was committed to SQLite
        final clientRepo = DriftClientRepository(db);
        final outboxRepo = DriftSyncOutboxRepository(db);

        expect(await clientRepo.getById(clientId), isNull);
        expect(await outboxRepo.getPending(), isEmpty);
        expect(await outboxRepo.getNextLocalSequence(), equals(1));
      },
    );

    test('rolls back business mutations if outbox recording throws', () async {
      final clientId = ClientId.fromString('client-fail-sync');
      final client = Client(
        id: clientId,
        name: 'Sync Fail Client',
        createdAt: DateTime.utc(2026, 3, 1),
        updatedAt: DateTime.utc(2026, 3, 1),
      );

      expect(
        () async => await uow.saveChangesWithSyncAsync((scope) async {
          await scope.clients.add(client);

          // Deliberately throw an exception during outbox step
          throw FormatException('Malformed payload serialization');
        }),
        throwsA(isA<FormatException>()),
      );

      final clientRepo = DriftClientRepository(db);
      final outboxRepo = DriftSyncOutboxRepository(db);

      expect(await clientRepo.getById(clientId), isNull);
      expect(await outboxRepo.getPending(), isEmpty);
    });

    test(
      'standard saveChangesAsync also functions correctly on DriftUnitOfWork',
      () async {
        final clientId = ClientId.fromString('client-standard-uow');
        final client = Client(
          id: clientId,
          name: 'Standard Client',
          createdAt: DateTime.utc(2026, 3, 1),
          updatedAt: DateTime.utc(2026, 3, 1),
        );

        final result = await uow.saveChangesAsync((scope) async {
          await scope.clients.add(client);
          return 'SUCCESS';
        });

        expect(result, equals('SUCCESS'));
        final clientRepo = DriftClientRepository(db);
        expect(await clientRepo.getById(clientId), isNotNull);
      },
    );
  });
}
