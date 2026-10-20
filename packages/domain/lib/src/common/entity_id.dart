import 'package:meta/meta.dart';
import 'package:uuid/uuid.dart';

import 'validation_utils.dart';

@immutable
class EntityId<T> implements Comparable<EntityId<T>> {
  const EntityId._(this.value);

  factory EntityId(String value) {
    final trimmed = ValidationUtils.validateAndTrimRequired(
      value,
      name: 'value',
      message: 'EntityId cannot be empty.',
    );
    return EntityId._(trimmed);
  }

  factory EntityId.fromString(String value) => EntityId(value);

  factory EntityId.generate() => EntityId._(const Uuid().v7());

  final String value;
  @override
  int compareTo(EntityId<T> other) => value.compareTo(other.value);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is EntityId<T> && other.value == value);

  @override
  int get hashCode => Object.hash(T, value);

  @override
  String toString() => 'EntityId($value)';

  String toJson() => value;
}
