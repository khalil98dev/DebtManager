/// Represents the lifecycle state of a synchronization operation in the local outbox.
enum SyncStatus {
  /// Enqueued locally and waiting to be included in a synchronization batch.
  pending,

  /// Currently included in an inflight batch being processed.
  processing,

  /// Successfully acknowledged and synchronized.
  acknowledged,

  /// Failed to process; may be retryable or permanent.
  failed,

  /// Conflicting remote/local change detected that requires explicit handling.
  conflict;

  static SyncStatus fromName(String name) {
    return SyncStatus.values.firstWhere(
      (e) => e.name == name,
      orElse: () => throw ArgumentError.value(
        name,
        'name',
        'Unsupported sync status: $name.',
      ),
    );
  }
}
