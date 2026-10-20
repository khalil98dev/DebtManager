/// Payment allocation repository contract.
library;

import 'package:domain/domain.dart';

import 'repository.dart';

abstract interface class PaymentAllocationRepository
    implements Repository<PaymentAllocation, PaymentAllocationId> {
  Future<List<PaymentAllocation>> getByPaymentId(PaymentId paymentId);
  Future<List<PaymentAllocation>> getByInvoiceId(InvoiceId invoiceId);
  Future<List<PaymentAllocation>> getByClientId(ClientId clientId);
  Future<PaymentAllocation?> getByPaymentAndInvoice(
    PaymentId paymentId,
    InvoiceId invoiceId,
  );
}
