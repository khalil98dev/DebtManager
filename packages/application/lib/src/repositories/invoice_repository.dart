/// Invoice repository contract.
library;

import 'package:domain/domain.dart';

import 'repository.dart';

abstract interface class InvoiceRepository
    implements Repository<Invoice, InvoiceId> {
  Future<List<Invoice>> getByClientId(
    ClientId clientId, {
    InvoiceStatus? status,
  });

  Future<Invoice?> getByNumber(String number);
}
