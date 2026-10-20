/// Represents the supported domain entity types for offline synchronization.
enum SyncEntityType {
  client,
  invoice,
  payment,
  paymentAllocation;

  static SyncEntityType fromName(String name) {
    return SyncEntityType.values.firstWhere(
      (e) => e.name == name,
      orElse: () => throw ArgumentError.value(
        name,
        'name',
        'Unsupported sync entity type: $name.',
      ),
    );
  }
}
