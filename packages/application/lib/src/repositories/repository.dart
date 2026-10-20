library;

abstract interface class Repository<T, TId> {
  Future<T?> getById(TId id);
  Future<bool> existsById(TId id);
  Future<List<T>> getAll();
  Future<void> add(T entity);
  Future<void> deleteById(TId id);
}
