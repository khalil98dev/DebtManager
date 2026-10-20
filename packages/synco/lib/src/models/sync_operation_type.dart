/// Represents the type of business mutation being synchronized.
enum SyncOperationType {
  create,
  update,
  issue,
  delete;

  static SyncOperationType fromName(String name) {
    return SyncOperationType.values.firstWhere(
      (e) => e.name == name,
      orElse: () => throw ArgumentError.value(
        name,
        'name',
        'Unsupported sync operation type: $name.',
      ),
    );
  }
}
