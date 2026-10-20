import 'package:application/application.dart';
import 'package:domain/domain.dart';
import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../database/tables/payment_allocations_table.dart';
import 'drift_repository.dart';

/// Drift and SQLite implementation of [PaymentAllocationRepository].
///
/// Inherits common CRUD operations from [DriftRepository] and implements specialized
/// allocation queries across payments, invoices, and clients.
final class DriftPaymentAllocationRepository
    extends
        DriftRepository<
          PaymentAllocation,
          PaymentAllocationId,
          PaymentAllocationsTable,
          PaymentAllocationEntry
        >
    implements PaymentAllocationRepository {
  const DriftPaymentAllocationRepository(super.db);

  @override
  TableInfo<PaymentAllocationsTable, PaymentAllocationEntry> get table =>
      db.paymentAllocationsTable;

  @override
  GeneratedColumn<String> get idColumn => db.paymentAllocationsTable.id;

  @override
  String idToDb(PaymentAllocationId id) => id.value;

  @override
  Insertable<PaymentAllocationEntry> toCompanion(PaymentAllocation entity) {
    return PaymentAllocationsTableCompanion(
      id: Value(entity.id.value),
      paymentId: Value(entity.paymentId.value),
      invoiceId: Value(entity.invoiceId.value),
      amount: Value(entity.amount.subunits),
      currency: Value(entity.currency.code),
      createdAt: Value(entity.createdAt),
    );
  }

  @override
  PaymentAllocation toDomain(PaymentAllocationEntry entry) {
    return PaymentAllocation(
      id: PaymentAllocationId.fromString(entry.id),
      paymentId: PaymentId.fromString(entry.paymentId),
      invoiceId: InvoiceId.fromString(entry.invoiceId),
      amount: Money.fromSubunits(
        entry.amount,
        Currency.fromCode(entry.currency),
      ),
      createdAt: entry.createdAt,
    );
  }

  @override
  Future<List<PaymentAllocation>> getByPaymentId(PaymentId paymentId) async {
    final query = db.select(table)
      ..where(
        (t) => db.paymentAllocationsTable.paymentId.equals(paymentId.value),
      )
      ..orderBy([
        (t) => OrderingTerm.asc(db.paymentAllocationsTable.createdAt),
      ]);
    final entries = await query.get();
    return entries.map(toDomain).toList(growable: false);
  }

  @override
  Future<List<PaymentAllocation>> getByInvoiceId(InvoiceId invoiceId) async {
    final query = db.select(table)
      ..where(
        (t) => db.paymentAllocationsTable.invoiceId.equals(invoiceId.value),
      )
      ..orderBy([
        (t) => OrderingTerm.asc(db.paymentAllocationsTable.createdAt),
      ]);
    final entries = await query.get();
    return entries.map(toDomain).toList(growable: false);
  }

  @override
  Future<List<PaymentAllocation>> getByClientId(ClientId clientId) async {
    final query =
        db.select(table).join([
            innerJoin(
              db.paymentsTable,
              db.paymentsTable.id.equalsExp(
                db.paymentAllocationsTable.paymentId,
              ),
            ),
          ])
          ..where(db.paymentsTable.clientId.equals(clientId.value))
          ..orderBy([OrderingTerm.desc(db.paymentAllocationsTable.createdAt)]);

    final rows = await query.get();
    return rows
        .map((row) => toDomain(row.readTable(table)))
        .toList(growable: false);
  }

  @override
  Future<PaymentAllocation?> getByPaymentAndInvoice(
    PaymentId paymentId,
    InvoiceId invoiceId,
  ) async {
    final query = db.select(table)
      ..where(
        (t) =>
            db.paymentAllocationsTable.paymentId.equals(paymentId.value) &
            db.paymentAllocationsTable.invoiceId.equals(invoiceId.value),
      );
    final entry = await query.getSingleOrNull();
    return entry != null ? toDomain(entry) : null;
  }
}
