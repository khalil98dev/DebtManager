import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:synco/synco.dart';

void main() {
  group('SyncOperation - Invariants & State Transitions', () {
    test('constructs valid SyncOperation with immutable payload', () {
      final op = SyncOperation(
        id: SyncOperationId.fromString('op-001'),
        entityType: SyncEntityType.client,
        entityId: 'client-1',
        operationType: SyncOperationType.create,
        status: SyncStatus.pending,
        payload: {'name': 'Fatima'},
        localSequence: 1,
        entityVersion: 1,
        createdAt: DateTime.utc(2026, 1, 1),
      );

      expect(op.id.value, equals('op-001'));
      expect(op.entityType, equals(SyncEntityType.client));
      expect(op.entityId, equals('client-1'));
      expect(op.operationType, equals(SyncOperationType.create));
      expect(op.status, equals(SyncStatus.pending));
      expect(op.payload['name'], equals('Fatima'));
      expect(op.localSequence, equals(1));
      expect(op.entityVersion, equals(1));
      expect(op.retryCount, equals(0));
      expect(op.isRetryable, isTrue);
      expect(op.processedAt, isNull);

      // Verify payload is unmodifiable
      expect(() => op.payload['new'] = 'val', throwsUnsupportedError);
    });

    test(
      'rejects empty entityId, negative sequence, negative retryCount, and zero version',
      () {
        expect(
          () => SyncOperation(
            id: SyncOperationId.fromString('op-bad'),
            entityType: SyncEntityType.client,
            entityId: '   ',
            operationType: SyncOperationType.create,
            payload: const {},
            localSequence: 0,
            entityVersion: 1,
            createdAt: DateTime.utc(2026, 1, 1),
          ),
          throwsArgumentError,
        );

        expect(
          () => SyncOperation(
            id: SyncOperationId.fromString('op-bad'),
            entityType: SyncEntityType.client,
            entityId: 'valid-id',
            operationType: SyncOperationType.create,
            payload: const {},
            localSequence: -1, // invalid!
            entityVersion: 1,
            createdAt: DateTime.utc(2026, 1, 1),
          ),
          throwsArgumentError,
        );

        expect(
          () => SyncOperation(
            id: SyncOperationId.fromString('op-bad'),
            entityType: SyncEntityType.client,
            entityId: 'valid-id',
            operationType: SyncOperationType.create,
            payload: const {},
            localSequence: 0,
            entityVersion: 0, // version must be >= 1
            createdAt: DateTime.utc(2026, 1, 1),
          ),
          throwsArgumentError,
        );

        expect(
          () => SyncOperation(
            id: SyncOperationId.fromString('op-bad'),
            entityType: SyncEntityType.client,
            entityId: 'valid-id',
            operationType: SyncOperationType.create,
            payload: const {},
            localSequence: 0,
            entityVersion: 1,
            retryCount: -1, // invalid!
            createdAt: DateTime.utc(2026, 1, 1),
          ),
          throwsArgumentError,
        );
      },
    );

    test('state transitions return updated immutable copies', () {
      final initial = SyncOperation(
        id: SyncOperationId.fromString('op-trans'),
        entityType: SyncEntityType.invoice,
        entityId: 'inv-1',
        operationType: SyncOperationType.create,
        status: SyncStatus.pending,
        payload: {'number': 'INV-001'},
        localSequence: 10,
        entityVersion: 1,
        createdAt: DateTime.utc(2026, 1, 1),
      );

      // markProcessing
      final procTime = DateTime.utc(2026, 1, 2);
      final processing = initial.markProcessing(at: procTime);
      expect(processing.status, equals(SyncStatus.processing));
      expect(processing.processedAt, equals(procTime));

      // markAcknowledged
      final ackTime = DateTime.utc(2026, 1, 3);
      final acknowledged = processing.markAcknowledged(at: ackTime);
      expect(acknowledged.status, equals(SyncStatus.acknowledged));
      expect(acknowledged.processedAt, equals(ackTime));
      expect(acknowledged.isRetryable, isFalse);

      // markFailed
      final failTime = DateTime.utc(2026, 1, 4);
      final failed = processing.markFailed(
        error: 'Network timeout',
        retryable: true,
        at: failTime,
      );
      expect(failed.status, equals(SyncStatus.failed));
      expect(failed.errorMessage, equals('Network timeout'));
      expect(failed.retryCount, equals(1));
      expect(failed.isRetryable, isTrue);

      // resetToPending
      final reset = failed.resetToPending();
      expect(reset.status, equals(SyncStatus.pending));
      expect(reset.processedAt, isNull);
      expect(reset.retryCount, equals(1)); // preserves attempts

      // markConflict
      final conflict = processing.markConflict(
        details: 'Version 2 already exists',
      );
      expect(conflict.status, equals(SyncStatus.conflict));
      expect(conflict.errorMessage, equals('Version 2 already exists'));
      expect(conflict.isRetryable, isFalse);
    });

    test('toJson and fromJson serialize and deserialize exactly', () {
      final op = SyncOperation(
        id: SyncOperationId.fromString('op-json'),
        entityType: SyncEntityType.payment,
        entityId: 'pay-42',
        operationType: SyncOperationType.create,
        status: SyncStatus.failed,
        payload: {'amount': 50000, 'currency': 'DZD'},
        localSequence: 5,
        entityVersion: 2,
        createdAt: DateTime.utc(2026, 1, 10, 10, 0),
        processedAt: DateTime.utc(2026, 1, 10, 10, 5),
        retryCount: 2,
        errorMessage: 'Temporary gateway rejection',
        isRetryable: true,
      );

      final json = op.toJson();
      final roundtripped = SyncOperation.fromJson(json);

      expect(roundtripped.id, equals(op.id));
      expect(roundtripped.entityType, equals(op.entityType));
      expect(roundtripped.entityId, equals(op.entityId));
      expect(roundtripped.operationType, equals(op.operationType));
      expect(roundtripped.status, equals(op.status));
      expect(roundtripped.payload, equals(op.payload));
      expect(roundtripped.localSequence, equals(op.localSequence));
      expect(roundtripped.entityVersion, equals(op.entityVersion));
      expect(roundtripped.createdAt, equals(op.createdAt));
      expect(roundtripped.processedAt, equals(op.processedAt));
      expect(roundtripped.retryCount, equals(op.retryCount));
      expect(roundtripped.errorMessage, equals(op.errorMessage));
      expect(roundtripped.isRetryable, equals(op.isRetryable));
    });
  });

  group('SyncConflict & SyncAcknowledgement - Contracts', () {
    test('SyncConflict serializes and deserializes exactly', () {
      final conflict = SyncConflict(
        operationId: SyncOperationId.fromString('op-conf-1'),
        entityType: SyncEntityType.client,
        entityId: 'client-1',
        localVersion: 1,
        remoteVersion: 2,
        localPayload: {'name': 'Local Name'},
        remotePayload: {'name': 'Remote Name'},
        reason: 'Concurrent edit detected on client',
        createdAt: DateTime.utc(2026, 1, 1),
      );

      final json = conflict.toJson();
      final parsed = SyncConflict.fromJson(json);

      expect(parsed, equals(conflict));
      expect(parsed.localPayload['name'], equals('Local Name'));
      expect(parsed.remotePayload['name'], equals('Remote Name'));
      expect(parsed.reason, equals('Concurrent edit detected on client'));
    });

    test('SyncAcknowledgement serializes and deserializes exactly', () {
      final ack = SyncAcknowledgement(
        operationId: SyncOperationId.fromString('op-ack-1'),
        entityId: 'client-1',
        status: SyncStatus.acknowledged,
        remoteVersion: 3,
        acknowledgedAt: DateTime.utc(2026, 1, 1),
      );

      final json = ack.toJson();
      final parsed = SyncAcknowledgement.fromJson(json);

      expect(parsed, equals(ack));
      expect(parsed.remoteVersion, equals(3));
      expect(parsed.errorMessage, isNull);
    });

    test('SyncBatchRequest and SyncBatchResponse roundtrip', () {
      final op = SyncOperation(
        id: SyncOperationId.fromString('op-b-1'),
        entityType: SyncEntityType.client,
        entityId: 'c-1',
        operationType: SyncOperationType.create,
        payload: {'name': 'Alice'},
        localSequence: 1,
        entityVersion: 1,
        createdAt: DateTime.utc(2026, 1, 1),
      );

      final req = SyncBatchRequest(
        batchId: 'batch-101',
        operations: [op],
        createdAt: DateTime.utc(2026, 1, 1),
      );
      final reqJson = req.toJson();
      final parsedReq = SyncBatchRequest.fromJson(reqJson);
      expect(parsedReq.batchId, equals('batch-101'));
      expect(parsedReq.count, equals(1));
      expect(parsedReq.operations.first.id, equals(op.id));

      final resp = SyncBatchResponse(
        batchId: 'batch-101',
        acknowledgements: [
          SyncAcknowledgement(
            operationId: op.id,
            entityId: 'c-1',
            status: SyncStatus.acknowledged,
            acknowledgedAt: DateTime.utc(2026, 1, 1),
          ),
        ],
        conflicts: const [],
        processedAt: DateTime.utc(2026, 1, 1),
      );
      final respJson = resp.toJson();
      final parsedResp = SyncBatchResponse.fromJson(respJson);
      expect(parsedResp.batchId, equals('batch-101'));
      expect(parsedResp.acknowledgements.length, equals(1));
      expect(parsedResp.conflicts, isEmpty);
    });
  });

  group('SyncChangeTracker - Explicit Entity Serialization', () {
    test('trackClientCreated and trackClientUpdated', () {
      final client = Client(
        id: ClientId.fromString('c-test-1'),
        name: 'Youcef Belaili',
        phone: '0555000111',
        notes: 'VIP Client',
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 2),
      );

      final createOp = SyncChangeTracker.trackClientCreated(
        client,
        localSequence: 1,
      );
      expect(createOp.entityType, equals(SyncEntityType.client));
      expect(createOp.operationType, equals(SyncOperationType.create));
      expect(createOp.entityVersion, equals(1));
      expect(createOp.payload['name'], equals('Youcef Belaili'));
      expect(createOp.payload['phone'], equals('0555000111'));

      final updateOp = SyncChangeTracker.trackClientUpdated(
        client,
        localSequence: 2,
        entityVersion: 2,
      );
      expect(updateOp.operationType, equals(SyncOperationType.update));
      expect(updateOp.entityVersion, equals(2));
    });

    test(
      'trackInvoiceCreated and trackInvoiceIssued preserves lines and status',
      () {
        final line = InvoiceLine(
          id: InvoiceLineId.fromString('l-1'),
          description: 'Design consulting',
          quantity: 2,
          unitPrice: Money.fromSubunits(500000, Currency.dzd),
          createdAt: DateTime.utc(2026, 1, 1),
        );
        final invoice = Invoice.draft(
          id: InvoiceId.fromString('inv-test-1'),
          clientId: ClientId.fromString('c-1'),
          number: 'INV-001',
          lines: [line],
          currency: Currency.dzd,
          createdAt: DateTime.utc(2026, 1, 1),
        );

        final draftOp = SyncChangeTracker.trackInvoiceCreated(
          invoice,
          localSequence: 3,
        );
        expect(draftOp.entityType, equals(SyncEntityType.invoice));
        expect(draftOp.operationType, equals(SyncOperationType.create));
        expect(draftOp.payload['status'], equals('draft'));
        final lines = draftOp.payload['lines'] as List;
        expect(lines.length, equals(1));
        expect(lines.first['unitPrice'], equals(500000));

        final issued = invoice.issue(issuedAt: DateTime.utc(2026, 1, 5));
        final issueOp = SyncChangeTracker.trackInvoiceIssued(
          issued,
          localSequence: 4,
          entityVersion: 2,
        );
        expect(issueOp.operationType, equals(SyncOperationType.issue));
        expect(issueOp.entityVersion, equals(2));
        expect(issueOp.payload['status'], equals('issued'));
      },
    );

    test('trackPaymentRecorded and trackPaymentAllocated', () {
      final payment = Payment(
        id: PaymentId.fromString('p-test-1'),
        clientId: ClientId.fromString('c-1'),
        amount: Money.fromSubunits(1000000, Currency.dzd),
        receivedAt: DateTime.utc(2026, 1, 10),
        createdAt: DateTime.utc(2026, 1, 10),
      );
      final payOp = SyncChangeTracker.trackPaymentRecorded(
        payment,
        localSequence: 5,
      );
      expect(payOp.entityType, equals(SyncEntityType.payment));
      expect(payOp.payload['amount'], equals(1000000));

      final alloc = PaymentAllocation(
        id: PaymentAllocationId.fromString('a-test-1'),
        paymentId: payment.id,
        invoiceId: InvoiceId.fromString('inv-test-1'),
        amount: Money.fromSubunits(500000, Currency.dzd),
        createdAt: DateTime.utc(2026, 1, 11),
      );
      final allocOp = SyncChangeTracker.trackPaymentAllocated(
        alloc,
        localSequence: 6,
      );
      expect(allocOp.entityType, equals(SyncEntityType.paymentAllocation));
      expect(allocOp.payload['paymentId'], equals(payment.id.value));
      expect(allocOp.payload['amount'], equals(500000));
    });
  });

  group('SyncCoordinator - In-Memory Coordination & Conflict Detection', () {
    test(
      'detectConflict returns SyncConflict on divergent payload with equal or lower version',
      () {
        final localOp = SyncOperation(
          id: SyncOperationId.fromString('op-conf-det'),
          entityType: SyncEntityType.client,
          entityId: 'c-conf',
          operationType: SyncOperationType.update,
          payload: {'name': 'Local Client'},
          localSequence: 1,
          entityVersion: 2,
          createdAt: DateTime.utc(2026, 1, 1),
        );

        final conflict = SyncCoordinator.detectConflict(
          localOp: localOp,
          incomingRemoteVersion: 2, // Same version, differing payload
          incomingRemotePayload: {'name': 'Remote Client'},
          reason: 'Concurrent modification on client name',
        );

        expect(conflict, isNotNull);
        expect(conflict!.localVersion, equals(2));
        expect(conflict.remoteVersion, equals(2));
        expect(conflict.reason, contains('Concurrent modification'));

        // If incoming is strictly higher version or payload is identical: no conflict
        final noConflictIdentical = SyncCoordinator.detectConflict(
          localOp: localOp,
          incomingRemoteVersion: 2,
          incomingRemotePayload: {'name': 'Local Client'}, // identical!
          reason: 'Replay',
        );
        expect(noConflictIdentical, isNull);

        final noConflictHigher = SyncCoordinator.detectConflict(
          localOp: localOp,
          incomingRemoteVersion: 3, // strictly higher!
          incomingRemotePayload: {'name': 'Remote Update'},
          reason: 'Legitimate newer update',
        );
        expect(noConflictHigher, isNull);
      },
    );
  });
}
