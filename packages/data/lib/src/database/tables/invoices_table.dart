import 'package:domain/domain.dart';
import 'package:drift/drift.dart';

import 'clients_table.dart';

/// Drift table definition for storing invoices.
///
/// Represents the persistence model for [Invoice] aggregate roots.
/// Timestamps are stored as ISO 8601 strings in SQLite via `store_date_time_values_as_text`.
@DataClassName('InvoiceEntry')
class InvoicesTable extends Table {
  @override
  String get tableName => 'invoices';

  TextColumn get id => text().withLength(min: 1, max: 64)();

  TextColumn get clientId =>
      text().references(ClientsTable, #id, onDelete: KeyAction.restrict)();

  TextColumn get number => text()();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get issuedAt => dateTime().nullable()();

  TextColumn get status => textEnum<InvoiceStatus>()();

  TextColumn get notes => text().nullable()();

  TextColumn get currency => text().withLength(min: 1, max: 10)();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {number},
  ];
}
