import 'package:application/application.dart';
import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/in_memory_repositories.dart';

void main() {
  group('AllocatePayment Command', () {
    late InMemoryUnitOfWork unitOfWork;
    late AllocatePayment allocatePayment;
    late Client clientA;
    late Client clientB;
    late Invoice issuedInvoiceA;
    late Invoice draftInvoiceA;
    late Payment paymentA;

    setUp(() async {
      unitOfWork = InMemoryUnitOfWork();
      allocatePayment = AllocatePayment(unitOfWork);

      clientA = Client.create(name: 'Client A');
      clientB = Client.create(name: 'Client B');
      await unitOfWork.clients.add(clientA);
      await unitOfWork.clients.add(clientB);

      final lineA = InvoiceLine.create(
        description: 'Goods A',
        quantity: 1,
        unitPrice: Money.dzd(10000), // 100.00 DZD
      );

      draftInvoiceA = Invoice.draft(
        clientId: clientA.id,
        number: 'INV-A-DRAFT',
        lines: [lineA],
      );
      issuedInvoiceA = Invoice.draft(
        clientId: clientA.id,
        number: 'INV-A-ISSUED',
        lines: [lineA],
      ).issue();

      paymentA = Payment.create(
        clientId: clientA.id,
        amount: Money.dzd(10000), // 100.00 DZD
      );

      await unitOfWork.invoices.add(draftInvoiceA);
      await unitOfWork.invoices.add(issuedInvoiceA);
      await unitOfWork.payments.add(paymentA);
    });

    test(
      'successfully allocates payment to issued invoice with generated ID',
      () async {
        final command = AllocatePaymentCommand(
          paymentId: paymentA.id,
          invoiceId: issuedInvoiceA.id,
          amount: Money.dzd(6000),
        );

        final result = await allocatePayment.execute(command);

        expect(result.isSuccess, isTrue);
        final allocation = result.dataOrNull!;
        expect(allocation.id, isA<PaymentAllocationId>());
        expect(allocation.paymentId, paymentA.id);
        expect(allocation.invoiceId, issuedInvoiceA.id);
        expect(allocation.amount, equals(Money.dzd(6000)));

        final saved = await unitOfWork.paymentAllocations.getById(
          allocation.id,
        );
        expect(saved, equals(allocation));
      },
    );

    test('supports custom caller-supplied typed PaymentAllocationId', () async {
      final customId = PaymentAllocationId.generate();
      final command = AllocatePaymentCommand(
        id: customId,
        paymentId: paymentA.id,
        invoiceId: issuedInvoiceA.id,
        amount: Money.dzd(4000),
      );

      final result = await allocatePayment.execute(command);

      expect(result.isSuccess, isTrue);
      final allocation = result.dataOrNull!;
      expect(allocation.id, equals(customId));

      final saved = await unitOfWork.paymentAllocations.getById(customId);
      expect(saved, equals(allocation));
    });

    test(
      'treats repeated allocation with identical data as idempotent retry',
      () async {
        final suppliedId = PaymentAllocationId.generate();
        final command = AllocatePaymentCommand(
          id: suppliedId,
          paymentId: paymentA.id,
          invoiceId: issuedInvoiceA.id,
          amount: Money.dzd(3000),
        );

        final firstResult = await allocatePayment.execute(command);
        expect(firstResult.isSuccess, isTrue);

        // Replay identical command
        final retryResult = await allocatePayment.execute(command);
        expect(retryResult.isSuccess, isTrue);
        expect(retryResult.dataOrNull!.id, equals(suppliedId));

        final all = await unitOfWork.paymentAllocations.getAll();
        expect(all.length, equals(1));
      },
    );

    test(
      'returns ConflictFailure when supplied ID collides with differing data',
      () async {
        final suppliedId = PaymentAllocationId.generate();
        final originalCommand = AllocatePaymentCommand(
          id: suppliedId,
          paymentId: paymentA.id,
          invoiceId: issuedInvoiceA.id,
          amount: Money.dzd(3000),
        );
        await allocatePayment.execute(originalCommand);

        // Colliding command with different amount
        final collidingCommand = AllocatePaymentCommand(
          id: suppliedId,
          paymentId: paymentA.id,
          invoiceId: issuedInvoiceA.id,
          amount: Money.dzd(5000),
        );
        final result = await allocatePayment.execute(collidingCommand);

        expect(result.isFailure, isTrue);
        expect(result.failureOrNull, isA<ConflictFailure>());
        expect(
          result.failureOrNull!.message,
          contains('already exists with differing data'),
        );
      },
    );

    test(
      'returns ValidationFailure when allocation amount is zero or negative',
      () async {
        final command = AllocatePaymentCommand(
          paymentId: paymentA.id,
          invoiceId: issuedInvoiceA.id,
          amount: Money.zero(Currency.dzd),
        );

        final result = await allocatePayment.execute(command);

        expect(result.isFailure, isTrue);
        expect(result.failureOrNull, isA<ValidationFailure>());
        expect(result.failureOrNull!.message, contains('strictly positive'));
      },
    );

    test('returns NotFoundFailure when payment does not exist', () async {
      final missingPaymentId = PaymentId.generate();
      final command = AllocatePaymentCommand(
        paymentId: missingPaymentId,
        invoiceId: issuedInvoiceA.id,
        amount: Money.dzd(5000),
      );

      final result = await allocatePayment.execute(command);

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<NotFoundFailure>());
      final nf = result.failureOrNull! as NotFoundFailure;
      expect(nf.entityType, 'Payment');
      expect(nf.entityId, missingPaymentId);
    });

    test('returns NotFoundFailure when invoice does not exist', () async {
      final missingInvoiceId = InvoiceId.generate();
      final command = AllocatePaymentCommand(
        paymentId: paymentA.id,
        invoiceId: missingInvoiceId,
        amount: Money.dzd(5000),
      );

      final result = await allocatePayment.execute(command);

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<NotFoundFailure>());
      final nf = result.failureOrNull! as NotFoundFailure;
      expect(nf.entityType, 'Invoice');
      expect(nf.entityId, missingInvoiceId);
    });

    test('returns ValidationFailure for cross-client allocation', () async {
      final paymentB = Payment.create(
        clientId: clientB.id,
        amount: Money.dzd(10000),
      );
      await unitOfWork.payments.add(paymentB);

      final command = AllocatePaymentCommand(
        paymentId: paymentB.id,
        invoiceId: issuedInvoiceA.id,
        amount: Money.dzd(5000),
      );

      final result = await allocatePayment.execute(command);

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<ValidationFailure>());
      expect(
        result.failureOrNull!.message,
        contains('Cross-client allocation violation'),
      );
    });

    test(
      'returns ValidationFailure when allocating to a draft invoice',
      () async {
        final command = AllocatePaymentCommand(
          paymentId: paymentA.id,
          invoiceId: draftInvoiceA.id,
          amount: Money.dzd(5000),
        );

        final result = await allocatePayment.execute(command);

        expect(result.isFailure, isTrue);
        expect(result.failureOrNull, isA<ValidationFailure>());
        expect(result.failureOrNull!.message, contains('draft invoice'));
      },
    );

    test('returns ValidationFailure on currency mismatch', () async {
      final eur = Currency(code: 'EUR');
      final command = AllocatePaymentCommand(
        paymentId: paymentA.id,
        invoiceId: issuedInvoiceA.id,
        amount: Money.fromSubunits(5000, eur),
      );

      final result = await allocatePayment.execute(command);

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<ValidationFailure>());
      expect(result.failureOrNull!.message, contains('Currency mismatch'));
    });

    test(
      'returns ConflictFailure when active allocation already exists for pair without custom ID',
      () async {
        final firstAlloc = PaymentAllocation.create(
          paymentId: paymentA.id,
          invoiceId: issuedInvoiceA.id,
          amount: Money.dzd(3000),
        );
        await unitOfWork.paymentAllocations.add(firstAlloc);

        final command = AllocatePaymentCommand(
          paymentId: paymentA.id,
          invoiceId: issuedInvoiceA.id,
          amount: Money.dzd(2000),
        );

        final result = await allocatePayment.execute(command);

        expect(result.isFailure, isTrue);
        expect(result.failureOrNull, isA<ConflictFailure>());
        expect(
          result.failureOrNull!.message,
          contains('active allocation already exists'),
        );
      },
    );

    test(
      'returns ValidationFailure when amount exceeds remaining payment capacity',
      () async {
        final lineOther = InvoiceLine.create(
          description: 'Other Invoice',
          quantity: 1,
          unitPrice: Money.dzd(8000),
        );
        final otherInvoice = Invoice.draft(
          clientId: clientA.id,
          number: 'INV-A-OTHER',
          lines: [lineOther],
        ).issue();
        await unitOfWork.invoices.add(otherInvoice);

        // Existing allocation uses 8,000 DZD out of 10,000 DZD payment -> 2,000 DZD remaining
        final existingAlloc = PaymentAllocation.create(
          paymentId: paymentA.id,
          invoiceId: otherInvoice.id,
          amount: Money.dzd(8000),
        );
        await unitOfWork.paymentAllocations.add(existingAlloc);

        // Attempt to allocate 3,000 DZD to issuedInvoiceA (exceeds 2,000 DZD remaining capacity)
        final command = AllocatePaymentCommand(
          paymentId: paymentA.id,
          invoiceId: issuedInvoiceA.id,
          amount: Money.dzd(3000),
        );

        final result = await allocatePayment.execute(command);

        expect(result.isFailure, isTrue);
        expect(result.failureOrNull, isA<ValidationFailure>());
        expect(
          result.failureOrNull!.message,
          contains('Payment capacity exceeded'),
        );
      },
    );

    test(
      'returns ValidationFailure when amount exceeds remaining invoice balance',
      () async {
        final payment2 = Payment.create(
          clientId: clientA.id,
          amount: Money.dzd(7000),
        );
        await unitOfWork.payments.add(payment2);

        final existingAlloc = PaymentAllocation.create(
          paymentId: payment2.id,
          invoiceId: issuedInvoiceA.id,
          amount: Money.dzd(7000),
        );
        await unitOfWork.paymentAllocations.add(existingAlloc);

        final command = AllocatePaymentCommand(
          paymentId: paymentA.id,
          invoiceId: issuedInvoiceA.id,
          amount: Money.dzd(4000),
        );

        final result = await allocatePayment.execute(command);

        expect(result.isFailure, isTrue);
        expect(result.failureOrNull, isA<ValidationFailure>());
        expect(
          result.failureOrNull!.message,
          contains('Invoice balance exceeded'),
        );
      },
    );

    test(
      'successfully allocates exact 100% remaining capacity and balance',
      () async {
        final command = AllocatePaymentCommand(
          paymentId: paymentA.id,
          invoiceId: issuedInvoiceA.id,
          amount: Money.dzd(10000),
        );

        final result = await allocatePayment.execute(command);

        expect(result.isSuccess, isTrue);
        final allocation = result.dataOrNull!;
        expect(allocation.amount, equals(Money.dzd(10000)));
      },
    );

    test(
      'returns RepositoryFailure when unit of work throws persistence error',
      () async {
        final failingUow = _FailingUnitOfWork();
        final failingAllocation = AllocatePayment(failingUow);

        final command = AllocatePaymentCommand(
          paymentId: paymentA.id,
          invoiceId: issuedInvoiceA.id,
          amount: Money.dzd(5000),
        );

        final result = await failingAllocation.execute(command);

        expect(result.isFailure, isTrue);
        expect(result.failureOrNull, isA<RepositoryFailure>());
        expect(
          result.failureOrNull!.message,
          contains('Simulated storage error'),
        );
      },
    );
  });
}

class _FailingUnitOfWork implements UnitOfWork {
  @override
  Future<T> saveChangesAsync<T>(
    Future<T> Function(UnitOfWorkScope scope) action,
  ) async {
    throw Exception('Simulated storage error');
  }
}
