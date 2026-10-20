import 'package:application/application.dart';
import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/in_memory_repositories.dart';

void main() {
  group('RecordPayment Command', () {
    late InMemoryClientRepository clientRepo;
    late InMemoryPaymentRepository paymentRepo;
    late RecordPayment recordPayment;
    late Client client;

    setUp(() async {
      clientRepo = InMemoryClientRepository();
      paymentRepo = InMemoryPaymentRepository();
      recordPayment = RecordPayment(
        clientRepository: clientRepo,
        paymentRepository: paymentRepo,
      );

      client = Client.create(name: 'Paying Client');
      await clientRepo.add(client);
    });

    test('records and persists payment with generated ID', () async {
      final receivedAt = DateTime.utc(2026, 4, 1, 9, 30);
      final command = RecordPaymentCommand(
        clientId: client.id,
        amount: Money.dzd(15000),
        receivedAt: receivedAt,
        notes: 'Cash payment with receipt #442',
      );

      final result = await recordPayment.execute(command);

      expect(result.isSuccess, isTrue);
      final payment = result.dataOrNull!;
      expect(payment.id, isA<PaymentId>());
      expect(payment.clientId, client.id);
      expect(payment.amount, equals(Money.dzd(15000)));
      expect(payment.receivedAt, receivedAt);
      expect(payment.notes, 'Cash payment with receipt #442');

      final saved = await paymentRepo.getById(payment.id);
      expect(saved, equals(payment));
    });

    test('supports custom caller-supplied typed PaymentId', () async {
      final customId = PaymentId.generate();
      final command = RecordPaymentCommand(
        id: customId,
        clientId: client.id,
        amount: Money.dzd(25000),
      );

      final result = await recordPayment.execute(command);

      expect(result.isSuccess, isTrue);
      final payment = result.dataOrNull!;
      expect(payment.id, equals(customId));

      final saved = await paymentRepo.getById(customId);
      expect(saved, equals(payment));
    });

    test(
      'treats repeated creation with identical data as idempotent retry',
      () async {
        final suppliedId = PaymentId.generate();
        final command = RecordPaymentCommand(
          id: suppliedId,
          clientId: client.id,
          amount: Money.dzd(30000),
          notes: 'Cheque #1234',
        );

        final firstResult = await recordPayment.execute(command);
        expect(firstResult.isSuccess, isTrue);

        final retryResult = await recordPayment.execute(command);
        expect(retryResult.isSuccess, isTrue);
        expect(retryResult.dataOrNull!.id, equals(suppliedId));

        final all = await paymentRepo.getAll();
        expect(all.length, equals(1));
      },
    );

    test(
      'returns ConflictFailure when supplied ID collides with differing data',
      () async {
        final suppliedId = PaymentId.generate();
        final originalCommand = RecordPaymentCommand(
          id: suppliedId,
          clientId: client.id,
          amount: Money.dzd(10000),
        );
        await recordPayment.execute(originalCommand);

        // Colliding request with different amount
        final collidingCommand = RecordPaymentCommand(
          id: suppliedId,
          clientId: client.id,
          amount: Money.dzd(99999),
        );
        final result = await recordPayment.execute(collidingCommand);

        expect(result.isFailure, isTrue);
        expect(result.failureOrNull, isA<ConflictFailure>());
        expect(
          result.failureOrNull!.message,
          contains('already exists with differing data'),
        );
      },
    );

    test('returns NotFoundFailure when client does not exist', () async {
      final missingClientId = ClientId.generate();
      final command = RecordPaymentCommand(
        clientId: missingClientId,
        amount: Money.dzd(5000),
      );

      final result = await recordPayment.execute(command);

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<NotFoundFailure>());
      final nf = result.failureOrNull! as NotFoundFailure;
      expect(nf.entityType, 'Client');
      expect(nf.entityId, missingClientId);
      expect(await paymentRepo.getAll(), isEmpty);
    });

    test('returns ValidationFailure when amount is zero or negative', () async {
      final zeroCommand = RecordPaymentCommand(
        clientId: client.id,
        amount: Money.zero(Currency.dzd),
      );
      final resultZero = await recordPayment.execute(zeroCommand);
      expect(resultZero.isFailure, isTrue);
      expect(resultZero.failureOrNull, isA<ValidationFailure>());

      final negativeCommand = RecordPaymentCommand(
        clientId: client.id,
        amount: Money.dzd(-500),
      );
      final resultNegative = await recordPayment.execute(negativeCommand);
      expect(resultNegative.isFailure, isTrue);
      expect(resultNegative.failureOrNull, isA<ValidationFailure>());
    });
  });
}
