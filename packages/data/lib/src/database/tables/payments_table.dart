import 'package:drift/drift.dart';

import 'clients_table.dart';

/// Drift table definition for storing payments.
///
/// Represents the persistence model for [Payment] domain entities.
/// Monetary amounts are stored as integer subunits in [amount].
/// Foreign key restricts deleting clients who have recorded payments.
@DataClassName('PaymentEntry')
class PaymentsTable extends Table {
  @override
  String get tableName => 'payments';

  TextColumn get id => text().withLength(min: 1, max: 64)();

  TextColumn get clientId =>
      text().references(ClientsTable, #id, onDelete: KeyAction.restrict)();

  IntColumn get amount => integer()();

  TextColumn get currency => text().withLength(min: 1, max: 10)();

  DateTimeColumn get receivedAt => dateTime()();

  TextColumn get notes => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
