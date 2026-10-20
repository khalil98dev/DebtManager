import 'package:application/application.dart';
import 'package:synco/synco.dart';

import '../database/app_database.dart';
import 'drift_client_repository.dart';
import 'drift_invoice_repository.dart';
import 'drift_payment_allocation_repository.dart';
import 'drift_payment_repository.dart';
import 'drift_sync_outbox_repository.dart';

/// Drift and SQLite implementation of [UnitOfWork] and [SyncUnitOfWork].
///
/// Wraps atomic multi-repository operations inside a SQLite transaction.
/// If any operation fails or an exception is thrown, all changes are rolled back automatically.
/// Also provides transactional synchronization outbox recording.
final class DriftUnitOfWork implements SyncUnitOfWork {
  const DriftUnitOfWork(this.db);

  final AppDatabase db;

  @override
  Future<T> saveChangesAsync<T>(
    Future<T> Function(UnitOfWorkScope scope) action,
  ) async {
    return db.transaction(() async {
      final scope = _DriftUnitOfWorkScope(db);
      return await action(scope);
    });
  }

  @override
  Future<T> saveChangesWithSyncAsync<T>(
    Future<T> Function(SyncUnitOfWorkScope scope) action,
  ) async {
    return db.transaction(() async {
      final scope = _DriftUnitOfWorkScope(db);
      return await action(scope);
    });
  }
}

final class _DriftUnitOfWorkScope implements SyncUnitOfWorkScope {
  _DriftUnitOfWorkScope(this.db)
    : clients = DriftClientRepository(db),
      invoices = DriftInvoiceRepository(db),
      payments = DriftPaymentRepository(db),
      paymentAllocations = DriftPaymentAllocationRepository(db),
      syncOutbox = DriftSyncOutboxRepository(db);

  final AppDatabase db;

  @override
  final ClientRepository clients;

  @override
  final InvoiceRepository invoices;

  @override
  final PaymentRepository payments;

  @override
  final PaymentAllocationRepository paymentAllocations;

  @override
  final SyncOutboxRepository syncOutbox;
}
