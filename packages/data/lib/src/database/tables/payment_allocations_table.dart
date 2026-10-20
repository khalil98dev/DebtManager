import 'package:drift/drift.dart';

import 'invoices_table.dart';
import 'payments_table.dart';

/// Drift table definition for storing payment allocations.
///
/// Represents the persistence model for [PaymentAllocation] domain entities.
/// Foreign keys restrict deleting payments or invoices that have active allocations.
/// The composite unique key `{paymentId, invoiceId}` enforces a single active allocation
/// per payment-invoice pair.
@DataClassName('PaymentAllocationEntry')
class PaymentAllocationsTable extends Table {
  @override
  String get tableName => 'payment_allocations';

  TextColumn get id => text().withLength(min: 1, max: 64)();

  TextColumn get paymentId =>
      text().references(PaymentsTable, #id, onDelete: KeyAction.restrict)();

  TextColumn get invoiceId =>
      text().references(InvoicesTable, #id, onDelete: KeyAction.restrict)();

  IntColumn get amount => integer()();

  TextColumn get currency => text().withLength(min: 1, max: 10)();

  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {paymentId, invoiceId},
  ];
}
