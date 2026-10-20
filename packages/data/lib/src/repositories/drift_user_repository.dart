import 'package:application/application.dart';
import 'package:domain/domain.dart';
import 'package:drift/drift.dart';

import '../database/app_database.dart';

/// SQLite and Drift implementation of [UserRepository].
final class DriftUserRepository implements UserRepository {
  const DriftUserRepository(this.db);

  final AppDatabase db;

  @override
  Future<void> add(User entity) async {
    await db.customStatement(
      '''
      INSERT OR REPLACE INTO users (
        id, username, display_name, password_hash, role_id, is_active, created_at, updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?);
      ''',
      [
        entity.id.value,
        entity.username.toLowerCase(),
        entity.displayName,
        entity.passwordHash,
        entity.roleId.value,
        entity.isActive ? 1 : 0,
        entity.createdAt.toUtc().toIso8601String(),
        entity.updatedAt.toUtc().toIso8601String(),
      ],
    );
  }

  @override
  Future<void> update(User entity) async {
    await add(entity);
  }

  @override
  Future<User?> getById(UserId id) async {
    final rows = await db.customSelect(
      'SELECT * FROM users WHERE id = ? LIMIT 1;',
      variables: [Variable.withString(id.value)],
    ).get();
    if (rows.isEmpty) return null;
    return _rowToUser(rows.first);
  }

  @override
  Future<User?> getByUsername(String username) async {
    final normalized = username.trim().toLowerCase();
    if (normalized.isEmpty) return null;
    final rows = await db.customSelect(
      'SELECT * FROM users WHERE LOWER(username) = ? LIMIT 1;',
      variables: [Variable.withString(normalized)],
    ).get();
    if (rows.isEmpty) return null;
    return _rowToUser(rows.first);
  }

  @override
  Future<List<User>> getAll() async {
    final rows = await db.customSelect(
      'SELECT * FROM users ORDER BY created_at ASC;',
    ).get();
    return rows.map(_rowToUser).toList(growable: false);
  }

  @override
  Future<bool> exists(UserId id) async {
    final user = await getById(id);
    return user != null;
  }

  @override
  Future<bool> existsById(UserId id) => exists(id);

  @override
  Future<int> count() async {
    final row = await db.customSelect(
      'SELECT COUNT(*) AS cnt FROM users;',
    ).getSingle();
    return (row.data['cnt'] as num?)?.toInt() ?? 0;
  }

  @override
  Future<void> delete(UserId id) async {
    await db.customStatement(
      'DELETE FROM users WHERE id = ?;',
      [id.value],
    );
  }

  @override
  Future<void> deleteById(UserId id) => delete(id);

  User _rowToUser(QueryRow row) {
    final data = row.data;
    final createdAt =
        DateTime.tryParse((data['created_at'] ?? '').toString()) ??
        DateTime.utc(2026, 1, 1);
    final updatedAt =
        DateTime.tryParse((data['updated_at'] ?? '').toString()) ?? createdAt;

    return User(
      id: UserId.fromString(data['id'].toString()),
      username: data['username'].toString(),
      displayName: data['display_name'].toString(),
      passwordHash: data['password_hash'].toString(),
      roleId: RoleId.fromString(data['role_id'].toString()),
      isActive: (data['is_active'] as int? ?? 1) != 0,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
