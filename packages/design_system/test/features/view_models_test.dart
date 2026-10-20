import 'package:application/application.dart';
import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:synco/synco.dart';

// --- In-memory test fakes for design_system tests ---

class _FakeClientRepo implements ClientRepository {
  final List<Client> list = [];

  @override
  Future<void> add(Client entity) async {
    list.removeWhere((c) => c.id == entity.id);
    list.add(entity);
  }

  @override
  Future<void> deleteById(ClientId id) async =>
      list.removeWhere((c) => c.id == id);

  @override
  Future<bool> existsById(ClientId id) async => list.any((c) => c.id == id);

  @override
  Future<bool> existsByName(String name) async =>
      list.any((c) => c.name.toLowerCase() == name.toLowerCase());

  @override
  Future<List<Client>> getAll() async => List.unmodifiable(list);

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

class _FakeInvoiceRepo implements InvoiceRepository {
  final List<Invoice> list = [];

  @override
  Future<void> add(Invoice entity) async {
    list.removeWhere((i) => i.id == entity.id);
    list.add(entity);
  }

  @override
  Future<void> deleteById(InvoiceId id) async =>
      list.removeWhere((i) => i.id == id);

  @override
  Future<bool> existsById(InvoiceId id) async => list.any((i) => i.id == id);

  @override
  Future<List<Invoice>> getAll() async => List.unmodifiable(list);

