library;

import 'package:domain/domain.dart';

import 'repository.dart';

abstract interface class PaymentRepository
    implements Repository<Payment, PaymentId> {
  Future<List<Payment>> getByClientId(ClientId clientId);
}
