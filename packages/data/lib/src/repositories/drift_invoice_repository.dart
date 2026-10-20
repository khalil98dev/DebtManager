import 'package:application/application.dart';
import 'package:domain/domain.dart';
import 'package:drift/drift.dart';

import '../database/app_database.dart';

/// Drift and SQLite implementation of [InvoiceRepository].
///
/// Persists [Invoice] aggregate roots and their child [InvoiceLine] items
/// atomically within SQLite transactions, enforcing lifecycle transitions
/// and immutability for issued invoices.
final class DriftInvoiceRepository implements InvoiceRepository {
  const DriftInvoiceRepository(this.db);

  final AppDatabase db;

  @override
  Future<Invoice?> getById(InvoiceId id) async {
    final invoiceEntry = await (db.select(
      db.invoicesTable,
    )..where((t) => t.id.equals(id.value))).getSingleOrNull();
    if (invoiceEntry == null) return null;

    final lineEntries =
        await (db.select(db.invoiceLinesTable)
              ..where((t) => t.invoiceId.equals(id.value))
              ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
            .get();

    return _toDomain(invoiceEntry, lineEntries);
  }

  @override
  Future<bool> existsById(InvoiceId id) async {
    final query = db.selectOnly(db.invoicesTable)
      ..addColumns([db.invoicesTable.id])
      ..where(db.invoicesTable.id.equals(id.value));
    final result = await query.getSingleOrNull();
    return result != null;
  }

  @override
  Future<List<Invoice>> getAll() async {
    final invoiceEntries = await (db.select(
      db.invoicesTable,
    )..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).get();

    return _loadInvoicesWithLines(invoiceEntries);
  }

  @override
  Future<List<Invoice>> getByClientId(
    ClientId clientId, {
    InvoiceStatus? status,
  }) async {
    var query = db.select(db.invoicesTable)
      ..where((t) => t.clientId.equals(clientId.value));
    if (status != null) {
      query = query..where((t) => t.status.equals(status.name));
    }
    query = query..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);

    final invoiceEntries = await query.get();
    return _loadInvoicesWithLines(invoiceEntries);
  }

