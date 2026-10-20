import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Client', () {
    final fixedId = ClientId('client-001');
    final fixedCreatedAt = DateTime.utc(2026, 1, 1, 10, 0, 0);
    final fixedUpdatedAt = DateTime.utc(2026, 1, 1, 12, 0, 0);

    test('instantiates with all fields and trims name', () {
      final client = Client(
        id: fixedId,
        name: '  Jane Doe  ',
        phone: '  +1234567890  ',
        notes: '  Important client  ',
        createdAt: fixedCreatedAt,
        updatedAt: fixedUpdatedAt,
      );

      expect(client.id, fixedId);
      expect(client.name, 'Jane Doe');
      expect(client.phone, '+1234567890');
      expect(client.notes, 'Important client');
      expect(client.createdAt, fixedCreatedAt);
      expect(client.updatedAt, fixedUpdatedAt);
    });

    test('defaults updatedAt to createdAt when not provided', () {
      final client = Client(
        id: fixedId,
        name: 'John Doe',
        createdAt: fixedCreatedAt,
      );

      expect(client.updatedAt, fixedCreatedAt);
      expect(client.phone, isNull);
      expect(client.notes, isNull);
    });

    test('rejects empty and whitespace-only names with ArgumentError', () {
      expect(
        () => Client(id: fixedId, name: '', createdAt: fixedCreatedAt),
        throwsArgumentError,
      );

      expect(
        () => Client(id: fixedId, name: '   \t \n ', createdAt: fixedCreatedAt),
        throwsArgumentError,
      );
    });

    test('normalizes blank phone numbers and notes to null', () {
      final clientEmptyStrings = Client(
        id: fixedId,
        name: 'Test Client',
        phone: '',
        notes: '',
        createdAt: fixedCreatedAt,
      );
      expect(clientEmptyStrings.phone, isNull);
      expect(clientEmptyStrings.notes, isNull);

      final clientWhitespaceStrings = Client(
        id: fixedId,
        name: 'Test Client',
        phone: '   \t  ',
        notes: '   \n  ',
        createdAt: fixedCreatedAt,
      );
      expect(clientWhitespaceStrings.phone, isNull);
      expect(clientWhitespaceStrings.notes, isNull);
    });

    test('rejects updatedAt that is before createdAt', () {
      expect(
        () => Client(
          id: fixedId,
          name: 'Test Client',
          createdAt: fixedCreatedAt,
          updatedAt: fixedCreatedAt.subtract(const Duration(seconds: 1)),
        ),
        throwsArgumentError,
      );
    });

    test('create factory generates unique id and timestamps automatically', () {
      final client = Client.create(name: 'Auto Client', phone: ' 9876543210 ');

      expect(client.id.value, isNotEmpty);
      expect(client.name, 'Auto Client');
      expect(client.phone, '9876543210');
      expect(client.notes, isNull);
      expect(client.createdAt, equals(client.updatedAt));
    });

    test('create factory respects custom id and createdAt', () {
      final client = Client.create(
        id: fixedId,
        name: 'Custom Client',
        createdAt: fixedCreatedAt,
      );

      expect(client.id, fixedId);
      expect(client.createdAt, fixedCreatedAt);
      expect(client.updatedAt, fixedCreatedAt);
    });

    group('rename', () {
      test(
        'renames client, trims new name, and preserves id and createdAt',
        () {
          final client = Client(
            id: fixedId,
            name: 'Original Name',
            phone: '123456',
            notes: 'Notes',
            createdAt: fixedCreatedAt,
          );

          final newTimestamp = fixedCreatedAt.add(const Duration(minutes: 5));
          final updated = client.rename(
            '  Updated Name  ',
            updatedAt: newTimestamp,
          );

          expect(updated.id, fixedId);
          expect(updated.createdAt, fixedCreatedAt);
          expect(updated.name, 'Updated Name');
          expect(updated.phone, '123456');
          expect(updated.notes, 'Notes');
          expect(updated.updatedAt, newTimestamp);

          // Original client must remain unchanged (immutability)
          expect(client.name, 'Original Name');
        },
      );

      test('rejects empty or blank new name with ArgumentError', () {
        final client = Client(
          id: fixedId,
          name: 'Original Name',
          createdAt: fixedCreatedAt,
        );

        expect(() => client.rename(''), throwsArgumentError);
        expect(() => client.rename('   '), throwsArgumentError);
      });
    });

    group('changePhone and updatePhone', () {
      test(
        'updates phone, normalizes blanks to null, preserves id and createdAt',
        () {
          final client = Client(
            id: fixedId,
            name: 'Original Name',
            phone: '123456',
            createdAt: fixedCreatedAt,
          );

          final newTimestamp = fixedCreatedAt.add(const Duration(minutes: 10));
          final withNewPhone = client.changePhone(
            '  999888  ',
            updatedAt: newTimestamp,
          );
          expect(withNewPhone.phone, '999888');
          expect(withNewPhone.id, fixedId);
          expect(withNewPhone.createdAt, fixedCreatedAt);
          expect(withNewPhone.updatedAt, newTimestamp);

          final withNullPhone = withNewPhone.changePhone(null);
          expect(withNullPhone.phone, isNull);

          final withBlankPhone = withNewPhone.changePhone('   ');
          expect(withBlankPhone.phone, isNull);

          final aliasCall = client.updatePhone('555', updatedAt: newTimestamp);
          expect(aliasCall.phone, '555');
        },
      );
    });

    group('updateNotes and changeNotes', () {
      test(
        'updates notes, normalizes blanks to null, preserves id and createdAt',
        () {
          final client = Client(
            id: fixedId,
            name: 'Original Name',
            notes: 'Old notes',
            createdAt: fixedCreatedAt,
          );

          final newTimestamp = fixedCreatedAt.add(const Duration(minutes: 10));
          final withNewNotes = client.updateNotes(
            '  New notes  ',
            updatedAt: newTimestamp,
          );
          expect(withNewNotes.notes, 'New notes');
          expect(withNewNotes.id, fixedId);
          expect(withNewNotes.createdAt, fixedCreatedAt);
          expect(withNewNotes.updatedAt, newTimestamp);

          final withNullNotes = withNewNotes.updateNotes(null);
          expect(withNullNotes.notes, isNull);

          final withBlankNotes = withNewNotes.updateNotes('  \t\n ');
          expect(withBlankNotes.notes, isNull);

          final aliasCall = client.changeNotes(
            'Notes alias',
            updatedAt: newTimestamp,
          );
          expect(aliasCall.notes, 'Notes alias');
        },
      );
    });

    group('equality and hashCode', () {
      test(
        'two clients with identical id are equal even with different fields',
        () {
          final client1 = Client(
            id: fixedId,
            name: 'Name 1',
            phone: '111',
            notes: 'Notes 1',
            createdAt: fixedCreatedAt,
            updatedAt: fixedCreatedAt,
          );

          final client2 = Client(
            id: fixedId,
            name: 'Name 2',
            phone: '222',
            notes: 'Notes 2',
            createdAt: fixedCreatedAt.add(const Duration(days: 1)),
            updatedAt: fixedCreatedAt.add(const Duration(days: 2)),
          );

          expect(client1, equals(client2));
          expect(client1.hashCode, equals(client2.hashCode));
        },
      );

      test(
        'two clients with different ids are not equal even with identical fields',
        () {
          final client1 = Client(
            id: ClientId('client-001'),
            name: 'Same Name',
            createdAt: fixedCreatedAt,
          );

          final client2 = Client(
            id: ClientId('client-002'),
            name: 'Same Name',
            createdAt: fixedCreatedAt,
          );

          expect(client1, isNot(equals(client2)));
        },
      );
    });

    test('toString includes all properties', () {
      final client = Client(
        id: fixedId,
        name: 'Jane',
        phone: '123',
        notes: 'Notes',
        createdAt: fixedCreatedAt,
        updatedAt: fixedUpdatedAt,
      );

      final str = client.toString();
      expect(str, contains('client-001'));
      expect(str, contains('Jane'));
      expect(str, contains('123'));
      expect(str, contains('Notes'));
    });
  });
}
