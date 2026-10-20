import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ClientId', () {
    test('creates a ClientId with valid trimmed string', () {
      final id = ClientId('  client-123  ');
      expect(id.value, 'client-123');
      expect(id.toString(), 'EntityId(client-123)');
    });

    test('creates a ClientId using fromString factory', () {
      final id = ClientId.fromString('client-456');
      expect(id.value, 'client-456');
    });

    test('generates globally unique IDs', () {
      final id1 = ClientId.generate();
      final id2 = ClientId.generate();

      expect(id1.value, isNotEmpty);
      expect(id2.value, isNotEmpty);
      expect(id1, isNot(equals(id2)));
      expect(id1.value, isNot(equals(id2.value)));
    });

    test('rejects empty string with ArgumentError', () {
      expect(() => ClientId(''), throwsArgumentError);
    });

    test('rejects whitespace-only string with ArgumentError', () {
      expect(() => ClientId('   \t\n  '), throwsArgumentError);
    });

    test('implements value equality and hashCode', () {
      final id1 = ClientId('client-1');
      final id2 = ClientId('client-1');
      final id3 = ClientId('client-2');

      expect(id1, equals(id2));
      expect(id1.hashCode, equals(id2.hashCode));

      expect(id1, isNot(equals(id3)));
      expect(id1.hashCode, isNot(equals(id3.hashCode)));
    });
  });
}
