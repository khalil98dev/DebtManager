import 'package:drift/drift.dart';
import 'package:synco/synco.dart';

/// Drift table definition for the local synchronization outbox.
///
/// Stores pending and historical synchronization operations locally in SQLite
/// to support offline-first operation and deterministic batch compilation.
@DataClassName('SyncOutboxEntry')
class SyncOutboxTable extends Table {
  @override
  String get tableName => 'sync_outbox';

  TextColumn get id => text().withLength(min: 1, max: 64)();

  TextColumn get entityType => textEnum<SyncEntityType>()();

  TextColumn get entityId => text().withLength(min: 1, max: 64)();

  TextColumn get operationType => textEnum<SyncOperationType>()();

  TextColumn get status => textEnum<SyncStatus>()();

  TextColumn get payload => text()();

  IntColumn get localSequence => integer()();

  IntColumn get entityVersion => integer()();

  IntColumn get retryCount => integer().withDefault(const Constant(0))();

  BoolColumn get isRetryable => boolean().withDefault(const Constant(true))();

  TextColumn get errorMessage => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get processedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {localSequence},
  ];
}
