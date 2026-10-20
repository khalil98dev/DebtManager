import 'package:application/application.dart';
import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/in_memory_repositories.dart';

void main() {
  group('CreateClient Command', () {
    late InMemoryClientRepository clientRepo;
    late CreateClient createClient;

    setUp(() {
      clientRepo = InMemoryClientRepository();
      createClient = CreateClient(clientRepo);
    });

    test('creates and persists a client with a generated ID', () async {
      final command = const CreateClientCommand(
        name: '  Karim Benzema  ',
        phone: ' +2135551234 ',
        notes: ' VIP Client ',
      );

      final result = await createClient.execute(command);

      expect(result.isSuccess, isTrue);
      final client = result.dataOrNull!;
      expect(client.id, isA<ClientId>());
      expect(client.name, 'Karim Benzema');
      expect(client.phone, '+2135551234');
      expect(client.notes, 'VIP Client');

      final saved = await clientRepo.getById(client.id);
      expect(saved, equals(client));
    });

    test('supports custom caller-supplied typed ID', () async {
      final customId = ClientId.generate();
      final customTime = DateTime.utc(2026, 1, 15, 10, 30);
      final command = CreateClientCommand(
        id: customId,
        name: 'Zinedine Zidane',
        createdAt: customTime,
      );

      final result = await createClient.execute(command);

      expect(result.isSuccess, isTrue);
      final client = result.dataOrNull!;
      expect(client.id, customId);
      expect(client.name, 'Zinedine Zidane');
      expect(client.createdAt, customTime);

      final saved = await clientRepo.getById(customId);
      expect(saved, equals(client));
    });

    test(
      'treats repeated creation with identical data as idempotent retry',
      () async {
        final suppliedId = ClientId.generate();
        final command = CreateClientCommand(
          id: suppliedId,
          name: 'Riyad Mahrez',
          phone: '+2137700000',
          notes: 'Al-Ahli forward',
        );

        final firstResult = await createClient.execute(command);
        expect(firstResult.isSuccess, isTrue);

        // Replay identical command
        final retryResult = await createClient.execute(command);
        expect(retryResult.isSuccess, isTrue);
        expect(retryResult.dataOrNull!.id, equals(suppliedId));
        expect(retryResult.dataOrNull!.name, equals('Riyad Mahrez'));

        // Ensure repository still has only 1 record
        final allClients = await clientRepo.getAll();
        expect(allClients.length, equals(1));
      },
    );

    test(
      'returns ConflictFailure when supplied ID collides with differing data',
      () async {
        final suppliedId = ClientId.generate();
        final originalCommand = CreateClientCommand(
          id: suppliedId,
          name: 'Original Client Name',
          phone: '+2135550000',
        );
        await createClient.execute(originalCommand);

        // Colliding command with same ID but different name
        final collidingCommand = CreateClientCommand(
          id: suppliedId,
          name: 'Different Client Name',
          phone: '+2135550000',
        );
        final result = await createClient.execute(collidingCommand);

        expect(result.isFailure, isTrue);
        expect(result.failureOrNull, isA<ConflictFailure>());
        expect(
          result.failureOrNull!.message,
          contains('already exists with differing data'),
        );

        // Original client remains untouched
        final saved = await clientRepo.getById(suppliedId);
        expect(saved!.name, equals('Original Client Name'));
      },
    );

    test(
      'returns ValidationFailure when name is empty or whitespace-only',
      () async {
        final command = const CreateClientCommand(name: '   ');

        final result = await createClient.execute(command);

        expect(result.isFailure, isTrue);
        expect(result.failureOrNull, isA<ValidationFailure>());
        expect(await clientRepo.getAll(), isEmpty);
      },
    );
  });
}
