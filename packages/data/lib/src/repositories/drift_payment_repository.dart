import 'package:application/application.dart';
import 'package:domain/domain.dart';
import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../database/tables/payments_table.dart';
import 'drift_repository.dart';

/// Drift and SQLite implementation of [PaymentRepository].
///
/// Inherits common CRUD operations from [DriftRepository] and adds payment-specific queries
/// while enforcing financial attribute immutability.
final class DriftPaymentRepository
    extends DriftRepository<Payment, PaymentId, PaymentsTable, PaymentEntry>
    implements PaymentRepository {
  const DriftPaymentRepository(super.db);

  @override
  TableInfo<PaymentsTable, PaymentEntry> get table => db.paymentsTable;

  @override
  GeneratedColumn<String> get idColumn => db.paymentsTable.id;

  @override
  String idToDb(PaymentId id) => id.value;

  @override
  Insertable<PaymentEntry> toCompanion(Payment entity) {
    return PaymentsTableCompanion(
      id: Value(entity.id.value),
      clientId: Value(entity.clientId.value),
      amount: Value(entity.amount.subunits),
      currency: Value(entity.currency.code),
      receivedAt: Value(entity.receivedAt),
      notes: Value(entity.notes),
      createdAt: Value(entity.createdAt),
    );
  }

  @override
  Payment toDomain(PaymentEntry entry) {
    return Payment(
      id: PaymentId.fromString(entry.id),
      clientId: ClientId.fromString(entry.clientId),
      amount: Money.fromSubunits(
        entry.amount,
        Currency.fromCode(entry.currency),
      ),
      receivedAt: entry.receivedAt,
      notes: entry.notes,
      createdAt: entry.createdAt,
    );
  }

  @override
  Future<void> add(Payment entity) async {
    final existing = await (db.select(
      table,
    )..where((_) => idColumn.equals(idToDb(entity.id)))).getSingleOrNull();

    if (existing != null) {
      // In accordance with financial domain invariants, core transaction attributes
      // (amount, clientId, currency, receivedAt, createdAt) are immutable facts.
      // Only notes can be updated.
      if (existing.amount != entity.amount.subunits ||
          existing.clientId != entity.clientId.value ||
          existing.currency != entity.currency.code ||
          existing.receivedAt != entity.receivedAt ||
          existing.createdAt != entity.createdAt) {
        throw StateError(
          'Cannot alter immutable financial transaction attributes of payment ${entity.id.value}. '
          'Only notes can be updated.',
        );
      }
    }

    await super.add(entity);
  }

  @override
  Future<List<Payment>> getByClientId(ClientId clientId) async {
    final query = db.select(table)
      ..where((t) => db.paymentsTable.clientId.equals(clientId.value))
      ..orderBy([(t) => OrderingTerm.desc(db.paymentsTable.receivedAt)]);
    final entries = await query.get();
    return entries.map(toDomain).toList(growable: false);
  }
}
