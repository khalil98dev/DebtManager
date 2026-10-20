import 'package:domain/domain.dart';
import 'package:meta/meta.dart';

import 'sync_entity_type.dart';
import 'sync_operation_id.dart';
import 'sync_operation_type.dart';
import 'sync_status.dart';

/// An immutable model representing a persistent synchronization operation in the local outbox.
///
/// Encapsulates change metadata, entity reference, monotonic sequence, versioning,
/// lifecycle status, and serialized state payload.
@immutable
class SyncOperation {
  SyncOperation({
    required this.id,
    required this.entityType,
    required String entityId,
    required this.operationType,
    this.status = SyncStatus.pending,
    required Map<String, dynamic> payload,
    required this.localSequence,
    required this.entityVersion,
    required this.createdAt,
    this.processedAt,
    this.retryCount = 0,
    this.errorMessage,
    this.isRetryable = true,
  }) : entityId = ValidationUtils.validateAndTrimRequired(
         entityId,
         name: 'entityId',
         message: 'SyncOperation entityId cannot be empty.',
       ),
       payload = Map<String, dynamic>.unmodifiable(payload) {
    if (localSequence < 0) {
      throw ArgumentError.value(
        localSequence,
        'localSequence',
        'SyncOperation localSequence must be non-negative.',
      );
    }
    if (entityVersion < 1) {
      throw ArgumentError.value(
        entityVersion,
        'entityVersion',
        'SyncOperation entityVersion must be at least 1.',
      );
    }
    if (retryCount < 0) {
      throw ArgumentError.value(
        retryCount,
        'retryCount',
        'SyncOperation retryCount cannot be negative.',
      );
    }
  }

  /// Unique identifier of this synchronization operation.
  final SyncOperationId id;

  /// The domain entity type being synchronized.
  final SyncEntityType entityType;

  /// The stable identifier of the entity instance.
  final String entityId;

  /// The business mutation type (create, update, issue, delete).
  final SyncOperationType operationType;

  /// The current outbox lifecycle status.
  final SyncStatus status;

  /// The serialized entity state or mutation delta payload.
  final Map<String, dynamic> payload;

  /// Strictly monotonic local sequence number for deterministic FIFO ordering.
  final int localSequence;

  /// The revision/version number of the entity at the time of this operation.
  final int entityVersion;

  /// Timestamp when the operation was recorded in the local outbox.
  final DateTime createdAt;

  /// Timestamp when the operation was last processed or acknowledged, or `null`.
  final DateTime? processedAt;

  /// Number of times this operation has been attempted.
  final int retryCount;

  /// Detailed error or conflict description if processing failed.
  final String? errorMessage;

  /// Whether a failed operation can be retried automatically.
  final bool isRetryable;

  /// Returns a copy of this operation marked as [SyncStatus.processing].
  SyncOperation markProcessing({DateTime? at}) {
    return SyncOperation(
      id: id,
      entityType: entityType,
      entityId: entityId,
      operationType: operationType,
      status: SyncStatus.processing,
      payload: payload,
      localSequence: localSequence,
      entityVersion: entityVersion,
      createdAt: createdAt,
      processedAt: at ?? DateTime.now(),
      retryCount: retryCount,
      errorMessage: errorMessage,
      isRetryable: isRetryable,
    );
  }

  /// Returns a copy of this operation marked as [SyncStatus.acknowledged].
  SyncOperation markAcknowledged({DateTime? at}) {
    return SyncOperation(
      id: id,
      entityType: entityType,
      entityId: entityId,
      operationType: operationType,
      status: SyncStatus.acknowledged,
      payload: payload,
      localSequence: localSequence,
      entityVersion: entityVersion,
      createdAt: createdAt,
      processedAt: at ?? DateTime.now(),
      retryCount: retryCount,
      errorMessage: null,
      isRetryable: false,
    );
  }

