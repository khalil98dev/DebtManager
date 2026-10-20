import 'package:domain/domain.dart';
import 'package:meta/meta.dart';

import 'sync_entity_type.dart';
import 'sync_operation_id.dart';

/// Represents a detected conflict between local entity state and incoming remote/transport state.
///
/// Encapsulates the diverging versions, payloads, and rationale for future resolution
/// without silently overwriting local financial data.
@immutable
class SyncConflict {
  SyncConflict({
    required this.operationId,
    required this.entityType,
    required String entityId,
    required this.localVersion,
    required this.remoteVersion,
    required Map<String, dynamic> localPayload,
    required Map<String, dynamic> remotePayload,
    required String reason,
    required this.createdAt,
  }) : entityId = ValidationUtils.validateAndTrimRequired(
         entityId,
         name: 'entityId',
         message: 'SyncConflict entityId cannot be empty.',
       ),
       reason = ValidationUtils.validateAndTrimRequired(
         reason,
         name: 'reason',
         message: 'SyncConflict reason cannot be empty.',
       ),
       localPayload = Map<String, dynamic>.unmodifiable(localPayload),
       remotePayload = Map<String, dynamic>.unmodifiable(remotePayload);

  /// The local operation ID associated with this conflict.
  final SyncOperationId operationId;

  /// The domain entity type involved.
  final SyncEntityType entityType;

  /// The stable entity identifier.
  final String entityId;

  /// Local revision version.
  final int localVersion;

  /// Remote revision version received from transport.
  final int remoteVersion;

  /// Snapshot of the local entity payload.
  final Map<String, dynamic> localPayload;

  /// Snapshot of the conflicting incoming remote payload.
  final Map<String, dynamic> remotePayload;

  /// Human-readable explanation of why the conflict occurred.
  final String reason;

  /// Timestamp when the conflict was detected.
  final DateTime createdAt;

  Map<String, dynamic> toJson() {
    return {
      'operationId': operationId.value,
      'entityType': entityType.name,
      'entityId': entityId,
      'localVersion': localVersion,
      'remoteVersion': remoteVersion,
      'localPayload': localPayload,
      'remotePayload': remotePayload,
      'reason': reason,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory SyncConflict.fromJson(Map<String, dynamic> json) {
    final rawOpId = json['operationId'] as String?;
    final rawEntityType = json['entityType'] as String?;
    final rawEntityId = json['entityId'] as String?;
    final rawLocalVer = json['localVersion'] as num?;
    final rawRemoteVer = json['remoteVersion'] as num?;
    final rawLocalPayload = json['localPayload'];
    final rawRemotePayload = json['remotePayload'];
    final rawReason = json['reason'] as String?;
    final rawCreatedAt = json['createdAt'] as String?;

    if (rawOpId == null ||
        rawEntityType == null ||
        rawEntityId == null ||
        rawLocalVer == null ||
        rawRemoteVer == null ||
        rawLocalPayload is! Map ||
        rawRemotePayload is! Map ||
        rawReason == null ||
        rawCreatedAt == null) {
      throw const FormatException(
        'Missing required fields when deserializing SyncConflict.',
      );
    }

    return SyncConflict(
      operationId: SyncOperationId.fromString(rawOpId),
      entityType: SyncEntityType.fromName(rawEntityType),
      entityId: rawEntityId,
      localVersion: rawLocalVer.toInt(),
      remoteVersion: rawRemoteVer.toInt(),
      localPayload: Map<String, dynamic>.from(rawLocalPayload),
      remotePayload: Map<String, dynamic>.from(rawRemotePayload),
      reason: rawReason,
      createdAt: DateTime.parse(rawCreatedAt),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncConflict &&
          other.operationId == operationId &&
          other.entityType == entityType &&
          other.entityId == entityId &&
          other.localVersion == localVersion &&
          other.remoteVersion == remoteVersion);

  @override
  int get hashCode => Object.hash(
    operationId,
    entityType,
    entityId,
    localVersion,
    remoteVersion,
  );

  @override
  String toString() =>
      'SyncConflict(op: $operationId, entity: ${entityType.name}:$entityId, '
      'localV: $localVersion, remoteV: $remoteVersion, reason: $reason)';
}
