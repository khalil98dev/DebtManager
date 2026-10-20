import 'package:domain/domain.dart';
import 'package:meta/meta.dart';

import 'sync_acknowledgement.dart';
import 'sync_conflict.dart';

/// Contract representing an immutable response envelope for a processed synchronization batch.
@immutable
class SyncBatchResponse {
  SyncBatchResponse({
    required String batchId,
    Iterable<SyncAcknowledgement> acknowledgements = const [],
    Iterable<SyncConflict> conflicts = const [],
    required this.processedAt,
  }) : batchId = ValidationUtils.validateAndTrimRequired(
         batchId,
         name: 'batchId',
         message: 'SyncBatchResponse batchId cannot be empty.',
       ),
       acknowledgements = List<SyncAcknowledgement>.unmodifiable(
         acknowledgements,
       ),
       conflicts = List<SyncConflict>.unmodifiable(conflicts);

  /// Unique identifier of the batch being answered.
  final String batchId;

  /// Acknowledgements for operations that were processed.
  final List<SyncAcknowledgement> acknowledgements;

  /// Conflicts identified during batch processing.
  final List<SyncConflict> conflicts;

  /// Timestamp when batch processing concluded.
  final DateTime processedAt;

  Map<String, dynamic> toJson() {
    return {
      'batchId': batchId,
      'acknowledgements': acknowledgements.map((a) => a.toJson()).toList(),
      'conflicts': conflicts.map((c) => c.toJson()).toList(),
      'processedAt': processedAt.toIso8601String(),
    };
  }

  factory SyncBatchResponse.fromJson(Map<String, dynamic> json) {
    final rawBatchId = json['batchId'] as String?;
    final rawAcks = json['acknowledgements'];
    final rawConflicts = json['conflicts'];
    final rawProcessedAt = json['processedAt'] as String?;

    if (rawBatchId == null ||
        rawAcks is! List ||
        rawConflicts is! List ||
        rawProcessedAt == null) {
      throw const FormatException(
        'Missing required fields when deserializing SyncBatchResponse.',
      );
    }

    final parsedAcks = rawAcks
        .map(
          (a) =>
              SyncAcknowledgement.fromJson(Map<String, dynamic>.from(a as Map)),
        )
        .toList();

    final parsedConflicts = rawConflicts
        .map((c) => SyncConflict.fromJson(Map<String, dynamic>.from(c as Map)))
        .toList();

    return SyncBatchResponse(
      batchId: rawBatchId,
      acknowledgements: parsedAcks,
      conflicts: parsedConflicts,
      processedAt: DateTime.parse(rawProcessedAt),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncBatchResponse && other.batchId == batchId);

  @override
  int get hashCode => batchId.hashCode;

  @override
  String toString() =>
      'SyncBatchResponse(batchId: $batchId, acks: ${acknowledgements.length}, conflicts: ${conflicts.length})';
}
