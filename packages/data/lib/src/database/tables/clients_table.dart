import 'package:drift/drift.dart';

/// Drift table definition for storing clients.
///
/// Represents the persistence model for [Client] domain entities.
/// Timestamps are stored as ISO 8601 strings in SQLite via `store_date_time_values_as_text`.
@DataClassName('ClientEntry')
class ClientsTable extends Table {
  @override
  String get tableName => 'clients';
  TextColumn get id => text().withLength(min: 1, max: 64)();

  TextColumn get name => text()();

  TextColumn get phone => text().nullable()();

  TextColumn get notes => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
