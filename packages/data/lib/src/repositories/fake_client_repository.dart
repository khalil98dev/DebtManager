import 'package:application/application.dart';
import 'package:domain/domain.dart';

/// An in-memory, thread-safe fake implementation of [ClientRepository]
/// designed for UI development, previews, and fast automated tests.
///
/// Easily injected into ViewModels and interchangeable with [DriftClientRepository].
class FakeClientRepository implements ClientRepository {
  FakeClientRepository({bool seeded = false}) {
    if (seeded) {
      seedWithSampleData();
    }
  }

  final Map<ClientId, Client> _clients = {};

  @override
  Future<Client?> getById(ClientId id) async => _clients[id];

  @override
  Future<bool> existsById(ClientId id) async => _clients.containsKey(id);

  @override
  Future<List<Client>> getAll() async {
    final list = _clients.values.toList();
    list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return List.unmodifiable(list);
  }

  @override
  Future<void> add(Client entity) async {
    _clients[entity.id] = entity;
  }

  @override
  Future<void> deleteById(ClientId id) async {
    _clients.remove(id);
  }

  @override
  Future<Client?> getByName(String name) async {
    final trimmed = name.trim().toLowerCase();
    if (trimmed.isEmpty) return null;
    try {
      return _clients.values.firstWhere(
        (c) => c.name.trim().toLowerCase() == trimmed,
      );
    } on StateError {
      return null;
    }
  }

  @override
  Future<bool> existsByName(String name) async {
    final client = await getByName(name);
    return client != null;
  }

  /// Clears all clients in memory.
  void clear() {
    _clients.clear();
  }

  /// Seeds realistic Apple HIG-grade demo clients.
  void seedWithSampleData() {
    clear();
    final now = DateTime.now();

    final samples = [
      Client.create(
        id: ClientId.fromString('c1000000-0000-0000-0000-000000000001'),
        name: 'Acme Corporation',
        phone: '+213 550 12 34 56',
        notes: 'Enterprise account. Monthly invoicing on 1st of every month.',
        createdAt: now.subtract(const Duration(days: 90)),
      ),
      Client.create(
        id: ClientId.fromString('c1000000-0000-0000-0000-000000000002'),
        name: 'Studio Nomad Architecture',
        phone: '+213 555 98 76 54',
        notes:
            'Commercial fit-out projects. Prefers communication via WhatsApp.',
        createdAt: now.subtract(const Duration(days: 60)),
      ),
      Client.create(
        id: ClientId.fromString('c1000000-0000-0000-0000-000000000003'),
        name: 'Elena Rostova',
        phone: '+213 561 22 33 44',
        notes: 'Freelance design client. High reliability.',
        createdAt: now.subtract(const Duration(days: 45)),
      ),
      Client.create(
        id: ClientId.fromString('c1000000-0000-0000-0000-000000000004'),
        name: 'Cabinet Médical Bensaad',
        phone: '+213 540 88 99 00',
        notes: 'Medical equipment maintenance contract.',
        createdAt: now.subtract(const Duration(days: 30)),
      ),
      Client.create(
        id: ClientId.fromString('c1000000-0000-0000-0000-000000000005'),
        name: 'TechFlow Solutions',
        phone: '+213 552 44 55 66',
        notes: 'Cloud migration services. NET 30 payment terms.',
        createdAt: now.subtract(const Duration(days: 15)),
      ),
      Client.create(
        id: ClientId.fromString('c1000000-0000-0000-0000-000000000006'),
        name: 'Karim Belkacem',
        phone: '+213 541 77 88 99',
        notes: 'Hardware procurement.',
        createdAt: now.subtract(const Duration(days: 7)),
      ),
      Client.create(
        id: ClientId.fromString('c1000000-0000-0000-0000-000000000007'),
        name: 'Atelier Artisanat & Co',
        phone: null,
        notes: 'Local supplier partner without primary phone listed.',
        createdAt: now.subtract(const Duration(days: 2)),
      ),
    ];

    for (final sample in samples) {
      _clients[sample.id] = sample;
    }
  }
}
