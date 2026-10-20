import 'package:application/application.dart';
import 'package:domain/domain.dart';
import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../database/tables/clients_table.dart';
import 'drift_repository.dart';

/// Drift and SQLite implementation of [ClientRepository].
///
/// Inherits common CRUD operations from [DriftRepository] and adds client-specific lookups.
final class DriftClientRepository
    extends DriftRepository<Client, ClientId, ClientsTable, ClientEntry>
    implements ClientRepository {
  const DriftClientRepository(super.db);

  @override
  TableInfo<ClientsTable, ClientEntry> get table => db.clientsTable;

  @override
  GeneratedColumn<String> get idColumn => db.clientsTable.id;

  @override
  String idToDb(ClientId id) => id.value;

  @override
  Insertable<ClientEntry> toCompanion(Client entity) {
    return ClientsTableCompanion(
      id: Value(entity.id.value),
      name: Value(entity.name),
      phone: Value(entity.phone),
      notes: Value(entity.notes),
      createdAt: Value(entity.createdAt),
      updatedAt: Value(entity.updatedAt),
    );
  }

  @override
  Client toDomain(ClientEntry entry) {
    return Client(
      id: ClientId.fromString(entry.id),
      name: entry.name,
      phone: entry.phone,
      notes: entry.notes,
      createdAt: entry.createdAt,
      updatedAt: entry.updatedAt,
    );
  }

  @override
  Future<Client?> getByName(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return null;

    final query = db.select(
      table,
    )..where((t) => db.clientsTable.name.lower().equals(trimmed.toLowerCase()));
    final entry = await query.getSingleOrNull();
    return entry != null ? toDomain(entry) : null;
  }

  @override
  Future<bool> existsByName(String name) async {
    final client = await getByName(name);
    return client != null;
  }
}
