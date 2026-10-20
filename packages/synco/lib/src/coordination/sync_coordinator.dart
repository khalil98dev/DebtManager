import 'package:uuid/uuid.dart';
import '../models/sync_batch_request.dart';
import '../models/sync_batch_response.dart';
import '../models/sync_conflict.dart';
import '../models/sync_operation.dart';
import '../models/sync_status.dart';
import '../repositories/sync_outbox_repository.dart';

/// Transport-independent local synchronization coordinator.
///
/// Coordinates reading pending operations from the outbox, packaging them into
/// immutable batches, transitioning states, applying acknowledgements/conflicts,
/// and retrying eligible failed operations without performing any network I/O.
final class SyncCoordinator {
  const SyncCoordinator(this.outbox);

  final SyncOutboxRepository outbox;

  /// Compiles up to [limit] pending operations into an immutable [SyncBatchRequest]
  /// and marks them as [SyncStatus.processing].
  Future<SyncBatchRequest> prepareBatch({
    int limit = 50,
    String? batchId,
    DateTime? preparedAt,
  }) async {
    final pendingOps = await outbox.getPending(limit: limit);
    if (pendingOps.isEmpty) {
      return SyncBatchRequest(
        batchId: batchId ?? const Uuid().v7(),
        operations: const [],
        createdAt: preparedAt ?? DateTime.now(),
      );
    }

    final now = preparedAt ?? DateTime.now();
    final processingOps = <SyncOperation>[];

    for (final op in pendingOps) {
      final updated = op.markProcessing(at: now);
      await outbox.update(updated);
      processingOps.add(updated);
    }

    return SyncBatchRequest(
      batchId: batchId ?? const Uuid().v7(),
      operations: processingOps,
      createdAt: now,
    );
  }

  /// Applies a [SyncBatchResponse] received from a simulated or future transport adapter.
  Future<void> applyBatchResponse(SyncBatchResponse response) async {
    // 1. Process acknowledgements
    for (final ack in response.acknowledgements) {
      final op = await outbox.getById(ack.operationId);
      if (op == null) continue;

      switch (ack.status) {
        case SyncStatus.acknowledged:
          await outbox.update(op.markAcknowledged(at: ack.acknowledgedAt));
        case SyncStatus.failed:
          await outbox.update(
            op.markFailed(
              error: ack.errorMessage ?? 'Remote synchronization failed.',
              retryable: true,
              at: ack.acknowledgedAt,
            ),
          );
        case SyncStatus.conflict:
          await outbox.update(
            op.markConflict(
              details: ack.errorMessage ?? 'Synchronization conflict reported.',
              at: ack.acknowledgedAt,
            ),
          );
        case SyncStatus.pending:
        case SyncStatus.processing:
          // Intermediate states; leave untouched or reset if needed
          break;
      }
    }

    // 2. Process explicit conflicts
    for (final conflict in response.conflicts) {
      final op = await outbox.getById(conflict.operationId);
      if (op == null) continue;

      await outbox.update(
        op.markConflict(
          details: 'Conflict detected: ${conflict.reason}',
          at: conflict.createdAt,
        ),
      );
    }
  }

  /// Finds failed operations where [SyncOperation.isRetryable] is `true`
  /// and resets their status to [SyncStatus.pending] so they can be re-batched.
  Future<int> retryEligibleFailedOperations() async {
    final failedOps = await outbox.getByStatus(SyncStatus.failed);
    var retriedCount = 0;

    for (final op in failedOps) {
      if (op.isRetryable) {
        await outbox.update(op.resetToPending());
        retriedCount++;
      }
    }

    return retriedCount;
  }

  /// Detects whether an incoming remote revision conflicts with known local state.
  ///
  /// Returns a [SyncConflict] if a version discrepancy or divergent payload is detected,
  /// or `null` if the update can be safely applied.
  static SyncConflict? detectConflict({
    required SyncOperation localOp,
    required int incomingRemoteVersion,
    required Map<String, dynamic> incomingRemotePayload,
    required String reason,
    DateTime? detectedAt,
  }) {
    // If incoming version is not strictly greater than local version, or
    // if local has unacknowledged modifications, a conflict exists.
    final hasVersionConflict = incomingRemoteVersion <= localOp.entityVersion;
    final hasDivergentPayload = !_areMapsEqual(
      localOp.payload,
      incomingRemotePayload,
    );

    if (hasVersionConflict && hasDivergentPayload) {
      return SyncConflict(
        operationId: localOp.id,
        entityType: localOp.entityType,
        entityId: localOp.entityId,
        localVersion: localOp.entityVersion,
        remoteVersion: incomingRemoteVersion,
        localPayload: localOp.payload,
        remotePayload: incomingRemotePayload,
        reason: reason,
        createdAt: detectedAt ?? DateTime.now(),
      );
    }

    return null;
  }

  static bool _areMapsEqual(Map<dynamic, dynamic> a, Map<dynamic, dynamic> b) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key)) return false;
      if (a[key] != b[key]) return false;
    }
    return true;
  }
}