  @override
  Future<Invoice?> getById(InvoiceId id) async {
    try {
      return list.firstWhere((i) => i.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<Invoice>> getByClientId(
    ClientId clientId, {
    InvoiceStatus? status,
  }) async {
    return list.where((i) {
      if (i.clientId != clientId) return false;
      if (status != null && i.status != status) return false;
      return true;
    }).toList();
  }

  @override
  Future<Invoice?> getByNumber(String number) async {
    try {
      return list.firstWhere((i) => i.number == number);
    } catch (_) {
      return null;
    }
  }

  Future<bool> existsByNumber(String number) async =>
      list.any((i) => i.number == number);
}

class _FakePaymentRepo implements PaymentRepository {
  final List<Payment> list = [];

  @override
  Future<void> add(Payment entity) async {
    list.removeWhere((p) => p.id == entity.id);
    list.add(entity);
  }

  @override
  Future<void> deleteById(PaymentId id) async =>
      list.removeWhere((p) => p.id == id);

  @override
  Future<bool> existsById(PaymentId id) async => list.any((p) => p.id == id);

  @override
  Future<List<Payment>> getAll() async => List.unmodifiable(list);

  @override
  Future<Payment?> getById(PaymentId id) async {
    try {
      return list.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<Payment>> getByClientId(ClientId clientId) async =>
      list.where((p) => p.clientId == clientId).toList();
}

class _FakeAllocationRepo implements PaymentAllocationRepository {
  final List<PaymentAllocation> list = [];

  @override
  Future<void> add(PaymentAllocation entity) async => list.add(entity);

  @override
  Future<void> deleteById(PaymentAllocationId id) async =>
      list.removeWhere((a) => a.id == id);

  @override
  Future<bool> existsById(PaymentAllocationId id) async =>
      list.any((a) => a.id == id);

  @override
  Future<List<PaymentAllocation>> getAll() async => List.unmodifiable(list);

  @override
  Future<PaymentAllocation?> getById(PaymentAllocationId id) async {
    try {
      return list.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<PaymentAllocation>> getByInvoiceId(InvoiceId invoiceId) async =>
      list.where((a) => a.invoiceId == invoiceId).toList();

  @override
  Future<List<PaymentAllocation>> getByPaymentId(PaymentId paymentId) async =>
      list.where((a) => a.paymentId == paymentId).toList();

  @override
  Future<List<PaymentAllocation>> getByClientId(ClientId clientId) async => [];

  @override
  Future<PaymentAllocation?> getByPaymentAndInvoice(
    PaymentId paymentId,
    InvoiceId invoiceId,
  ) async {
    try {
      return list.firstWhere(
        (a) => a.paymentId == paymentId && a.invoiceId == invoiceId,
      );
    } catch (_) {
      return null;
    }
  }
}

class _FakeOutboxRepo implements SyncOutboxRepository {
  final List<SyncOperation> list = [];
  int _sequence = 1;

  @override
  Future<void> enqueue(SyncOperation operation) async => list.add(operation);

  @override
  Future<SyncOperation?> getById(SyncOperationId id) async {
    try {
      return list.firstWhere((o) => o.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<SyncOperation>> getPending({int? limit}) async =>
      list.where((o) => o.status == SyncStatus.pending).toList();

  @override
  Future<List<SyncOperation>> getByStatus(
    SyncStatus status, {
    int? limit,
  }) async => list.where((o) => o.status == status).toList();

  @override
  Future<List<SyncOperation>> getByEntity(
    SyncEntityType entityType,
    String entityId,
  ) async => list
      .where((o) => o.entityType == entityType && o.entityId == entityId)
      .toList();

  @override
  Future<void> updateStatus(
    SyncOperationId id,
    SyncStatus status, {
    String? errorMessage,
    bool? isRetryable,
    DateTime? processedAt,
  }) async {}

  @override
  Future<void> update(SyncOperation operation) async {}

  @override
  Future<int> getNextLocalSequence() async => _sequence++;

  @override
  Future<int> getLatestEntityVersion(
    SyncEntityType entityType,
    String entityId,
  ) async => 1;

  @override
  Future<void> clearAll() async => list.clear();
}

class _FakeUnitOfWorkScope implements UnitOfWorkScope {
  _FakeUnitOfWorkScope({
    required this.clients,
    required this.invoices,
    required this.payments,
    required this.paymentAllocations,
  });

  @override
  final ClientRepository clients;
  @override
  final InvoiceRepository invoices;
  @override
  final PaymentRepository payments;
  @override
  final PaymentAllocationRepository paymentAllocations;
}

class _FakeUnitOfWork implements UnitOfWork {
  _FakeUnitOfWork([_FakeUnitOfWorkScope? scope])
    : scope =
          scope ??
          _FakeUnitOfWorkScope(
            clients: _FakeClientRepo(),
            invoices: _FakeInvoiceRepo(),
            payments: _FakePaymentRepo(),
            paymentAllocations: _FakeAllocationRepo(),
          );

  final _FakeUnitOfWorkScope scope;

  @override
  Future<T> saveChangesAsync<T>(
    Future<T> Function(UnitOfWorkScope scope) action,
  ) => action(scope);
}

void main() {
  group('Feature ViewModels Test Suite', () {
    late _FakeClientRepo clientRepo;
    late _FakeInvoiceRepo invoiceRepo;
    late _FakePaymentRepo paymentRepo;
    late _FakeAllocationRepo allocRepo;
    late _FakeOutboxRepo outboxRepo;

    setUp(() {
      clientRepo = _FakeClientRepo();
      invoiceRepo = _FakeInvoiceRepo();
      paymentRepo = _FakePaymentRepo();
      allocRepo = _FakeAllocationRepo();
      outboxRepo = _FakeOutboxRepo();
    });

    test('DashboardViewModel loads summary with metrics', () async {
      final client = Client.create(name: 'Client Alpha');
      await clientRepo.add(client);

      final invoice = Invoice.draft(
        clientId: client.id,
        number: 'INV-101',
        lines: [
          InvoiceLine(
            id: InvoiceLineId.generate(),
            description: 'Item 1',
            quantity: 2,
            unitPrice: Money.fromSubunits(10000, Currency.dzd),
            createdAt: DateTime.now(),
          ),
        ],
      );
      await invoiceRepo.add(invoice);

      final getDashboard = GetDashboardSummary(
        clientRepository: clientRepo,
        invoiceRepository: invoiceRepo,
        paymentRepository: paymentRepo,
        paymentAllocationRepository: allocRepo,
      );

      final vm = DashboardViewModel(getDashboardSummary: getDashboard);
      await vm.loadSummary();

      expect(vm.state.status, DashboardStatus.loaded);
      expect(vm.state.summary, isNotNull);
      expect(vm.state.summary!.totalDraftInvoices, 1);
      expect(vm.state.summary!.totalIssuedInvoices, 0);
    });

    test(
      'InvoiceListViewModel loads, filters by status, and searches',
      () async {
        final client = Client.create(name: 'Beta Trading');
        await clientRepo.add(client);

        final draftInv = Invoice.draft(
          clientId: client.id,
          number: 'INV-DRAFT-1',
          lines: [
            InvoiceLine(
              id: InvoiceLineId.generate(),
              description: 'Consulting',
              quantity: 1,
              unitPrice: Money.fromSubunits(5000, Currency.dzd),
              createdAt: DateTime.now(),
            ),
          ],
        );
        final issuedInv = Invoice.draft(
          clientId: client.id,
          number: 'INV-ISSUED-2',
          lines: [
            InvoiceLine(
              id: InvoiceLineId.generate(),
              description: 'Design',
              quantity: 1,
              unitPrice: Money.fromSubunits(8000, Currency.dzd),
              createdAt: DateTime.now(),
            ),
          ],
        ).issue();

        await invoiceRepo.add(draftInv);
        await invoiceRepo.add(issuedInv);

        final vm = InvoiceListViewModel(
          invoiceRepository: invoiceRepo,
          clientRepository: clientRepo,
        );

        await vm.loadInvoices();

        expect(vm.state.status, InvoiceListStatus.loaded);
        expect(vm.state.invoices.length, 2);

        // Filter by Draft
        vm.filterByStatus(InvoiceStatus.draft);
        expect(vm.state.filteredInvoices.length, 1);
        expect(vm.state.filteredInvoices.first.number, 'INV-DRAFT-1');

        // Filter by Issued
        vm.filterByStatus(InvoiceStatus.issued);
        expect(vm.state.filteredInvoices.length, 1);
        expect(vm.state.filteredInvoices.first.number, 'INV-ISSUED-2');

        // Search query
        vm.filterByStatus(null);
        vm.search('DRAFT');
        expect(vm.state.filteredInvoices.length, 1);
      },
    );

    test('PaymentListViewModel loads payments and filters by query', () async {
      final client = Client.create(name: 'Gamma Corp');
      await clientRepo.add(client);

      final payment = Payment.create(
        clientId: client.id,
        amount: Money.fromSubunits(20000, Currency.dzd),
        receivedAt: DateTime.now(),
        notes: 'Cash deposit receipt #45',
      );
      await paymentRepo.add(payment);

      final vm = PaymentListViewModel(
        paymentRepository: paymentRepo,
        clientRepository: clientRepo,
      );

      await vm.loadPayments();

      expect(vm.state.status, PaymentListStatus.loaded);
      expect(vm.state.payments.length, 1);

      vm.search('Gamma');
      expect(vm.state.filteredPayments.length, 1);

      vm.search('NonExistent');
      expect(vm.state.filteredPayments, isEmpty);
    });

    test('SyncStatusViewModel loads outbox diagnostics', () async {
      await outboxRepo.getNextLocalSequence(); // 1
      await outboxRepo.getNextLocalSequence(); // 2

      final vm = SyncStatusViewModel(outboxRepository: outboxRepo);
      await vm.loadDiagnostics();

      expect(vm.state.status, SyncStatusViewStateStatus.loaded);
      expect(vm.state.latestSequence, 2);
      expect(vm.state.isLocalOnly, isTrue);
      expect(vm.state.pendingCount, 0);
    });

    test('SettingsViewModel toggles theme mode and currency', () async {
      final vm = SettingsViewModel(
        clientRepository: clientRepo,
        invoiceRepository: invoiceRepo,
        paymentRepository: paymentRepo,
        paymentAllocationRepository: allocRepo,
        outboxRepository: outboxRepo,
      );

      expect(vm.state.themeMode, ThemeMode.system);
      vm.setThemeMode(ThemeMode.dark);
      expect(vm.state.themeMode, ThemeMode.dark);

      expect(vm.state.primaryCurrency, Currency.dzd);
      final eur = Currency.fromCode('EUR', symbol: '€');
      vm.setPrimaryCurrency(eur);
      expect(vm.state.primaryCurrency, eur);

      await vm.loadDiagnostics();
      expect(vm.state.status, SettingsLoadStatus.loaded);
      expect(vm.state.databaseStats.storageEngine, 'SQLite + Drift');
      expect(vm.state.databaseStats.schemaVersion, 3);
    });

    test(
      'InvoiceFormViewModel directly creates and issues invoice in one step',
      () async {
        final client = Client.create(name: 'Direct Issue Client');
        await clientRepo.add(client);

        final createInvoice = CreateInvoice(
          clientRepository: clientRepo,
          invoiceRepository: invoiceRepo,
        );
        final updateInvoiceDraft = UpdateInvoiceDraft(
          clientRepository: clientRepo,
          invoiceRepository: invoiceRepo,
        );
        final issueInvoice = IssueInvoice(invoiceRepo);

        final vm = InvoiceFormViewModel(
          clientRepository: clientRepo,
          createInvoice: createInvoice,
          updateInvoiceDraft: updateInvoiceDraft,
          issueInvoice: issueInvoice,
        );

        await vm.initialize();
        vm.onClientSelected(client);
        vm.onNumberChanged('INV-DIRECT-001');

        // Update default line item
        final lineId = vm.state.lines.first.id;
        vm.updateLineDescription(lineId, 'Full Website Redesign');
        vm.updateLineQuantity(lineId, 1);
        vm.updateLineUnitPrice(lineId, '150000');

        // Execute direct issue
        final issued = await vm.submit(issueDirectly: true);

        expect(issued, isNotNull);
        expect(issued!.isIssued, isTrue);
        expect(issued.status, equals(InvoiceStatus.issued));
        expect(issued.issuedAt, isNotNull);
        expect(
          issued.grossTotal,
          equals(Money.fromSubunits(15000000, Currency.dzd)),
        );

        // Verify persisted in invoice repository as issued
        final persisted = await invoiceRepo.getById(issued.id);
        expect(persisted, isNotNull);
        expect(persisted!.isIssued, isTrue);
        expect(persisted.status, equals(InvoiceStatus.issued));
      },
    );

    test(
      'InvoiceFormViewModel and PaymentFormViewModel refresh clients dynamically',
      () async {
        final vm = InvoiceFormViewModel(
          clientRepository: clientRepo,
          createInvoice: CreateInvoice(
            clientRepository: clientRepo,
            invoiceRepository: invoiceRepo,
          ),
          updateInvoiceDraft: UpdateInvoiceDraft(
            clientRepository: clientRepo,
            invoiceRepository: invoiceRepo,
          ),
        );

        await vm.initialize();
        expect(vm.state.availableClients, isEmpty);

        // Now add a client to repo
        final newClient = Client.create(name: 'Dynamic Client');
        await clientRepo.add(newClient);

        // Trigger refresh
        await vm.refreshClients();
        expect(vm.state.availableClients.length, 1);
        expect(vm.state.availableClients.first.name, 'Dynamic Client');

        // Same for PaymentFormViewModel
        final payVm = PaymentFormViewModel(
          clientRepository: clientRepo,
          recordPayment: RecordPayment(
            paymentRepository: paymentRepo,
            clientRepository: clientRepo,
          ),
        );
        await payVm.initialize();
        expect(payVm.state.availableClients.length, 1);

        // Add another client
        final client2 = Client.create(name: 'Second Dynamic Client');
        await clientRepo.add(client2);

        await payVm.refreshClients();
        expect(payVm.state.availableClients.length, 2);
      },
    );

    test('AppDependencies dataRevision triggers reactive notifications', () {
      final deps = AppDependencies(
        clientRepository: clientRepo,
        invoiceRepository: invoiceRepo,
        paymentRepository: paymentRepo,
        paymentAllocationRepository: allocRepo,
        syncOutboxRepository: outboxRepo,
        unitOfWork: _FakeUnitOfWork(),
      );

      int notifyCount = 0;
      deps.dataRevision.addListener(() => notifyCount++);

      expect(deps.dataRevision.value, 0);
      expect(notifyCount, 0);

      deps.notifyDataChanged();
      expect(deps.dataRevision.value, 1);
      expect(notifyCount, 1);

      deps.notifyDataChanged();
      expect(deps.dataRevision.value, 2);
      expect(notifyCount, 2);
    });
  });
}
