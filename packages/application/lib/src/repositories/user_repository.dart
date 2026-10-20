/// User repository contract and in-memory default implementation.
library;

import 'package:domain/domain.dart';

import 'repository.dart';

abstract interface class UserRepository implements Repository<User, UserId> {
  Future<User?> getByUsername(String username);

  Future<int> count();

  Future<void> update(User entity);

  Future<bool> exists(UserId id);

  Future<void> delete(UserId id);
}

/// In-memory implementation of [UserRepository].
class InMemoryUserRepository implements UserRepository {
  final Map<UserId, User> _store = {};

  @override
  Future<void> add(User entity) async {
    _store[entity.id] = entity;
  }

  @override
  Future<void> update(User entity) async {
    _store[entity.id] = entity;
  }

  @override
  Future<User?> getById(UserId id) async {
    return _store[id];
  }

  @override
  Future<List<User>> getAll() async {
    return _store.values.toList(growable: false);
  }

  @override
  Future<bool> exists(UserId id) async {
    return _store.containsKey(id);
  }

  @override
  Future<bool> existsById(UserId id) => exists(id);

  @override
  Future<User?> getByUsername(String username) async {
    final normalized = username.trim().toLowerCase();
    for (final user in _store.values) {
      if (user.username == normalized) {
        return user;
      }
    }
    return null;
  }

  @override
  Future<int> count() async {
    return _store.length;
  }

  @override
  Future<void> delete(UserId id) async {
    _store.remove(id);
  }

  @override
  Future<void> deleteById(UserId id) => delete(id);
}
