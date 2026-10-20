import 'package:domain/domain.dart';
import 'package:meta/meta.dart';

import 'sync_operation.dart';

/// Contract representing an immutable batch of pending synchronization operations
/// prepared for future transport integration.
@immutable
class SyncBatchRequest {
  SyncBatchRequest({
    required String batchId,
    required Iterable<SyncOperation> operations,
    required this.createdAt,
  }) : batchId = ValidationUtils.validateAndTrimRequired(
         batchId,
         name: 'batchId',
         message: 'SyncBatchRequest batchId cannot be empty.',
       ),
       operations = List<SyncOperation>.unmodifiable(operations);

  /// Unique identifier of this batch envelope.
  final String batchId;

  /// Ordered collection of operations contained within this batch.
  final List<SyncOperation> operations;

  /// Timestamp when this batch was compiled from the outbox.
  final DateTime createdAt;

  /// The count of operations in this batch.
  int get count => operations.length;

  /// Whether this batch contains no operations.
  bool get isEmpty => operations.isEmpty;

  Map<String, dynamic> toJson() {
    return {
      'batchId': batchId,
      'operations': operations.map((op) => op.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory SyncBatchRequest.fromJson(Map<String, dynamic> json) {
    final rawBatchId = json['batchId'] as String?;
    final rawOps = json['operations'];
    final rawCreatedAt = json['createdAt'] as String?;

    if (rawBatchId == null || rawOps is! List || rawCreatedAt == null) {
      throw const FormatException(
        'Missing required fields when deserializing SyncBatchRequest.',
      );
    }

    final parsedOps = rawOps
        .map(
          (op) => SyncOperation.fromJson(Map<String, dynamic>.from(op as Map)),
        )
        .toList();

    return SyncBatchRequest(
      batchId: rawBatchId,
      operations: parsedOps,
      createdAt: DateTime.parse(rawCreatedAt),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncBatchRequest && other.batchId == batchId);

  @override
  int get hashCode => batchId.hashCode;

  @override
  String toString() => 'SyncBatchRequest(batchId: $batchId, count: $count)';
}
