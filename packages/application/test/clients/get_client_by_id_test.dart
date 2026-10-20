import 'package:application/application.dart';
import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/in_memory_repositories.dart';

void main() {
  group('GetClientById Query', () {
    late InMemoryClientRepository clientRepo;
    late GetClientById getClientById;

    setUp(() {
      clientRepo = InMemoryClientRepository();
      getClientById = GetClientById(clientRepo);
    });

    test('returns client when found', () async {
      final client = Client.create(name: 'Client A');
      await clientRepo.add(client);

      final result = await getClientById.execute(GetClientByIdQuery(client.id));

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull, equals(client));
    });

    test('returns NotFoundFailure when client does not exist', () async {
      final nonExistentId = ClientId.generate();

      final result = await getClientById.execute(
        GetClientByIdQuery(nonExistentId),
      );

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<NotFoundFailure>());
      final nf = result.failureOrNull! as NotFoundFailure;
      expect(nf.entityType, equals('Client'));
      expect(nf.entityId, equals(nonExistentId));
    });
  });
}
