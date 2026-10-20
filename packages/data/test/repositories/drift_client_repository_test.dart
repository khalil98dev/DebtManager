import 'package:application/application.dart';
import 'package:data/data.dart';
import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DriftClientRepository', () {
    late AppDatabase db;
    late DriftClientRepository repository;

    setUp(() {
      db = AppDatabase.inMemory();
      repository = DriftClientRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('add persists client and getById retrieves exact entity', () async {
      final client = Client.create(
        name: 'John Doe',
        phone: '+2135550001',
        notes: 'Preferred client',
      );

      await repository.add(client);

      final retrieved = await repository.getById(client.id);
      expect(retrieved, isNotNull);
      expect(retrieved!.id, equals(client.id));
      expect(retrieved.name, equals('John Doe'));
      expect(retrieved.phone, equals('+2135550001'));
      expect(retrieved.notes, equals('Preferred client'));
      expect(retrieved.createdAt, equals(client.createdAt));
      expect(retrieved.updatedAt, equals(client.updatedAt));
    });

    test('handles nullable phone and notes properly', () async {
      final client = Client.create(name: 'Jane Smith');

      await repository.add(client);

      final retrieved = await repository.getById(client.id);
      expect(retrieved, isNotNull);
      expect(retrieved!.phone, isNull);
      expect(retrieved.notes, isNull);
    });

    test('getById returns null when client does not exist', () async {
      final nonExistentId = ClientId.generate();
      final retrieved = await repository.getById(nonExistentId);
      expect(retrieved, isNull);
    });

    test(
      'existsById returns true for existing client and false otherwise',
      () async {
        final client = Client.create(name: 'Exists Check');
        await repository.add(client);

        expect(await repository.existsById(client.id), isTrue);
        expect(await repository.existsById(ClientId.generate()), isFalse);
      },
    );

    test('getAll returns all persisted clients', () async {
      final client1 = Client.create(name: 'Alpha Corp');
      final client2 = Client.create(name: 'Beta LLC');

      await repository.add(client1);
      await repository.add(client2);

      final all = await repository.getAll();
      expect(all.length, equals(2));
      expect(all.map((c) => c.name), containsAll(['Alpha Corp', 'Beta LLC']));
    });

    test('deleteById removes client from database', () async {
      final client = Client.create(name: 'To Delete');
      await repository.add(client);

      expect(await repository.existsById(client.id), isTrue);

      await repository.deleteById(client.id);

      expect(await repository.existsById(client.id), isFalse);
      expect(await repository.getById(client.id), isNull);
    });

    test('getByName finds client case-insensitively', () async {
      final client = Client.create(name: 'Sidi Bel Abbes');
      await repository.add(client);

      final foundExact = await repository.getByName('Sidi Bel Abbes');
      expect(foundExact, isNotNull);
      expect(foundExact!.id, equals(client.id));

      final foundLower = await repository.getByName('sidi bel abbes');
      expect(foundLower, isNotNull);
      expect(foundLower!.id, equals(client.id));

      final foundSpaces = await repository.getByName('  Sidi Bel Abbes  ');
      expect(foundSpaces, isNotNull);
      expect(foundSpaces!.id, equals(client.id));

      final notFound = await repository.getByName('Oran');
      expect(notFound, isNull);
    });

    test('existsByName returns true when client exists by name', () async {
      final client = Client.create(name: 'Constantine Corp');
      await repository.add(client);

      expect(await repository.existsByName('Constantine Corp'), isTrue);
      expect(await repository.existsByName('constantine corp'), isTrue);
      expect(await repository.existsByName('Algiers LLC'), isFalse);
    });

    test(
      'add with existing ID updates client (insertOnConflictUpdate)',
      () async {
        final original = Client.create(
          name: 'Original Name',
          phone: '+2135551111',
        );
        await repository.add(original);

        final updated = original
            .rename('Updated Name')
            .changePhone('+2137772222');
        await repository.add(updated);

        final retrieved = await repository.getById(original.id);
        expect(retrieved, isNotNull);
        expect(retrieved!.name, equals('Updated Name'));
        final all = await repository.getAll();
        expect(all.length, equals(1));
      },
    );

    test('preserves exact DateTime precision roundtrip', () async {
      final preciseTime = DateTime.utc(2026, 10, 19, 14, 25, 30, 456);
      final client = Client.create(
        name: 'Timestamp Precision',
        createdAt: preciseTime,
      );
      await repository.add(client);

      final retrieved = await repository.getById(client.id);
      expect(retrieved!.createdAt, equals(preciseTime));
    });
  });

  group('DriftClientRepository + Application Layer Integration', () {
    late AppDatabase db;
    late DriftClientRepository repository;
    late CreateClient createClient;
    late GetClientById getClientById;

    setUp(() {
      db = AppDatabase.inMemory();
      repository = DriftClientRepository(db);
      createClient = CreateClient(repository);
      getClientById = GetClientById(repository);
    });

    tearDown(() async {
      await db.close();
    });

    test(
      'CreateClient usecase persists and returns new client via Drift',
      () async {
        final command = const CreateClientCommand(
          name: 'Amine Gouiri',
          phone: '+213661000000',
          notes: 'National team striker',
        );

        final result = await createClient.execute(command);

        expect(result.isSuccess, isTrue);
        final client = result.dataOrNull!;
        expect(client.name, equals('Amine Gouiri'));

        // Verify directly via repository query
        final persisted = await repository.getById(client.id);
        expect(persisted, isNotNull);
        expect(persisted!.name, equals('Amine Gouiri'));
        expect(persisted.phone, equals('+213661000000'));
      },
    );

    test('CreateClient supports caller-supplied ID into SQLite', () async {
      final customId = ClientId.generate();
      final command = CreateClientCommand(
        id: customId,
        name: 'Ismael Bennacer',
      );

      final result = await createClient.execute(command);

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull!.id, equals(customId));

      final persisted = await repository.getById(customId);
      expect(persisted, isNotNull);
      expect(persisted!.id, equals(customId));
    });

    test(
      'CreateClient handles idempotent retry with matching data in SQLite',
      () async {
        final suppliedId = ClientId.generate();
        final command = CreateClientCommand(
          id: suppliedId,
          name: 'Youcef Atal',
          phone: '+213770000000',
        );

        final firstResult = await createClient.execute(command);
        expect(firstResult.isSuccess, isTrue);

        final retryResult = await createClient.execute(command);
        expect(retryResult.isSuccess, isTrue);
        expect(retryResult.dataOrNull!.id, equals(suppliedId));

        final all = await repository.getAll();
        expect(all.length, equals(1));
      },
    );

    test(
      'CreateClient returns ConflictFailure when ID exists with differing data',
      () async {
        final suppliedId = ClientId.generate();
        final command1 = CreateClientCommand(
          id: suppliedId,
          name: 'Ramy Bensebaini',
        );
        await createClient.execute(command1);

        final command2 = CreateClientCommand(
          id: suppliedId,
          name: 'Aissa Mandi',
        );
        final result = await createClient.execute(command2);

        expect(result.isFailure, isTrue);
        expect(result.failureOrNull, isA<ConflictFailure>());
      },
    );

    test(
      'GetClientById retrieves client created through CreateClient',
      () async {
        final createResult = await createClient.execute(
          const CreateClientCommand(name: 'Houssem Aouar'),
        );
        final client = createResult.dataOrNull!;

        final queryResult = await getClientById.execute(
          GetClientByIdQuery(client.id),
        );

        expect(queryResult.isSuccess, isTrue);
        expect(queryResult.dataOrNull!.name, equals('Houssem Aouar'));
      },
    );

    test('GetClientById returns NotFoundFailure when not in SQLite', () async {
      final result = await getClientById.execute(
        GetClientByIdQuery(ClientId.generate()),
      );

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<NotFoundFailure>());
    });
  });
}
