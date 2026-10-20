import 'package:flutter/foundation.dart';
import 'package:synco/synco.dart';

import 'sync_status_state.dart';

/// ViewModel managing local SQLite sync outbox diagnostics and status inspection.
///
/// Follows strict offline-first principles: local outbox operations are inspected
/// without making network requests.
class SyncStatusViewModel extends ChangeNotifier {
  SyncStatusViewModel({
    SyncOutboxRepository? outboxRepository,
    SyncOutboxRepository? syncOutboxRepository,
  }) : outboxRepository = (outboxRepository ?? syncOutboxRepository)!;

  final SyncOutboxRepository outboxRepository;

  SyncStatusViewState _state = const SyncStatusViewState();
  SyncStatusViewState get state => _state;

  Future<void> loadStatus() => loadDiagnostics();

  Future<void> loadDiagnostics() async {
    _state = _state.copyWith(
      status: SyncStatusViewStateStatus.loading,
      errorMessage: null,
    );
    notifyListeners();

    try {
      final pending = await outboxRepository.getPending();
      final failed = await outboxRepository.getByStatus(SyncStatus.failed);
      final acknowledged = await outboxRepository.getByStatus(
        SyncStatus.acknowledged,
      );
      final nextSeq = await outboxRepository.getNextLocalSequence();
      final latestSeq = nextSeq > 1 ? nextSeq - 1 : 0;

      _state = _state.copyWith(
        status: SyncStatusViewStateStatus.loaded,
        pendingOperations: pending,
        failedOperations: failed,
        acknowledgedCount: acknowledged.length,
        latestSequence: latestSeq,
        lastRefreshedAt: DateTime.now(),
      );
    } catch (e) {
      _state = _state.copyWith(
        status: SyncStatusViewStateStatus.error,
        errorMessage: 'Failed to query local outbox diagnostics: $e',
      );
    }
    notifyListeners();
  }

  Future<void> refresh() => loadDiagnostics();
}
