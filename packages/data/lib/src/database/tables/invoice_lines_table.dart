import 'package:drift/drift.dart';

import 'invoices_table.dart';

/// Drift table definition for storing invoice line items.
///
/// Child entities belonging to an [InvoicesTable] entry.
/// Foreign key is configured with CASCADE delete so removing a draft invoice
/// cleans up child lines automatically.
@DataClassName('InvoiceLineEntry')
class InvoiceLinesTable extends Table {
  @override
  String get tableName => 'invoice_lines';

  TextColumn get id => text().withLength(min: 1, max: 64)();

  TextColumn get invoiceId =>
      text().references(InvoicesTable, #id, onDelete: KeyAction.cascade)();

  TextColumn get description => text()();

  IntColumn get quantity => integer()();

  IntColumn get unitPrice => integer()();

  IntColumn get discount => integer()();

  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
