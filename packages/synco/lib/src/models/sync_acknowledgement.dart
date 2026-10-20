import 'package:domain/domain.dart';
import 'package:meta/meta.dart';

import 'sync_operation_id.dart';
import 'sync_status.dart';

/// Represents an acknowledgement result for an operation processed by local coordination or remote transport.
@immutable
class SyncAcknowledgement {
  SyncAcknowledgement({
    required this.operationId,
    required String entityId,
    required this.status,
    this.remoteVersion,
    required this.acknowledgedAt,
    this.errorMessage,
  }) : entityId = ValidationUtils.validateAndTrimRequired(
         entityId,
         name: 'entityId',
         message: 'SyncAcknowledgement entityId cannot be empty.',
       );

  /// Identifier of the operation being acknowledged.
  final SyncOperationId operationId;

  /// Identifier of the related entity.
  final String entityId;

  /// Resulting synchronization status (typically [SyncStatus.acknowledged], [SyncStatus.failed], or [SyncStatus.conflict]).
  final SyncStatus status;

  /// Optional remote version assigned or confirmed by transport.
  final int? remoteVersion;

  /// Timestamp when acknowledgement occurred.
  final DateTime acknowledgedAt;

  /// Optional error or conflict details if not successful.
  final String? errorMessage;

  Map<String, dynamic> toJson() {
    return {
      'operationId': operationId.value,
      'entityId': entityId,
      'status': status.name,
      'remoteVersion': remoteVersion,
      'acknowledgedAt': acknowledgedAt.toIso8601String(),
      'errorMessage': errorMessage,
    };
  }

  factory SyncAcknowledgement.fromJson(Map<String, dynamic> json) {
    final rawOpId = json['operationId'] as String?;
    final rawEntityId = json['entityId'] as String?;
    final rawStatus = json['status'] as String?;
    final rawAckAt = json['acknowledgedAt'] as String?;

    if (rawOpId == null ||
        rawEntityId == null ||
        rawStatus == null ||
        rawAckAt == null) {
      throw const FormatException(
        'Missing required fields when deserializing SyncAcknowledgement.',
      );
    }

    return SyncAcknowledgement(
      operationId: SyncOperationId.fromString(rawOpId),
      entityId: rawEntityId,
      status: SyncStatus.fromName(rawStatus),
      remoteVersion: (json['remoteVersion'] as num?)?.toInt(),
      acknowledgedAt: DateTime.parse(rawAckAt),
      errorMessage: json['errorMessage'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncAcknowledgement &&
          other.operationId == operationId &&
          other.entityId == entityId &&
          other.status == status);

  @override
  int get hashCode => Object.hash(operationId, entityId, status);

  @override
  String toString() =>
      'SyncAcknowledgement(op: $operationId, entity: $entityId, status: ${status.name})';
}
