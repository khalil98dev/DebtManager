import '../models/sync_entity_type.dart';
import '../models/sync_operation.dart';
import '../models/sync_operation_id.dart';
import '../models/sync_status.dart';

/// Contract for persistent local outbox storage of synchronization operations.
abstract interface class SyncOutboxRepository {
  /// Enqueues a new synchronization operation into the outbox.
  ///
  /// Must be idempotent: if an operation with the same ID already exists,
  /// it is preserved without duplicating records.
  Future<void> enqueue(SyncOperation operation);

  /// Retrieves an operation by its unique ID, or `null` if not found.
  Future<SyncOperation?> getById(SyncOperationId id);

  /// Retrieves pending operations ordered by [SyncOperation.localSequence] ascending (FIFO).
  Future<List<SyncOperation>> getPending({int? limit});

  /// Retrieves operations filtered by status, ordered by [SyncOperation.localSequence] ascending.
  Future<List<SyncOperation>> getByStatus(SyncStatus status, {int? limit});

  /// Retrieves all operations recorded for a specific entity instance.
  Future<List<SyncOperation>> getByEntity(
    SyncEntityType entityType,
    String entityId,
  );

  /// Updates the lifecycle status and error metadata of an existing operation.
  Future<void> updateStatus(
    SyncOperationId id,
    SyncStatus status, {
    String? errorMessage,
    bool? isRetryable,
    DateTime? processedAt,
  });

  /// Replaces or updates the entire state of an existing operation.
  Future<void> update(SyncOperation operation);

  /// Returns the next strictly monotonic local sequence number.
  Future<int> getNextLocalSequence();

  /// Returns the highest known revision/version number for an entity, or 0 if none recorded.
  Future<int> getLatestEntityVersion(
    SyncEntityType entityType,
    String entityId,
  );

  /// Deletes all operations from the outbox (used primarily for test cleanup and resets).
  Future<void> clearAll();
}
