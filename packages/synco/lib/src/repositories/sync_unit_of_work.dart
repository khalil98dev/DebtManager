import 'package:application/application.dart';

import 'sync_outbox_repository.dart';

/// Extension of [UnitOfWorkScope] that provides access to the [SyncOutboxRepository]
/// within the same transactional boundary.
abstract interface class SyncUnitOfWorkScope implements UnitOfWorkScope {
  /// The local synchronization outbox repository.
  SyncOutboxRepository get syncOutbox;
}

/// Extension of [UnitOfWork] supporting atomic business operations combined with
/// synchronization change tracking.
abstract interface class SyncUnitOfWork implements UnitOfWork {
  /// Executes [action] inside an atomic transaction scope with outbox access.
  Future<T> saveChangesWithSyncAsync<T>(
    Future<T> Function(SyncUnitOfWorkScope scope) action,
  );
}
