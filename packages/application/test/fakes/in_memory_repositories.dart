import 'package:application/application.dart';
import 'package:domain/domain.dart';

/// Base in-memory repository implementing common CRUD operations.
abstract class InMemoryRepository<T, TId> implements Repository<T, TId> {
  final Map<TId, T> storage = {};

  TId getId(T entity);

  @override
  Future<T?> getById(TId id) async => storage[id];

  @override
  Future<bool> existsById(TId id) async => storage.containsKey(id);

  @override
  Future<List<T>> getAll() async => List.unmodifiable(storage.values);

  @override
  Future<void> add(T entity) async {
    storage[getId(entity)] = entity;
  }

  @override
  Future<void> deleteById(TId id) async {
    storage.remove(id);
  }
}

/// In-memory fake implementation of [ClientRepository].
class InMemoryClientRepository extends InMemoryRepository<Client, ClientId>
    implements ClientRepository {
  @override
  ClientId getId(Client entity) => entity.id;

  @override
  Future<Client?> getByName(String name) async {
    final trimmed = name.trim().toLowerCase();
    try {
      return storage.values.firstWhere((c) => c.name.toLowerCase() == trimmed);
    } on StateError {
      return null;
    }
  }

  @override
  Future<bool> existsByName(String name) async {
    final client = await getByName(name);
    return client != null;
  }
}

/// In-memory fake implementation of [InvoiceRepository].
class InMemoryInvoiceRepository extends InMemoryRepository<Invoice, InvoiceId>
    implements InvoiceRepository {
  @override
  InvoiceId getId(Invoice entity) => entity.id;

  @override
  Future<List<Invoice>> getByClientId(
    ClientId clientId, {
    InvoiceStatus? status,
  }) async {
    return storage.values.where((inv) {
      if (inv.clientId != clientId) return false;
      if (status != null && inv.status != status) return false;
      return true;
    }).toList();
  }

  @override
  Future<Invoice?> getByNumber(String number) async {
    final trimmed = number.trim();
    try {
      return storage.values.firstWhere((inv) => inv.number == trimmed);
    } on StateError {
      return null;
    }
  }
}

/// In-memory fake implementation of [PaymentRepository].
class InMemoryPaymentRepository extends InMemoryRepository<Payment, PaymentId>
    implements PaymentRepository {
  @override
  PaymentId getId(Payment entity) => entity.id;

  @override
  Future<List<Payment>> getByClientId(ClientId clientId) async {
    return storage.values.where((p) => p.clientId == clientId).toList();
  }
}

/// In-memory fake implementation of [PaymentAllocationRepository].
class InMemoryPaymentAllocationRepository
    extends InMemoryRepository<PaymentAllocation, PaymentAllocationId>
    implements PaymentAllocationRepository {
  InMemoryPaymentAllocationRepository({this.findClientIdForAllocation});

  final ClientId? Function(PaymentAllocation allocation)?
  findClientIdForAllocation;

  @override
  PaymentAllocationId getId(PaymentAllocation entity) => entity.id;

  @override
  Future<List<PaymentAllocation>> getByPaymentId(PaymentId paymentId) async {
    return storage.values.where((a) => a.paymentId == paymentId).toList();
  }

  @override
  Future<List<PaymentAllocation>> getByInvoiceId(InvoiceId invoiceId) async {
    return storage.values.where((a) => a.invoiceId == invoiceId).toList();
  }

  @override
  Future<PaymentAllocation?> getByPaymentAndInvoice(
    PaymentId paymentId,
    InvoiceId invoiceId,
  ) async {
    try {
      return storage.values.firstWhere(
        (a) => a.paymentId == paymentId && a.invoiceId == invoiceId,
      );
    } on StateError {
      return null;
    }
  }

  @override
  Future<List<PaymentAllocation>> getByClientId(ClientId clientId) async {
    if (findClientIdForAllocation != null) {
      return storage.values
          .where((a) => findClientIdForAllocation!(a) == clientId)
          .toList();
    }
    return storage.values.toList();
  }
}

/// Internal transactional scope for in-memory fake repositories.
class _InMemoryUnitOfWorkScope implements UnitOfWorkScope {
  const _InMemoryUnitOfWorkScope({
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

/// In-memory fake implementation of [UnitOfWork] with rollback support on exception.
class InMemoryUnitOfWork implements UnitOfWork {
  InMemoryUnitOfWork({
    InMemoryClientRepository? clientRepository,
    InMemoryInvoiceRepository? invoiceRepository,
    InMemoryPaymentRepository? paymentRepository,
    InMemoryPaymentAllocationRepository? paymentAllocationRepository,
  }) : clients = clientRepository ?? InMemoryClientRepository(),
       invoices = invoiceRepository ?? InMemoryInvoiceRepository(),
       payments = paymentRepository ?? InMemoryPaymentRepository() {
    paymentAllocations =
        paymentAllocationRepository ??
        InMemoryPaymentAllocationRepository(
          findClientIdForAllocation: (alloc) {
            final payment = payments.storage[alloc.paymentId];
            if (payment != null) return payment.clientId;
            final invoice = invoices.storage[alloc.invoiceId];
            if (invoice != null) return invoice.clientId;
            return null;
          },
        );
  }

  final InMemoryClientRepository clients;
  final InMemoryInvoiceRepository invoices;
  final InMemoryPaymentRepository payments;
  late final InMemoryPaymentAllocationRepository paymentAllocations;

  @override
  Future<T> saveChangesAsync<T>(
    Future<T> Function(UnitOfWorkScope scope) action,
  ) async {
    final clientSnapshot = Map<ClientId, Client>.of(clients.storage);
    final invoiceSnapshot = Map<InvoiceId, Invoice>.of(invoices.storage);
    final paymentSnapshot = Map<PaymentId, Payment>.of(payments.storage);
    final allocationSnapshot = Map<PaymentAllocationId, PaymentAllocation>.of(
      paymentAllocations.storage,
    );

    final scope = _InMemoryUnitOfWorkScope(
      clients: clients,
      invoices: invoices,
      payments: payments,
      paymentAllocations: paymentAllocations,
    );

    try {
      return await action(scope);
    } catch (_) {
      clients.storage
        ..clear()
        ..addAll(clientSnapshot);
      invoices.storage
        ..clear()
        ..addAll(invoiceSnapshot);
      payments.storage
        ..clear()
        ..addAll(paymentSnapshot);
      paymentAllocations.storage
        ..clear()
        ..addAll(allocationSnapshot);
      rethrow;
    }
  }
}
