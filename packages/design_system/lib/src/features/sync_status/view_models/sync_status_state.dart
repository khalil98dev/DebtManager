import 'package:flutter/foundation.dart';
import 'package:synco/synco.dart';

enum SyncStatusViewStateStatus { initial, loading, loaded, error }

/// Immutable state for the local sync outbox diagnostics screen.
@immutable
class SyncStatusViewState {
  const SyncStatusViewState({
    this.status = SyncStatusViewStateStatus.initial,
    this.pendingOperations = const [],
    this.failedOperations = const [],
    this.acknowledgedCount = 0,
    this.latestSequence = 0,
    this.isLocalOnly = true,
    this.lastRefreshedAt,
    this.errorMessage,
  });

  final SyncStatusViewStateStatus status;
  final List<SyncOperation> pendingOperations;
  final List<SyncOperation> failedOperations;
  final int acknowledgedCount;
  final int latestSequence;
  final bool isLocalOnly;
  final DateTime? lastRefreshedAt;
  final String? errorMessage;

  bool get isLoading => status == SyncStatusViewStateStatus.loading;
  bool get hasError => status == SyncStatusViewStateStatus.error;
  int get pendingCount => pendingOperations.length;
  int get failedCount => failedOperations.length;
  int get totalOutboxCount => pendingCount + failedCount + acknowledgedCount;

  SyncStatusViewState copyWith({
    SyncStatusViewStateStatus? status,
    List<SyncOperation>? pendingOperations,
    List<SyncOperation>? failedOperations,
    int? acknowledgedCount,
    int? latestSequence,
    bool? isLocalOnly,
    DateTime? lastRefreshedAt,
    String? errorMessage,
  }) {
    return SyncStatusViewState(
      status: status ?? this.status,
      pendingOperations: pendingOperations ?? this.pendingOperations,
      failedOperations: failedOperations ?? this.failedOperations,
      acknowledgedCount: acknowledgedCount ?? this.acknowledgedCount,
      latestSequence: latestSequence ?? this.latestSequence,
      isLocalOnly: isLocalOnly ?? this.isLocalOnly,
      lastRefreshedAt: lastRefreshedAt ?? this.lastRefreshedAt,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
