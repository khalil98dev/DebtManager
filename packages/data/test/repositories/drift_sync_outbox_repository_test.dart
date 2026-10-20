import 'dart:io';

import 'package:data/data.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:synco/synco.dart';

void main() {
  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  late AppDatabase db;
  late DriftSyncOutboxRepository repo;

  setUp(() {
    db = AppDatabase.inMemory();
    repo = DriftSyncOutboxRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('DriftSyncOutboxRepository - Basic Operations & FIFO Ordering', () {
    test(
      'enqueues pending operations and retrieves them in FIFO sequence order',
      () async {
        final op1 = SyncOperation(
          id: SyncOperationId.fromString('op-1'),
          entityType: SyncEntityType.client,
          entityId: 'client-1',
          operationType: SyncOperationType.create,
          payload: {'name': 'Client One'},
          localSequence: 1,
          entityVersion: 1,
          createdAt: DateTime.utc(2026, 3, 1, 10, 0),
        );

        final op2 = SyncOperation(
          id: SyncOperationId.fromString('op-2'),
          entityType: SyncEntityType.invoice,
          entityId: 'inv-1',
          operationType: SyncOperationType.create,
          payload: {'number': 'INV-001'},
          localSequence: 2,
          entityVersion: 1,
          createdAt: DateTime.utc(2026, 3, 1, 10, 5),
        );

        await repo.enqueue(op2); // Enqueue op2 first
        await repo.enqueue(op1); // Enqueue op1 second

        final pending = await repo.getPending();
        expect(pending.length, equals(2));
        // Even though op2 was inserted first, getPending orders by localSequence ASC
        expect(pending[0].id, equals(op1.id));
        expect(pending[0].localSequence, equals(1));
        expect(pending[1].id, equals(op2.id));
        expect(pending[1].localSequence, equals(2));
      },
    );

    test('getPending respects limit parameter', () async {
      for (var i = 1; i <= 5; i++) {
        await repo.enqueue(
          SyncOperation(
            id: SyncOperationId.fromString('op-$i'),
            entityType: SyncEntityType.client,
            entityId: 'client-$i',
            operationType: SyncOperationType.create,
            payload: {'name': 'Client $i'},
            localSequence: i,
            entityVersion: 1,
            createdAt: DateTime.utc(2026, 3, 1, 10, i),
          ),
        );
      }

      final pendingBatch = await repo.getPending(limit: 3);
      expect(pendingBatch.length, equals(3));
      expect(
        pendingBatch.map((o) => o.localSequence).toList(),
        equals([1, 2, 3]),
      );
    });

    test(
      'enqueue is idempotent: re-enqueuing existing ID preserves original entry',
      () async {
        final originalOp = SyncOperation(
          id: SyncOperationId.fromString('op-dup-1'),
          entityType: SyncEntityType.client,
          entityId: 'client-1',
          operationType: SyncOperationType.create,
          payload: {'name': 'Original Name'},
          localSequence: 1,
          entityVersion: 1,
          createdAt: DateTime.utc(2026, 3, 1, 10, 0),
        );

        await repo.enqueue(originalOp);

        final duplicateOp = SyncOperation(
          id: SyncOperationId.fromString('op-dup-1'),
          entityType: SyncEntityType.client,
          entityId: 'client-1',
          operationType: SyncOperationType.create,
          payload: {'name': 'Modified Name'},
          localSequence: 99,
          entityVersion: 5,
          createdAt: DateTime.utc(2026, 3, 1, 12, 0),
        );

        await repo.enqueue(duplicateOp);

        final retrieved = await repo.getById(originalOp.id);
        expect(retrieved, isNotNull);
        expect(retrieved!.payload['name'], equals('Original Name'));
        expect(retrieved.localSequence, equals(1));
        expect(retrieved.entityVersion, equals(1));
      },
    );

    test('getById returns null when operation does not exist', () async {
      final notFound = await repo.getById(
        SyncOperationId.fromString('non-existent'),
      );
      expect(notFound, isNull);
    });
  });

  group('DriftSyncOutboxRepository - Status Transitions & Updates', () {
    test('updates status and metadata correctly', () async {
      final op = SyncOperation(
        id: SyncOperationId.fromString('op-trans-1'),
        entityType: SyncEntityType.payment,
        entityId: 'pay-1',
        operationType: SyncOperationType.create,
        payload: {'amount': 1000},
        localSequence: 1,
        entityVersion: 1,
        createdAt: DateTime.utc(2026, 3, 1, 10, 0),
      );

      await repo.enqueue(op);

      // Transition to processing
      final procTime = DateTime.utc(2026, 3, 1, 10, 10);
      await repo.updateStatus(
        op.id,
        SyncStatus.processing,
        processedAt: procTime,
      );

      var updated = await repo.getById(op.id);
      expect(updated!.status, equals(SyncStatus.processing));
      expect(updated.processedAt, equals(procTime));

      // Transition to failed
      await repo.updateStatus(
        op.id,
        SyncStatus.failed,
        errorMessage: 'Network timeout',
        isRetryable: true,
      );

      updated = await repo.getById(op.id);
      expect(updated!.status, equals(SyncStatus.failed));
      expect(updated.errorMessage, equals('Network timeout'));
      expect(updated.isRetryable, isTrue);

      // Transition to acknowledged
      await repo.updateStatus(
        op.id,
        SyncStatus.acknowledged,
        isRetryable: false,
      );

      updated = await repo.getById(op.id);
      expect(updated!.status, equals(SyncStatus.acknowledged));
      expect(updated.isRetryable, isFalse);
    });

    test('update replaces full operation state', () async {
      final op = SyncOperation(
        id: SyncOperationId.fromString('op-update-1'),
        entityType: SyncEntityType.invoice,
        entityId: 'inv-1',
        operationType: SyncOperationType.create,
        payload: {'number': 'INV-001'},
        localSequence: 1,
        entityVersion: 1,
        createdAt: DateTime.utc(2026, 3, 1, 10, 0),
      );

      await repo.enqueue(op);

      final modified = op
          .markFailed(error: 'Conflict with server revision', retryable: false)
          .markConflict(details: 'Invoice already exists on remote');

      await repo.update(modified);

      final retrieved = await repo.getById(op.id);
      expect(retrieved!.status, equals(SyncStatus.conflict));
      expect(
        retrieved.errorMessage,
        equals('Invoice already exists on remote'),
      );
      expect(retrieved.isRetryable, isFalse);
    });

    test(
      'getByStatus retrieves only operations with specified status',
      () async {
        final op1 = SyncOperation(
          id: SyncOperationId.fromString('op-s1'),
          entityType: SyncEntityType.client,
          entityId: 'client-1',
          operationType: SyncOperationType.create,
          payload: {'name': 'Client 1'},
          localSequence: 1,
          entityVersion: 1,
          createdAt: DateTime.utc(2026, 3, 1, 10, 0),
        );
        final op2 = SyncOperation(
          id: SyncOperationId.fromString('op-s2'),
          entityType: SyncEntityType.client,
          entityId: 'client-2',
          operationType: SyncOperationType.create,
          status: SyncStatus.failed,
          payload: {'name': 'Client 2'},
          localSequence: 2,
          entityVersion: 1,
          createdAt: DateTime.utc(2026, 3, 1, 10, 1),
        );
        final op3 = SyncOperation(
          id: SyncOperationId.fromString('op-s3'),
          entityType: SyncEntityType.client,
          entityId: 'client-3',
          operationType: SyncOperationType.create,
          status: SyncStatus.acknowledged,
          payload: {'name': 'Client 3'},
          localSequence: 3,
          entityVersion: 1,
          createdAt: DateTime.utc(2026, 3, 1, 10, 2),
        );

        await repo.enqueue(op1);
        await repo.enqueue(op2);
        await repo.enqueue(op3);

        final pending = await repo.getByStatus(SyncStatus.pending);
        expect(pending.length, equals(1));
        expect(pending.first.id, equals(op1.id));

        final failed = await repo.getByStatus(SyncStatus.failed);
        expect(failed.length, equals(1));
        expect(failed.first.id, equals(op2.id));

        final acked = await repo.getByStatus(SyncStatus.acknowledged);
        expect(acked.length, equals(1));
        expect(acked.first.id, equals(op3.id));
      },
    );

    test('getByEntity filters by entityType and entityId in order', () async {
      final op1 = SyncOperation(
        id: SyncOperationId.fromString('op-e1'),
        entityType: SyncEntityType.client,
        entityId: 'client-A',
        operationType: SyncOperationType.create,
        payload: {'name': 'Client A'},
        localSequence: 1,
        entityVersion: 1,
        createdAt: DateTime.utc(2026, 3, 1, 10, 0),
      );
      final op2 = SyncOperation(
        id: SyncOperationId.fromString('op-e2'),
        entityType: SyncEntityType.client,
        entityId: 'client-A',
        operationType: SyncOperationType.update,
        payload: {'name': 'Client A Updated'},
        localSequence: 2,
        entityVersion: 2,
        createdAt: DateTime.utc(2026, 3, 1, 10, 5),
      );
      final op3 = SyncOperation(
        id: SyncOperationId.fromString('op-e3'),
        entityType: SyncEntityType.client,
        entityId: 'client-B',
        operationType: SyncOperationType.create,
        payload: {'name': 'Client B'},
        localSequence: 3,
        entityVersion: 1,
        createdAt: DateTime.utc(2026, 3, 1, 10, 6),
      );

      await repo.enqueue(op1);
      await repo.enqueue(op2);
      await repo.enqueue(op3);

      final clientAOps = await repo.getByEntity(
        SyncEntityType.client,
        'client-A',
      );
      expect(clientAOps.length, equals(2));
      expect(clientAOps[0].id, equals(op1.id));
      expect(clientAOps[1].id, equals(op2.id));
    });
  });

  group('DriftSyncOutboxRepository - Monotonic Sequence & Version Queries', () {
    test(
      'getNextLocalSequence returns 1 when empty and strictly increments',
      () async {
        expect(await repo.getNextLocalSequence(), equals(1));

        await repo.enqueue(
          SyncOperation(
            id: SyncOperationId.fromString('op-seq-1'),
            entityType: SyncEntityType.client,
            entityId: 'c-1',
            operationType: SyncOperationType.create,
            payload: {'name': 'C1'},
            localSequence: 1,
            entityVersion: 1,
            createdAt: DateTime.utc(2026, 3, 1),
          ),
        );

        expect(await repo.getNextLocalSequence(), equals(2));

        await repo.enqueue(
          SyncOperation(
            id: SyncOperationId.fromString('op-seq-10'),
            entityType: SyncEntityType.client,
            entityId: 'c-2',
            operationType: SyncOperationType.create,
            payload: {'name': 'C2'},
            localSequence: 10,
            entityVersion: 1,
            createdAt: DateTime.utc(2026, 3, 1),
          ),
        );

        expect(await repo.getNextLocalSequence(), equals(11));
      },
    );

    test(
      'getLatestEntityVersion returns 0 when unknown, and highest version when recorded',
      () async {
        expect(
          await repo.getLatestEntityVersion(SyncEntityType.client, 'unknown-c'),
          equals(0),
        );

        await repo.enqueue(
          SyncOperation(
            id: SyncOperationId.fromString('op-ver-1'),
            entityType: SyncEntityType.client,
            entityId: 'c-ver',
            operationType: SyncOperationType.create,
            payload: {'name': 'Version 1'},
            localSequence: 1,
            entityVersion: 1,
            createdAt: DateTime.utc(2026, 3, 1),
          ),
        );

        expect(
          await repo.getLatestEntityVersion(SyncEntityType.client, 'c-ver'),
          equals(1),
        );

        await repo.enqueue(
          SyncOperation(
            id: SyncOperationId.fromString('op-ver-2'),
            entityType: SyncEntityType.client,
            entityId: 'c-ver',
            operationType: SyncOperationType.update,
            payload: {'name': 'Version 3'},
            localSequence: 2,
            entityVersion: 3,
            createdAt: DateTime.utc(2026, 3, 1, 10, 1),
          ),
        );

        expect(
          await repo.getLatestEntityVersion(SyncEntityType.client, 'c-ver'),
          equals(3),
        );
      },
    );

    test('clearAll removes all records from outbox table', () async {
      await repo.enqueue(
        SyncOperation(
          id: SyncOperationId.fromString('op-c1'),
          entityType: SyncEntityType.client,
          entityId: 'c-1',
          operationType: SyncOperationType.create,
          payload: {'name': 'C1'},
          localSequence: 1,
          entityVersion: 1,
          createdAt: DateTime.utc(2026, 3, 1),
        ),
      );

      expect((await repo.getPending()).length, equals(1));
      await repo.clearAll();
      expect((await repo.getPending()).length, equals(0));
    });
  });

  group('DriftSyncOutboxRepository - Persistence Across Database Reopen', () {
    test('outbox entries persist across database close and reopen', () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'drift_outbox_persist_',
      );
      final dbFile = File('${tempDir.path}/outbox_persist.sqlite');

      final db1 = AppDatabase(NativeDatabase(dbFile));
      final repo1 = DriftSyncOutboxRepository(db1);

      final op = SyncOperation(
        id: SyncOperationId.fromString('op-file-1'),
        entityType: SyncEntityType.invoice,
        entityId: 'inv-file-1',
        operationType: SyncOperationType.create,
        payload: {'number': 'INV-FILE-001'},
        localSequence: 1,
        entityVersion: 1,
        createdAt: DateTime.utc(2026, 3, 1, 12, 0),
      );

      await repo1.enqueue(op);
      await db1.close();

      // Reopen database from disk
      final db2 = AppDatabase(NativeDatabase(dbFile));
      final repo2 = DriftSyncOutboxRepository(db2);

      final retrieved = await repo2.getById(op.id);
      expect(retrieved, isNotNull);
      expect(retrieved!.id, equals(op.id));
      expect(retrieved.payload['number'], equals('INV-FILE-001'));
      expect(retrieved.localSequence, equals(1));

      await db2.close();
      await tempDir.delete(recursive: true);
    });
  });
}
