import 'package:application/application.dart';
import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/in_memory_repositories.dart';

void main() {
  group('GetPaymentById Query', () {
    late InMemoryPaymentRepository paymentRepo;
    late GetPaymentById getPaymentById;

    setUp(() {
      paymentRepo = InMemoryPaymentRepository();
      getPaymentById = GetPaymentById(paymentRepo);
    });

    test('returns payment when found', () async {
      final payment = Payment.create(
        clientId: ClientId.generate(),
        amount: Money.dzd(5000),
      );
      await paymentRepo.add(payment);

      final result = await getPaymentById.execute(
        GetPaymentByIdQuery(payment.id),
      );

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull, equals(payment));
    });

    test('returns NotFoundFailure when payment does not exist', () async {
      final nonExistentId = PaymentId.generate();

      final result = await getPaymentById.execute(
        GetPaymentByIdQuery(nonExistentId),
      );

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<NotFoundFailure>());
      final nf = result.failureOrNull! as NotFoundFailure;
      expect(nf.entityType, equals('Payment'));
      expect(nf.entityId, equals(nonExistentId));
    });
  });
}
