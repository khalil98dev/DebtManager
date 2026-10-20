import 'package:application/application.dart';
import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/in_memory_repositories.dart';

void main() {
  group('GetPaymentAllocationById Query', () {
    late InMemoryPaymentAllocationRepository allocationRepo;
    late GetPaymentAllocationById getPaymentAllocationById;

    setUp(() {
      allocationRepo = InMemoryPaymentAllocationRepository();
      getPaymentAllocationById = GetPaymentAllocationById(allocationRepo);
    });

    test('returns allocation when found', () async {
      final allocation = PaymentAllocation.create(
        paymentId: PaymentId.generate(),
        invoiceId: InvoiceId.generate(),
        amount: Money.dzd(5000),
      );
      await allocationRepo.add(allocation);

      final result = await getPaymentAllocationById.execute(
        GetPaymentAllocationByIdQuery(allocation.id),
      );

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull, equals(allocation));
    });

    test('returns NotFoundFailure when allocation does not exist', () async {
      final nonExistentId = PaymentAllocationId.generate();

      final result = await getPaymentAllocationById.execute(
        GetPaymentAllocationByIdQuery(nonExistentId),
      );

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<NotFoundFailure>());
      final nf = result.failureOrNull! as NotFoundFailure;
      expect(nf.entityType, equals('PaymentAllocation'));
      expect(nf.entityId, equals(nonExistentId));
    });
  });
}
