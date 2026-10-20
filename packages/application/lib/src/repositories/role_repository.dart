/// Role repository contract and in-memory default implementation.
library;

import 'package:domain/domain.dart';

import 'repository.dart';

abstract interface class RoleRepository implements Repository<Role, RoleId> {
  Future<Role?> getByName(String name);

  Future<void> ensureSystemRoles();

  Future<void> update(Role entity);

  Future<bool> exists(RoleId id);

  Future<void> delete(RoleId id);
}

/// In-memory implementation of [RoleRepository] pre-seeded with system roles.
class InMemoryRoleRepository implements RoleRepository {
  InMemoryRoleRepository({bool seedSystemRoles = true}) {
    if (seedSystemRoles) {
      final admin = Role.systemAdmin();
      final operatorRole = Role.systemOperator();
      _store[admin.id] = admin;
      _store[operatorRole.id] = operatorRole;
    }
  }

  final Map<RoleId, Role> _store = {};

  @override
  Future<void> ensureSystemRoles() async {
    _store.putIfAbsent(Role.adminRoleId, Role.systemAdmin);
    _store.putIfAbsent(Role.operatorRoleId, Role.systemOperator);
  }

  @override
  Future<void> add(Role entity) async {
    _store[entity.id] = entity;
  }

  @override
  Future<void> update(Role entity) async {
    _store[entity.id] = entity;
  }

  @override
  Future<Role?> getById(RoleId id) async {
    await ensureSystemRoles();
    return _store[id];
  }

  @override
  Future<List<Role>> getAll() async {
    await ensureSystemRoles();
    return _store.values.toList(growable: false);
  }

  @override
  Future<bool> exists(RoleId id) async {
    await ensureSystemRoles();
    return _store.containsKey(id);
  }

  @override
  Future<bool> existsById(RoleId id) => exists(id);

  @override
  Future<Role?> getByName(String name) async {
    await ensureSystemRoles();
    final normalized = name.trim().toLowerCase();
    for (final role in _store.values) {
      if (role.name.toLowerCase() == normalized) {
        return role;
      }
    }
    return null;
  }

  @override
  Future<void> delete(RoleId id) async {
    final role = _store[id];
    if (role != null && !role.isSystem) {
      _store.remove(id);
    }
  }

  @override
  Future<void> deleteById(RoleId id) => delete(id);
}
