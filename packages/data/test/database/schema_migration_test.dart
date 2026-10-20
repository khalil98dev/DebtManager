import 'dart:io';

import 'package:data/data.dart';
import 'package:domain/domain.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:synco/synco.dart';

void main() {
  late Directory tempDir;
  late File dbFile;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('drift_mig_test_');
    dbFile = File('${tempDir.path}/migration_test.sqlite');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('Database Schema Migration v1 -> v4', () {
    test(
      'migrates existing v1 database to v4, preserves clients, and creates invoices, payments, allocations, and sync_outbox tables',
      () async {
        // Step 1: Create a simulated v1 database with only the clients table and seed data
        final rawDb = sqlite3.open(dbFile.path);
        rawDb.execute('''
        CREATE TABLE clients (
          id TEXT NOT NULL PRIMARY KEY,
          name TEXT NOT NULL,
          phone TEXT,
          notes TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        );
      ''');
        rawDb.execute('PRAGMA user_version = 1;');
        rawDb.execute('''
        INSERT INTO clients (id, name, phone, notes, created_at, updated_at)
        VALUES ('client-v1', 'Pre-existing Client', '0555123456', 'Created in v1', '2026-01-01T00:00:00.000Z', '2026-01-01T00:00:00.000Z');
      ''');
        rawDb.close();

        // Step 2: Open with AppDatabase (schemaVersion = 4), triggering onUpgrade through v2, v3, and v4
        final appDb = AppDatabase(NativeDatabase(dbFile));

        // Verify that clients table still contains the pre-existing client
        final clientRepo = DriftClientRepository(appDb);
        final preExistingClient = await clientRepo.getById(
          ClientId.fromString('client-v1'),
        );
        expect(preExistingClient, isNotNull);
        expect(preExistingClient!.name, equals('Pre-existing Client'));
        expect(preExistingClient.phone, equals('0555123456'));
        expect(preExistingClient.notes, equals('Created in v1'));

        // Verify that user_version in SQLite was bumped to 4
        final userVersionResult = await appDb
            .customSelect('PRAGMA user_version;')
            .getSingle();
        expect(userVersionResult.data['user_version'], equals(4));

        // Step 3: Verify the newly created invoice tables are fully functional
        final invoiceRepo = DriftInvoiceRepository(appDb);
        final line = InvoiceLine(
          id: InvoiceLineId.fromString('line-mig-1'),
          description: 'Post-migration line',
          quantity: 1,
          unitPrice: Money.fromSubunits(750000, Currency.dzd),
          createdAt: DateTime.utc(2026, 2, 1),
        );
        final invoice = Invoice.draft(
          id: InvoiceId.fromString('inv-mig-1'),
          clientId: preExistingClient.id,
          number: 'INV-MIG-001',
          lines: [line],
          currency: Currency.dzd,
          createdAt: DateTime.utc(2026, 2, 1),
        ).issue(issuedAt: DateTime.utc(2026, 2, 2));

        await invoiceRepo.add(invoice);

        final retrievedInvoice = await invoiceRepo.getById(invoice.id);
        expect(retrievedInvoice, isNotNull);
        expect(retrievedInvoice!.number, equals('INV-MIG-001'));
        expect(retrievedInvoice.clientId, equals(preExistingClient.id));
        expect(retrievedInvoice.lines.length, equals(1));

        // Step 4: Verify the newly created payments table is fully functional
        final paymentRepo = DriftPaymentRepository(appDb);
        final payment = Payment(
          id: PaymentId.fromString('pay-mig-1'),
          clientId: preExistingClient.id,
          amount: Money.fromSubunits(500000, Currency.dzd),
          receivedAt: DateTime.utc(2026, 2, 3),
          createdAt: DateTime.utc(2026, 2, 3),
        );
        await paymentRepo.add(payment);

        final retrievedPayment = await paymentRepo.getById(payment.id);
        expect(retrievedPayment, isNotNull);
        expect(retrievedPayment!.amount, equals(payment.amount));

        // Step 5: Verify payment allocations table is fully functional
        final allocationRepo = DriftPaymentAllocationRepository(appDb);
        final allocation = PaymentAllocation(
          id: PaymentAllocationId.fromString('alloc-mig-1'),
          paymentId: payment.id,
          invoiceId: invoice.id,
          amount: Money.fromSubunits(300000, Currency.dzd),
          createdAt: DateTime.utc(2026, 2, 4),
        );
        await allocationRepo.add(allocation);

        final retrievedAlloc = await allocationRepo.getById(allocation.id);
        expect(retrievedAlloc, isNotNull);
        expect(retrievedAlloc!.amount, equals(allocation.amount));

        // Step 6: Verify sync_outbox table is fully functional
        final outboxRepo = DriftSyncOutboxRepository(appDb);
        final operation = SyncOperation(
          id: SyncOperationId.fromString('op-mig-1'),
          entityType: SyncEntityType.client,
          entityId: preExistingClient.id.value,
          operationType: SyncOperationType.create,
          payload: {'name': preExistingClient.name},
          localSequence: 1,
          entityVersion: 1,
          createdAt: DateTime.utc(2026, 2, 5),
        );
        await outboxRepo.enqueue(operation);

        final retrievedOp = await outboxRepo.getById(operation.id);
        expect(retrievedOp, isNotNull);
        expect(retrievedOp!.id, equals(operation.id));
        expect(retrievedOp.entityType, equals(SyncEntityType.client));
        expect(retrievedOp.entityId, equals(preExistingClient.id.value));
        expect(retrievedOp.payload['name'], equals(preExistingClient.name));

        await appDb.close();
      },
    );
  });
}
