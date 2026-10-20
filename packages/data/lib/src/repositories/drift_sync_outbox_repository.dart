import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:synco/synco.dart';

import '../database/app_database.dart';

/// Drift and SQLite implementation of [SyncOutboxRepository].
///
/// Persists pending, processing, and historical synchronization operations
/// locally in SQLite for offline-first resilience and deterministic batch assembly.
final class DriftSyncOutboxRepository implements SyncOutboxRepository {
  const DriftSyncOutboxRepository(this.db);

  final AppDatabase db;

  @override
  Future<void> enqueue(SyncOperation operation) async {
    final existing = await getById(operation.id);
    if (existing != null) {
      return;
    }
    await db
        .into(db.syncOutboxTable)
        .insert(toCompanion(operation), mode: InsertMode.insertOrIgnore);
  }

  @override
  Future<SyncOperation?> getById(SyncOperationId id) async {
    final query = db.select(db.syncOutboxTable)
      ..where((t) => t.id.equals(id.value));
    final entry = await query.getSingleOrNull();
    return entry != null ? _toDomain(entry) : null;
  }

  @override
  Future<List<SyncOperation>> getPending({int? limit}) async {
    var query = db.select(db.syncOutboxTable)
      ..where((t) => t.status.equalsValue(SyncStatus.pending))
      ..orderBy([(t) => OrderingTerm.asc(t.localSequence)]);
    if (limit != null && limit > 0) {
      query = query..limit(limit);
    }
    final entries = await query.get();
    return entries.map(_toDomain).toList(growable: false);
  }

  @override
  Future<List<SyncOperation>> getByStatus(
    SyncStatus status, {
    int? limit,
  }) async {
    var query = db.select(db.syncOutboxTable)
      ..where((t) => t.status.equalsValue(status))
      ..orderBy([(t) => OrderingTerm.asc(t.localSequence)]);
    if (limit != null && limit > 0) {
      query = query..limit(limit);
    }
    final entries = await query.get();
    return entries.map(_toDomain).toList(growable: false);
  }

  @override
  Future<List<SyncOperation>> getByEntity(
    SyncEntityType entityType,
    String entityId,
  ) async {
    final query = db.select(db.syncOutboxTable)
      ..where(
        (t) =>
            t.entityType.equalsValue(entityType) & t.entityId.equals(entityId),
      )
      ..orderBy([(t) => OrderingTerm.asc(t.localSequence)]);
    final entries = await query.get();
    return entries.map(_toDomain).toList(growable: false);
  }

  @override
  Future<void> updateStatus(
    SyncOperationId id,
    SyncStatus status, {
    String? errorMessage,
    bool? isRetryable,
    DateTime? processedAt,
  }) async {
    final companion = SyncOutboxTableCompanion(
      status: Value(status),
      errorMessage: Value(errorMessage),
      isRetryable: isRetryable != null
          ? Value(isRetryable)
          : const Value.absent(),
      processedAt: Value(
        processedAt ?? (status != SyncStatus.pending ? DateTime.now() : null),
      ),
    );
    await (db.update(
      db.syncOutboxTable,
    )..where((t) => t.id.equals(id.value))).write(companion);
  }

  @override
  Future<void> update(SyncOperation operation) async {
    await (db.update(db.syncOutboxTable)
          ..where((t) => t.id.equals(operation.id.value)))
        .write(toCompanion(operation));
  }

  @override
  Future<int> getNextLocalSequence() async {
    final maxSeqExpr = db.syncOutboxTable.localSequence.max();
    final query = db.selectOnly(db.syncOutboxTable)..addColumns([maxSeqExpr]);
    final row = await query.getSingleOrNull();
    final maxSeq = row?.read(maxSeqExpr);
    return (maxSeq ?? 0) + 1;
  }

  @override
  Future<int> getLatestEntityVersion(
    SyncEntityType entityType,
    String entityId,
  ) async {
    final maxVerExpr = db.syncOutboxTable.entityVersion.max();
    final query = db.selectOnly(db.syncOutboxTable)
      ..addColumns([maxVerExpr])
      ..where(
        db.syncOutboxTable.entityType.equalsValue(entityType) &
            db.syncOutboxTable.entityId.equals(entityId),
      );
    final row = await query.getSingleOrNull();
    final maxVer = row?.read(maxVerExpr);
    return maxVer ?? 0;
  }

  @override
  Future<void> clearAll() async {
    await db.delete(db.syncOutboxTable).go();
  }

  SyncOutboxTableCompanion toCompanion(SyncOperation operation) {
    return SyncOutboxTableCompanion(
      id: Value(operation.id.value),
      entityType: Value(operation.entityType),
      entityId: Value(operation.entityId),
      operationType: Value(operation.operationType),
      status: Value(operation.status),
      payload: Value(jsonEncode(operation.payload)),
      localSequence: Value(operation.localSequence),
      entityVersion: Value(operation.entityVersion),
      retryCount: Value(operation.retryCount),
      isRetryable: Value(operation.isRetryable),
      errorMessage: Value(operation.errorMessage),
      createdAt: Value(operation.createdAt),
      processedAt: Value(operation.processedAt),
    );
  }

  SyncOperation _toDomain(SyncOutboxEntry entry) {
    return SyncOperation(
      id: SyncOperationId.fromString(entry.id),
      entityType: entry.entityType,
      entityId: entry.entityId,
      operationType: entry.operationType,
      status: entry.status,
      payload: jsonDecode(entry.payload) as Map<String, dynamic>,
      localSequence: entry.localSequence,
      entityVersion: entry.entityVersion,
      createdAt: entry.createdAt,
      processedAt: entry.processedAt,
      retryCount: entry.retryCount,
      errorMessage: entry.errorMessage,
      isRetryable: entry.isRetryable,
    );
  }
}