  @override
  Future<Invoice?> getByNumber(String number) async {
    final trimmed = number.trim();
    if (trimmed.isEmpty) return null;

    final invoiceEntry = await (db.select(
      db.invoicesTable,
    )..where((t) => t.number.equals(trimmed))).getSingleOrNull();
    if (invoiceEntry == null) return null;

    final lineEntries =
        await (db.select(db.invoiceLinesTable)
              ..where((t) => t.invoiceId.equals(invoiceEntry.id))
              ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
            .get();

    return _toDomain(invoiceEntry, lineEntries);
  }

  @override
  Future<void> add(Invoice entity) async {
    await db.transaction(() async {
      final existing = await (db.select(
        db.invoicesTable,
      )..where((t) => t.id.equals(entity.id.value))).getSingleOrNull();

      if (existing != null) {
        if (existing.status == InvoiceStatus.issued) {
          throw StateError(
            'Cannot modify an invoice that has already been issued (id: ${entity.id.value}). Issued invoices are immutable.',
          );
        }

        // Synchronize lines: delete removed lines, update existing lines, insert new lines.
        final existingLines = await (db.select(
          db.invoiceLinesTable,
        )..where((t) => t.invoiceId.equals(entity.id.value))).get();
        final existingLineIds = existingLines.map((l) => l.id).toSet();
        final newLineIds = entity.lines.map((l) => l.id.value).toSet();

        final toDelete = existingLineIds.difference(newLineIds);
        if (toDelete.isNotEmpty) {
          await (db.delete(
            db.invoiceLinesTable,
          )..where((t) => t.id.isIn(toDelete))).go();
        }

        for (final line in entity.lines) {
          if (existingLineIds.contains(line.id.value)) {
            await (db.update(
              db.invoiceLinesTable,
            )..where((t) => t.id.equals(line.id.value))).write(
              InvoiceLinesTableCompanion(
                description: Value(line.description),
                quantity: Value(line.quantity),
                unitPrice: Value(line.unitPrice.subunits),
                discount: Value(line.discount.subunits),
              ),
            );
          } else {
            await db
                .into(db.invoiceLinesTable)
                .insert(
                  InvoiceLinesTableCompanion.insert(
                    id: line.id.value,
                    invoiceId: entity.id.value,
                    description: line.description,
                    quantity: line.quantity,
                    unitPrice: line.unitPrice.subunits,
                    discount: line.discount.subunits,
                    createdAt: line.createdAt,
                  ),
                );
          }
        }

        await (db.update(
          db.invoicesTable,
        )..where((t) => t.id.equals(entity.id.value))).write(
          InvoicesTableCompanion(
            clientId: Value(entity.clientId.value),
            number: Value(entity.number),
            createdAt: Value(entity.createdAt),
            issuedAt: Value(entity.issuedAt),
            status: Value(entity.status),
            notes: Value(entity.notes),
            currency: Value(entity.currency.code),
          ),
        );
      } else {
        // Insert new invoice record
        await db
            .into(db.invoicesTable)
            .insert(
              InvoicesTableCompanion.insert(
                id: entity.id.value,
                clientId: entity.clientId.value,
                number: entity.number,
                createdAt: entity.createdAt,
                issuedAt: Value(entity.issuedAt),
                status: entity.status,
                notes: Value(entity.notes),
                currency: entity.currency.code,
              ),
            );

        // Insert all lines
        for (final line in entity.lines) {
          await db
              .into(db.invoiceLinesTable)
              .insert(
                InvoiceLinesTableCompanion.insert(
                  id: line.id.value,
                  invoiceId: entity.id.value,
                  description: line.description,
                  quantity: line.quantity,
                  unitPrice: line.unitPrice.subunits,
                  discount: line.discount.subunits,
                  createdAt: line.createdAt,
                ),
              );
        }
      }
    });
  }

  @override
  Future<void> deleteById(InvoiceId id) async {
    final invoice = await (db.select(
      db.invoicesTable,
    )..where((t) => t.id.equals(id.value))).getSingleOrNull();
    if (invoice == null) {
      return;
    }
    if (invoice.status == InvoiceStatus.issued) {
      throw StateError(
        'Cannot delete an issued invoice (id: ${id.value}). Issued invoices are immutable financial records.',
      );
    }

    await (db.delete(
      db.invoicesTable,
    )..where((t) => t.id.equals(id.value))).go();
  }

  /// Batch loads lines for a list of invoices in a single query to eliminate N+1 queries.
  Future<List<Invoice>> _loadInvoicesWithLines(
    List<InvoiceEntry> invoiceEntries,
  ) async {
    if (invoiceEntries.isEmpty) return const [];

    final ids = invoiceEntries.map((e) => e.id).toList(growable: false);
    final allLineEntries =
        await (db.select(db.invoiceLinesTable)
              ..where((t) => t.invoiceId.isIn(ids))
              ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
            .get();

    final linesByInvoiceId = <String, List<InvoiceLineEntry>>{};
    for (final line in allLineEntries) {
      linesByInvoiceId.putIfAbsent(line.invoiceId, () => []).add(line);
    }

    return invoiceEntries
        .map((entry) {
          final lines = linesByInvoiceId[entry.id] ?? const [];
          return _toDomain(entry, lines);
        })
        .toList(growable: false);
  }

  Invoice _toDomain(
    InvoiceEntry invoiceEntry,
    List<InvoiceLineEntry> lineEntries,
  ) {
    final currency = Currency.fromCode(invoiceEntry.currency);
    final lines = lineEntries.map(
      (line) => InvoiceLine(
        id: InvoiceLineId.fromString(line.id),
        description: line.description,
        quantity: line.quantity,
        unitPrice: Money.fromSubunits(line.unitPrice, currency),
        discount: Money.fromSubunits(line.discount, currency),
        createdAt: line.createdAt,
      ),
    );

    return Invoice(
      id: InvoiceId.fromString(invoiceEntry.id),
      clientId: ClientId.fromString(invoiceEntry.clientId),
      number: invoiceEntry.number,
      lines: lines,
      createdAt: invoiceEntry.createdAt,
      issuedAt: invoiceEntry.issuedAt,
      status: invoiceEntry.status,
      notes: invoiceEntry.notes,
      currency: currency,
    );
  }
}
