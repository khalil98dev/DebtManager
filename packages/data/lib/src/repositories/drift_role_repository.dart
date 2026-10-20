import 'dart:convert';

import 'package:application/application.dart';
import 'package:domain/domain.dart';
import 'package:drift/drift.dart';

import '../database/app_database.dart';

/// SQLite and Drift implementation of [RoleRepository].
final class DriftRoleRepository implements RoleRepository {
  const DriftRoleRepository(this.db);

  final AppDatabase db;

  @override
  Future<void> ensureSystemRoles() async {
    final admin = Role.systemAdmin();
    final operatorRole = Role.systemOperator();
    await _insertOrIgnore(admin);
    await _insertOrIgnore(operatorRole);
  }

  Future<void> _insertOrIgnore(Role role) async {
    final permsJson = jsonEncode(role.permissions.map((p) => p.name).toList());
    await db.customStatement(
      '''
      INSERT OR IGNORE INTO roles (
        id, name, description, permissions_json, is_system, created_at, updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?);
      ''',
      [
        role.id.value,
        role.name,
        role.description,
        permsJson,
        role.isSystem ? 1 : 0,
        role.createdAt.toUtc().toIso8601String(),
        role.updatedAt.toUtc().toIso8601String(),
      ],
    );
  }

  @override
  Future<void> add(Role entity) async {
    await ensureSystemRoles();
    final permsJson = jsonEncode(
      entity.permissions.map((p) => p.name).toList(),
    );
    await db.customStatement(
      '''
      INSERT OR REPLACE INTO roles (
        id, name, description, permissions_json, is_system, created_at, updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?);
      ''',
      [
        entity.id.value,
        entity.name,
        entity.description,
        permsJson,
        entity.isSystem ? 1 : 0,
        entity.createdAt.toUtc().toIso8601String(),
        entity.updatedAt.toUtc().toIso8601String(),
      ],
    );
  }

  @override
  Future<void> update(Role entity) async {
    await add(entity);
  }

  @override
  Future<Role?> getById(RoleId id) async {
    await ensureSystemRoles();
    final rows = await db.customSelect(
      'SELECT * FROM roles WHERE id = ? LIMIT 1;',
      variables: [Variable.withString(id.value)],
    ).get();
    if (rows.isEmpty) return null;
    return _rowToRole(rows.first);
  }

  @override
  Future<Role?> getByName(String name) async {
    await ensureSystemRoles();
    final trimmed = name.trim().toLowerCase();
    if (trimmed.isEmpty) return null;
    final rows = await db.customSelect(
      'SELECT * FROM roles WHERE LOWER(name) = ? LIMIT 1;',
      variables: [Variable.withString(trimmed)],
    ).get();
    if (rows.isEmpty) return null;
    return _rowToRole(rows.first);
  }

  @override
  Future<List<Role>> getAll() async {
    await ensureSystemRoles();
    final rows = await db.customSelect(
      'SELECT * FROM roles ORDER BY is_system DESC, created_at ASC;',
    ).get();
    return rows.map(_rowToRole).toList(growable: false);
  }

  @override
  Future<bool> exists(RoleId id) async {
    final role = await getById(id);
    return role != null;
  }

  @override
  Future<bool> existsById(RoleId id) => exists(id);

  @override
  Future<void> delete(RoleId id) async {
    await db.customStatement(
      'DELETE FROM roles WHERE id = ? AND is_system = 0;',
      [id.value],
    );
  }

  @override
  Future<void> deleteById(RoleId id) => delete(id);

  Role _rowToRole(QueryRow row) {
    final data = row.data;
    final rawPermsJson = (data['permissions_json'] ?? '[]').toString();
    final decodedList = (jsonDecode(rawPermsJson) as List<dynamic>)
        .map((e) => e.toString())
        .map(AppPermission.tryFromName)
        .whereType<AppPermission>()
        .toSet();

    final perms = decodedList.isEmpty
        ? AppPermission.operatorBasePermissions
        : decodedList;

    final createdAt =
        DateTime.tryParse((data['created_at'] ?? '').toString()) ??
        DateTime.utc(2026, 1, 1);
    final updatedAt =
        DateTime.tryParse((data['updated_at'] ?? '').toString()) ?? createdAt;

    return Role(
      id: RoleId.fromString(data['id'].toString()),
      name: data['name'].toString(),
      description: data['description']?.toString(),
      permissions: perms,
      isSystem: (data['is_system'] as int? ?? 0) != 0,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