  /// Returns a copy of this operation marked as [SyncStatus.failed].
  SyncOperation markFailed({
    required String error,
    bool retryable = true,
    DateTime? at,
  }) {
    return SyncOperation(
      id: id,
      entityType: entityType,
      entityId: entityId,
      operationType: operationType,
      status: SyncStatus.failed,
      payload: payload,
      localSequence: localSequence,
      entityVersion: entityVersion,
      createdAt: createdAt,
      processedAt: at ?? DateTime.now(),
      retryCount: retryCount + 1,
      errorMessage: error,
      isRetryable: retryable,
    );
  }

  /// Returns a copy of this operation marked as [SyncStatus.conflict].
  SyncOperation markConflict({required String details, DateTime? at}) {
    return SyncOperation(
      id: id,
      entityType: entityType,
      entityId: entityId,
      operationType: operationType,
      status: SyncStatus.conflict,
      payload: payload,
      localSequence: localSequence,
      entityVersion: entityVersion,
      createdAt: createdAt,
      processedAt: at ?? DateTime.now(),
      retryCount: retryCount,
      errorMessage: details,
      isRetryable: false,
    );
  }

  /// Resets a failed or processing operation back to [SyncStatus.pending].
  SyncOperation resetToPending() {
    return SyncOperation(
      id: id,
      entityType: entityType,
      entityId: entityId,
      operationType: operationType,
      status: SyncStatus.pending,
      payload: payload,
      localSequence: localSequence,
      entityVersion: entityVersion,
      createdAt: createdAt,
      processedAt: null,
      retryCount: retryCount,
      errorMessage: errorMessage,
      isRetryable: isRetryable,
    );
  }

  /// Converts this operation into an explicit JSON-serializable map.
  Map<String, dynamic> toJson() {
    return {
      'id': id.value,
      'entityType': entityType.name,
      'entityId': entityId,
      'operationType': operationType.name,
      'status': status.name,
      'payload': payload,
      'localSequence': localSequence,
      'entityVersion': entityVersion,
      'createdAt': createdAt.toIso8601String(),
      'processedAt': processedAt?.toIso8601String(),
      'retryCount': retryCount,
      'errorMessage': errorMessage,
      'isRetryable': isRetryable,
    };
  }

  /// Reconstructs a [SyncOperation] from an explicit JSON map.
  factory SyncOperation.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'] as String?;
    final rawEntityType = json['entityType'] as String?;
    final rawEntityId = json['entityId'] as String?;
    final rawOperationType = json['operationType'] as String?;
    final rawStatus = json['status'] as String?;
    final rawPayload = json['payload'];
    final rawSequence = json['localSequence'] as num?;
    final rawVersion = json['entityVersion'] as num?;
    final rawCreatedAt = json['createdAt'] as String?;

    if (rawId == null ||
        rawEntityType == null ||
        rawEntityId == null ||
        rawOperationType == null ||
        rawStatus == null ||
        rawPayload is! Map ||
        rawSequence == null ||
        rawVersion == null ||
        rawCreatedAt == null) {
      throw const FormatException(
        'Missing required fields when deserializing SyncOperation.',
      );
    }

    return SyncOperation(
      id: SyncOperationId.fromString(rawId),
      entityType: SyncEntityType.fromName(rawEntityType),
      entityId: rawEntityId,
      operationType: SyncOperationType.fromName(rawOperationType),
      status: SyncStatus.fromName(rawStatus),
      payload: Map<String, dynamic>.from(rawPayload),
      localSequence: rawSequence.toInt(),
      entityVersion: rawVersion.toInt(),
      createdAt: DateTime.parse(rawCreatedAt),
      processedAt: json['processedAt'] != null
          ? DateTime.parse(json['processedAt'] as String)
          : null,
      retryCount: (json['retryCount'] as num?)?.toInt() ?? 0,
      errorMessage: json['errorMessage'] as String?,
      isRetryable: (json['isRetryable'] as bool?) ?? true,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is SyncOperation && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'SyncOperation(id: $id, entity: ${entityType.name}:$entityId, '
      'type: ${operationType.name}, status: ${status.name}, seq: $localSequence, v: $entityVersion)';
}
