import 'package:application/application.dart';
import 'package:drift/drift.dart';

import '../database/app_database.dart';

/// Generic base repository implementing common CRUD operations using Drift and SQLite.
///
/// Subclasses specify their target [table], [idColumn], ID conversion, and entity/companion mappings.
abstract base class DriftRepository<TDomain, TId, TTable extends Table, TEntry>
    implements Repository<TDomain, TId> {
  const DriftRepository(this.db);

  final AppDatabase db;

  TableInfo<TTable, TEntry> get table;

  GeneratedColumn<String> get idColumn;

  String idToDb(TId id);

  Insertable<TEntry> toCompanion(TDomain entity);

  /// Converts a database entry row to the domain entity.
  TDomain toDomain(TEntry entry);

  @override
  Future<TDomain?> getById(TId id) async {
    final query = db.select(table)..where((_) => idColumn.equals(idToDb(id)));
    final entry = await query.getSingleOrNull();
    return entry != null ? toDomain(entry) : null;
  }

  @override
  Future<bool> existsById(TId id) async {
    final query = db.selectOnly(table)
      ..addColumns([idColumn])
      ..where(idColumn.equals(idToDb(id)));
    final result = await query.getSingleOrNull();
    return result != null;
  }

  @override
  Future<List<TDomain>> getAll() async {
    final entries = await db.select(table).get();
    return entries.map(toDomain).toList(growable: false);
  }

  @override
  Future<void> add(TDomain entity) async {
    await db.into(table).insertOnConflictUpdate(toCompanion(entity));
  }

  @override
  Future<void> deleteById(TId id) async {
    await (db.delete(table)..where((_) => idColumn.equals(idToDb(id)))).go();
  }
}
