library;

import 'client_repository.dart';
import 'invoice_repository.dart';
import 'payment_allocation_repository.dart';
import 'payment_repository.dart';

abstract interface class UnitOfWorkScope {
  ClientRepository get clients;

  InvoiceRepository get invoices;

  PaymentRepository get payments;

  PaymentAllocationRepository get paymentAllocations;
}

abstract interface class UnitOfWork {
  Future<T> saveChangesAsync<T>(
    Future<T> Function(UnitOfWorkScope scope) action,
  );
}
