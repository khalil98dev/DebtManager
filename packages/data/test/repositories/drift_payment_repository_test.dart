import 'package:application/application.dart';
import 'package:data/data.dart';
import 'package:domain/domain.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late DriftPaymentRepository paymentRepo;
  late DriftClientRepository clientRepo;

  final testClient = Client(
    id: ClientId.fromString('client-pay-1'),
    name: 'Karim Ziani',
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
  );

  setUp(() async {
    db = AppDatabase.inMemory();
    paymentRepo = DriftPaymentRepository(db);
    clientRepo = DriftClientRepository(db);

    await clientRepo.add(testClient);
  });

  tearDown(() async {
    await db.close();
  });

  group('DriftPaymentRepository - CRUD Operations', () {
    test('persists payment and retrieves exact entity by id', () async {
      final payment = Payment(
        id: PaymentId.fromString('pay-001'),
        clientId: testClient.id,
        amount: Money.fromSubunits(1500000, Currency.dzd), // 15,000.00 DZD
        receivedAt: DateTime.utc(2026, 1, 15, 11, 0),
        notes: 'Check #1234',
        createdAt: DateTime.utc(2026, 1, 15, 11, 5),
      );

      await paymentRepo.add(payment);

      final retrieved = await paymentRepo.getById(payment.id);
      expect(retrieved, isNotNull);
      expect(retrieved!.id, equals(payment.id));
      expect(retrieved.clientId, equals(testClient.id));
      expect(
        retrieved.amount,
        equals(Money.fromSubunits(1500000, Currency.dzd)),
      );
      expect(retrieved.currency, equals(Currency.dzd));
      expect(retrieved.receivedAt, equals(DateTime.utc(2026, 1, 15, 11, 0)));
      expect(retrieved.notes, equals('Check #1234'));
      expect(retrieved.createdAt, equals(DateTime.utc(2026, 1, 15, 11, 5)));
    });

    test('getById returns null when payment does not exist', () async {
      final retrieved = await paymentRepo.getById(
        PaymentId.fromString('non-existent'),
      );
      expect(retrieved, isNull);
    });

    test(
      'existsById returns true for existing and false for missing',
      () async {
        final payment = Payment.create(
          id: PaymentId.fromString('pay-exists'),
          clientId: testClient.id,
          amount: Money.fromSubunits(50000, Currency.dzd),
        );

        expect(await paymentRepo.existsById(payment.id), isFalse);
        await paymentRepo.add(payment);
        expect(await paymentRepo.existsById(payment.id), isTrue);
      },
    );

    test('getAll returns all payments across clients', () async {
      final client2 = Client(
        id: ClientId.fromString('client-pay-2'),
        name: 'Sara B.',
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1),
      );
      await clientRepo.add(client2);

      final p1 = Payment.create(
        id: PaymentId.fromString('p-1'),
        clientId: testClient.id,
        amount: Money.fromSubunits(10000, Currency.dzd),
      );
      final p2 = Payment.create(
        id: PaymentId.fromString('p-2'),
        clientId: client2.id,
        amount: Money.fromSubunits(20000, Currency.dzd),
      );

      await paymentRepo.add(p1);
      await paymentRepo.add(p2);

      final all = await paymentRepo.getAll();
      expect(all.length, equals(2));
      expect(all.map((p) => p.id), containsAll([p1.id, p2.id]));
    });

    test(
      'getByClientId returns only payments for specified client ordered by receivedAt DESC',
      () async {
        final pOld = Payment(
          id: PaymentId.fromString('p-old'),
          clientId: testClient.id,
          amount: Money.fromSubunits(10000, Currency.dzd),
          receivedAt: DateTime.utc(2026, 1, 5),
          createdAt: DateTime.utc(2026, 1, 5),
        );
        final pNew = Payment(
          id: PaymentId.fromString('p-new'),
          clientId: testClient.id,
          amount: Money.fromSubunits(25000, Currency.dzd),
          receivedAt: DateTime.utc(2026, 1, 20),
          createdAt: DateTime.utc(2026, 1, 20),
        );

        await paymentRepo.add(pOld);
        await paymentRepo.add(pNew);

        final clientPayments = await paymentRepo.getByClientId(testClient.id);
        expect(clientPayments.length, equals(2));
        expect(clientPayments[0].id, equals(pNew.id)); // Newer received first
        expect(clientPayments[1].id, equals(pOld.id));
      },
    );

    test('deleteById removes payment from database', () async {
      final payment = Payment.create(
        id: PaymentId.fromString('p-delete'),
        clientId: testClient.id,
        amount: Money.fromSubunits(10000, Currency.dzd),
      );
      await paymentRepo.add(payment);

      await paymentRepo.deleteById(payment.id);
      final retrieved = await paymentRepo.getById(payment.id);
      expect(retrieved, isNull);
    });
  });

  group('DriftPaymentRepository - Financial Immutability & Updates', () {
    test('updating notes on existing payment succeeds', () async {
      final payment = Payment(
        id: PaymentId.fromString('p-notes'),
        clientId: testClient.id,
        amount: Money.fromSubunits(50000, Currency.dzd),
        receivedAt: DateTime.utc(2026, 1, 10),
        notes: 'Initial memo',
        createdAt: DateTime.utc(2026, 1, 10),
      );
      await paymentRepo.add(payment);

      final updatedPayment = payment.updateNotes(
        'Corrected memo with wire ref',
      );
      await paymentRepo.add(updatedPayment);

      final retrieved = await paymentRepo.getById(payment.id);
      expect(retrieved, isNotNull);
      expect(retrieved!.notes, equals('Corrected memo with wire ref'));
      expect(retrieved.amount, equals(Money.fromSubunits(50000, Currency.dzd)));
    });

    test(
      'attempting to alter financial attributes of existing payment throws StateError',
      () async {
        final payment = Payment(
          id: PaymentId.fromString('p-immutable'),
          clientId: testClient.id,
          amount: Money.fromSubunits(50000, Currency.dzd),
          receivedAt: DateTime.utc(2026, 1, 10),
          createdAt: DateTime.utc(2026, 1, 10),
        );
        await paymentRepo.add(payment);

        // Attempting to modify amount on the same payment ID
        final tamperedPayment = Payment(
          id: payment.id,
          clientId: testClient.id,
          amount: Money.fromSubunits(99999, Currency.dzd), // altered!
          receivedAt: DateTime.utc(2026, 1, 10),
          createdAt: DateTime.utc(2026, 1, 10),
        );

        expect(
          () => paymentRepo.add(tamperedPayment),
          throwsA(
            isA<StateError>().having(
              (e) => e.message,
              'message',
              contains(
                'Cannot alter immutable financial transaction attributes',
              ),
            ),
          ),
        );
      },
    );
  });

  group('DriftPaymentRepository - Constraints & Integrity', () {
    test(
      'foreign key restrict prevents deleting client who has recorded payments',
      () async {
        final payment = Payment.create(
          id: PaymentId.fromString('p-fk-restrict'),
          clientId: testClient.id,
          amount: Money.fromSubunits(10000, Currency.dzd),
        );
        await paymentRepo.add(payment);

        expect(
          () => clientRepo.deleteById(testClient.id),
          throwsA(isA<SqliteException>()),
        );
      },
    );

    test('rejects payment referencing non-existent client', () async {
      final invalidPayment = Payment.create(
        id: PaymentId.fromString('p-bad-client'),
        clientId: ClientId.fromString('ghost-client'),
        amount: Money.fromSubunits(10000, Currency.dzd),
      );

      expect(
        () => paymentRepo.add(invalidPayment),
        throwsA(isA<SqliteException>()),
      );
    });
  });

  group('DriftPaymentRepository + Application Layer Integration', () {
    test(
      'RecordPayment usecase persists payment into SQLite with generated ID',
      () async {
        final recordPayment = RecordPayment(
          clientRepository: clientRepo,
          paymentRepository: paymentRepo,
        );

        final command = RecordPaymentCommand(
          clientId: testClient.id,
          amount: Money.fromSubunits(750000, Currency.dzd),
          notes: 'Transfer via CCP',
        );

        final result = await recordPayment.execute(command);
        expect(result.isSuccess, isTrue);

        final payment = result.dataOrNull!;
        expect(
          payment.amount,
          equals(Money.fromSubunits(750000, Currency.dzd)),
        );

        final fromDb = await paymentRepo.getById(payment.id);
        expect(fromDb, isNotNull);
        expect(fromDb!.amount, equals(payment.amount));
        expect(fromDb.notes, equals('Transfer via CCP'));
      },
    );

    test(
      'RecordPayment handles idempotent retry with matching data in SQLite',
      () async {
        final recordPayment = RecordPayment(
          clientRepository: clientRepo,
          paymentRepository: paymentRepo,
        );

        final customId = PaymentId.fromString('pay-custom-id');
        final command = RecordPaymentCommand(
          id: customId,
          clientId: testClient.id,
          amount: Money.fromSubunits(300000, Currency.dzd),
          notes: 'Initial receipt',
        );

        final result1 = await recordPayment.execute(command);
        expect(result1.isSuccess, isTrue);

        // Re-execute exact command with same ID
        final result2 = await recordPayment.execute(command);
        expect(result2.isSuccess, isTrue);
        expect(result2.dataOrNull!.id, equals(customId));
      },
    );

    test(
      'RecordPayment returns ConflictFailure when ID collides with differing data',
      () async {
        final recordPayment = RecordPayment(
          clientRepository: clientRepo,
          paymentRepository: paymentRepo,
        );

        final customId = PaymentId.fromString('pay-collision');
        final command1 = RecordPaymentCommand(
          id: customId,
          clientId: testClient.id,
          amount: Money.fromSubunits(100000, Currency.dzd),
        );
        await recordPayment.execute(command1);

        final command2 = RecordPaymentCommand(
          id: customId,
          clientId: testClient.id,
          amount: Money.fromSubunits(999999, Currency.dzd), // differing amount
        );
        final result2 = await recordPayment.execute(command2);
        expect(result2.isFailure, isTrue);
        expect(result2.failureOrNull, isA<ConflictFailure>());
      },
    );
  });
}
