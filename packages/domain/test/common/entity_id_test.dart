import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

class EntityA {}

class EntityB {}

void main() {
  group('EntityId', () {
    test('creates an EntityId with valid trimmed string', () {
      final id = EntityId<EntityA>('  entity-123  ');
      expect(id.value, 'entity-123');
      expect(id.toString(), 'EntityId(entity-123)');
      expect(id.toJson(), 'entity-123');
    });

    test('creates an EntityId using fromString factory', () {
      final id = EntityId<EntityA>.fromString('  entity-456  ');
      expect(id.value, 'entity-456');
    });

    test('generates globally unique IDs', () {
      final id1 = EntityId<EntityA>.generate();
      final id2 = EntityId<EntityA>.generate();

      expect(id1.value, isNotEmpty);
      expect(id2.value, isNotEmpty);
      expect(id1, isNot(equals(id2)));
      expect(id1.value, isNot(equals(id2.value)));
    });

    test('rejects empty string with ArgumentError', () {
      expect(() => EntityId<EntityA>(''), throwsArgumentError);
    });

    test('rejects whitespace-only string with ArgumentError', () {
      expect(() => EntityId<EntityA>('   \t\r\n '), throwsArgumentError);
    });

    test('implements value equality and hashCode for the same entity type', () {
      final id1 = EntityId<EntityA>('id-1');
      final id2 = EntityId<EntityA>('id-1');
      final id3 = EntityId<EntityA>('id-2');

      expect(id1, equals(id2));
      expect(id1.hashCode, equals(id2.hashCode));

      expect(id1, isNot(equals(id3)));
      expect(id1.hashCode, isNot(equals(id3.hashCode)));
    });

    test('differentiates equality across different entity types', () {
      final idA = EntityId<EntityA>('same-id');
      final idB = EntityId<EntityB>('same-id');

      expect(idA.value, equals(idB.value));
      expect(idA, isNot(equals(idB)));
      expect(idA.hashCode, isNot(equals(idB.hashCode)));
    });

    test('implements Comparable ordering based on string value', () {
      final a = EntityId<EntityA>('a');
      final b = EntityId<EntityA>('b');
      final c = EntityId<EntityA>('c');

      final list = [c, a, b]..sort();
      expect(list, equals([a, b, c]));
      expect(a.compareTo(b), isNegative);
      expect(b.compareTo(a), isPositive);
      expect(a.compareTo(EntityId<EntityA>('a')), isZero);
    });
  });
}
