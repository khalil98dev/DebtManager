import 'package:data/data.dart';
import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FakeClientRepository', () {
    late FakeClientRepository repository;

    setUp(() {
      repository = FakeClientRepository();
    });

    test('starts empty when unseeded', () async {
      expect(await repository.getAll(), isEmpty);
    });

    test('seeds sample clients correctly', () async {
      final seededRepo = FakeClientRepository(seeded: true);
      final clients = await seededRepo.getAll();
      expect(clients.length, greaterThanOrEqualTo(5));
      expect(clients.any((c) => c.name.contains('Acme')), isTrue);
    });

    test('add, getById, existsById, and deleteById work as expected', () async {
      final client = Client.create(name: 'Sarah Connor', phone: '+2135551122');
      await repository.add(client);

      expect(await repository.existsById(client.id), isTrue);
      expect(await repository.getById(client.id), equals(client));

      final all = await repository.getAll();
      expect(all, hasLength(1));
      expect(all.first.name, 'Sarah Connor');

      await repository.deleteById(client.id);
      expect(await repository.existsById(client.id), isFalse);
      expect(await repository.getById(client.id), isNull);
    });

    test('getByName and existsByName match case-insensitively', () async {
      final client = Client.create(name: 'Wayne Enterprises');
      await repository.add(client);

      expect(await repository.existsByName('wayne enterprises'), isTrue);
      expect(await repository.existsByName('WAYNE ENTERPRISES'), isTrue);
      expect(await repository.existsByName('Unknown'), isFalse);

      final found = await repository.getByName('  wayne enterprises  ');
      expect(found, isNotNull);
      expect(found?.name, 'Wayne Enterprises');
    });

    test('updating existing client replaces entity with matching ID', () async {
      final client = Client.create(name: 'Stark Industries', phone: '111');
      await repository.add(client);

      final updated = client.changePhone('222');
      await repository.add(updated);

      final retrieved = await repository.getById(client.id);
      expect(retrieved?.phone, '222');
      expect((await repository.getAll()).length, 1);
    });
  });
}
