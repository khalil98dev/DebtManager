import 'package:application/application.dart';
import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/in_memory_repositories.dart';

void main() {
  group('UpdateClient Command', () {
    late InMemoryClientRepository clientRepo;
    late UpdateClient updateClient;

    setUp(() {
      clientRepo = InMemoryClientRepository();
      updateClient = UpdateClient(clientRepo);
    });

    test('updates existing client details successfully', () async {
      final client = Client.create(
        name: 'Original Name',
        phone: '0555111222',
        notes: 'Old notes',
      );
      await clientRepo.add(client);

      final result = await updateClient.execute(
        UpdateClientCommand(
          id: client.id,
          name: 'Updated Name',
          phone: '0555999888',
          notes: 'New notes',
        ),
      );

      expect(result.isSuccess, isTrue);
      final updated = result.dataOrNull!;
      expect(updated.id, equals(client.id));
      expect(updated.name, equals('Updated Name'));
      expect(updated.phone, equals('0555999888'));
      expect(updated.notes, equals('New notes'));

      final fromRepo = await clientRepo.getById(client.id);
      expect(fromRepo?.name, equals('Updated Name'));
    });

    test('returns NotFoundFailure when client does not exist', () async {
      final nonExistentId = ClientId.generate();
      final result = await updateClient.execute(
        UpdateClientCommand(id: nonExistentId, name: 'Ghost Client'),
      );

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<NotFoundFailure>());
    });

    test('returns ValidationFailure when name is empty', () async {
      final client = Client.create(name: 'Valid Name');
      await clientRepo.add(client);

      final result = await updateClient.execute(
        UpdateClientCommand(id: client.id, name: '   '),
      );

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<ValidationFailure>());
    });
  });
}
