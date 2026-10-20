import 'package:application/application.dart';
import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

class _MockRepo implements ClientRepository {
  final List<Client> list = [];
  bool shouldThrow = false;

  @override
  Future<void> add(Client entity) async {
    list.removeWhere((c) => c.id == entity.id);
    list.add(entity);
  }

  @override
  Future<void> deleteById(ClientId id) async {
    if (shouldThrow) throw Exception('Database error');
    list.removeWhere((c) => c.id == id);
  }

  @override
  Future<bool> existsById(ClientId id) async => list.any((c) => c.id == id);

  @override
  Future<bool> existsByName(String name) async =>
      list.any((c) => c.name.toLowerCase() == name.toLowerCase());

  @override
  Future<List<Client>> getAll() async {
    if (shouldThrow) throw Exception('Failed to connect to storage');
    return List.unmodifiable(list);
  }

  @override
  Future<Client?> getById(ClientId id) async {
    try {
      return list.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Client?> getByName(String name) async {
    try {
      return list.firstWhere((c) => c.name.toLowerCase() == name.toLowerCase());
    } catch (_) {
      return null;
    }
  }
}

void main() {
  group('ClientListViewModel', () {
    late _MockRepo repo;
    late ClientListViewModel viewModel;

    setUp(() {
      repo = _MockRepo();
      viewModel = ClientListViewModel(repository: repo);
    });

    test('initial state is uninitialized', () {
      expect(viewModel.state.status, ClientListStatus.initial);
      expect(viewModel.state.clients, isEmpty);
      expect(viewModel.state.filteredClients, isEmpty);
      expect(viewModel.state.isEmpty, isFalse);
    });

    test('loadClients populates and sorts clients alphabetically', () async {
      final c1 = Client.create(name: 'Zara Fashion', phone: '0555111111');
      final c2 = Client.create(name: 'Apple Store', phone: '0555222222');
      final c3 = Client.create(name: 'Bravo Logistics', phone: '0555333333');

      await repo.add(c1);
      await repo.add(c2);
      await repo.add(c3);

      await viewModel.loadClients();

      expect(viewModel.state.status, ClientListStatus.loaded);
      expect(viewModel.state.totalCount, 3);
      expect(viewModel.state.filteredCount, 3);
      // Alphabetical order: Apple, Bravo, Zara
      expect(viewModel.state.clients[0].name, 'Apple Store');
      expect(viewModel.state.clients[1].name, 'Bravo Logistics');
      expect(viewModel.state.clients[2].name, 'Zara Fashion');
      expect(viewModel.state.isEmpty, isFalse);
    });

    test('loadClients on empty repository sets isEmpty to true', () async {
      await viewModel.loadClients();
      expect(viewModel.state.status, ClientListStatus.loaded);
      expect(viewModel.state.isEmpty, isTrue);
      expect(viewModel.state.totalCount, 0);
    });

    test('search filters by name and phone number', () async {
      final c1 = Client.create(name: 'Acme Corp', phone: '0550123456');
      final c2 = Client.create(name: 'Beta Studio', phone: '0550998877');
      final c3 = Client.create(name: 'Delta LLC', phone: null);

      await repo.add(c1);
      await repo.add(c2);
      await repo.add(c3);
      await viewModel.loadClients();

      // Search by name substring
      viewModel.search('acme');
      expect(viewModel.state.filteredCount, 1);
      expect(viewModel.state.filteredClients.first.name, 'Acme Corp');

      // Search by phone substring
      viewModel.search('9988');
      expect(viewModel.state.filteredCount, 1);
      expect(viewModel.state.filteredClients.first.name, 'Beta Studio');

      // Search with no matches sets isSearchEmpty
      viewModel.search('nonexistent');
      expect(viewModel.state.filteredCount, 0);
      expect(viewModel.state.isSearchEmpty, isTrue);

      // Clearing search restores all clients
      viewModel.clearSearch();
      expect(viewModel.state.filteredCount, 3);
      expect(viewModel.state.isSearchEmpty, isFalse);
    });

    test('deleteClient removes entity from list and updates state', () async {
      final c1 = Client.create(name: 'Client A');
      final c2 = Client.create(name: 'Client B');
      await repo.add(c1);
      await repo.add(c2);
      await viewModel.loadClients();

      final success = await viewModel.deleteClient(c1.id);
      expect(success, isTrue);
      expect(viewModel.state.totalCount, 1);
      expect(viewModel.state.clients.first.name, 'Client B');
      expect(await repo.existsById(c1.id), isFalse);
    });

    test('captures repository errors gracefully', () async {
      repo.shouldThrow = true;
      await viewModel.loadClients();

      expect(viewModel.state.status, ClientListStatus.error);
      expect(viewModel.state.hasError, isTrue);
      expect(viewModel.state.errorMessage, contains('Failed to connect'));
    });
  });
}
