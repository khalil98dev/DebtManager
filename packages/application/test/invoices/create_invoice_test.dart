import 'package:application/application.dart';
import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/in_memory_repositories.dart';

void main() {
  group('CreateInvoice Command', () {
    late InMemoryClientRepository clientRepo;
    late InMemoryInvoiceRepository invoiceRepo;
    late CreateInvoice createInvoice;
    late Client client;

    setUp(() async {
      clientRepo = InMemoryClientRepository();
      invoiceRepo = InMemoryInvoiceRepository();
      createInvoice = CreateInvoice(
        clientRepository: clientRepo,
        invoiceRepository: invoiceRepo,
      );

      client = Client.create(name: 'Test Client');
      await clientRepo.add(client);
    });

    test(
      'creates and persists draft invoice with lines and calculated total',
      () async {
        final line1 = InvoiceLine.create(
          description: 'Item 1',
          quantity: 2,
          unitPrice: Money.dzd(1000),
        );
        final line2 = InvoiceLine.create(
          description: 'Item 2',
          quantity: 1,
          unitPrice: Money.dzd(500),
          discount: Money.dzd(100),
        );

        final command = CreateInvoiceCommand(
          clientId: client.id,
          number: 'INV-2026-001',
          lines: [line1, line2],
          notes: 'Net 30 days',
        );

        final result = await createInvoice.execute(command);

        expect(result.isSuccess, isTrue);
        final invoice = result.dataOrNull!;
        expect(invoice.id, isA<InvoiceId>());
        expect(invoice.clientId, client.id);
        expect(invoice.number, 'INV-2026-001');
        expect(invoice.isDraft, isTrue);
        expect(invoice.total, equals(Money.dzd(2400)));
        expect(invoice.notes, 'Net 30 days');

        final saved = await invoiceRepo.getById(invoice.id);
        expect(saved, equals(invoice));
      },
    );

    test('supports custom caller-supplied typed InvoiceId', () async {
      final customId = InvoiceId.generate();
      final command = CreateInvoiceCommand(
        id: customId,
        clientId: client.id,
        number: 'INV-CUSTOM-ID',
      );

      final result = await createInvoice.execute(command);

      expect(result.isSuccess, isTrue);
      final invoice = result.dataOrNull!;
      expect(invoice.id, equals(customId));

      final saved = await invoiceRepo.getById(customId);
      expect(saved, equals(invoice));
    });

    test(
      'treats repeated creation with identical data as idempotent retry',
      () async {
        final suppliedId = InvoiceId.generate();
        final line = InvoiceLine.create(
          description: 'Consulting',
          quantity: 1,
          unitPrice: Money.dzd(5000),
        );
        final command = CreateInvoiceCommand(
          id: suppliedId,
          clientId: client.id,
          number: 'INV-RETRY-01',
          lines: [line],
          notes: 'Terms 15 days',
        );

        final firstResult = await createInvoice.execute(command);
        expect(firstResult.isSuccess, isTrue);

        // Replay identical request
        final retryResult = await createInvoice.execute(command);
        expect(retryResult.isSuccess, isTrue);
        expect(retryResult.dataOrNull!.id, equals(suppliedId));

        final all = await invoiceRepo.getAll();
        expect(all.length, equals(1));
      },
    );

    test(
      'returns ConflictFailure when supplied ID collides with differing data',
      () async {
        final suppliedId = InvoiceId.generate();
        final originalCommand = CreateInvoiceCommand(
          id: suppliedId,
          clientId: client.id,
          number: 'INV-ORIGINAL',
        );
        await createInvoice.execute(originalCommand);

        // Colliding request with different invoice number
        final collidingCommand = CreateInvoiceCommand(
          id: suppliedId,
          clientId: client.id,
          number: 'INV-DIFFERENT',
        );
        final result = await createInvoice.execute(collidingCommand);

        expect(result.isFailure, isTrue);
        expect(result.failureOrNull, isA<ConflictFailure>());
        expect(
          result.failureOrNull!.message,
          contains('already exists with differing data'),
        );
      },
    );

    test('creates empty draft invoice successfully', () async {
      final command = CreateInvoiceCommand(
        clientId: client.id,
        number: 'INV-EMPTY',
      );

      final result = await createInvoice.execute(command);

      expect(result.isSuccess, isTrue);
      final invoice = result.dataOrNull!;
      expect(invoice.lines, isEmpty);
      expect(invoice.total, equals(Money.zero(Currency.dzd)));
    });

    test('returns NotFoundFailure when client does not exist', () async {
      final missingClientId = ClientId.generate();
      final command = CreateInvoiceCommand(
        clientId: missingClientId,
        number: 'INV-001',
      );

      final result = await createInvoice.execute(command);

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<NotFoundFailure>());
      final nf = result.failureOrNull! as NotFoundFailure;
      expect(nf.entityType, 'Client');
      expect(nf.entityId, missingClientId);
      expect(await invoiceRepo.getAll(), isEmpty);
    });

    test(
      'returns ConflictFailure when invoice number already exists on different ID',
      () async {
        final existingInvoice = Invoice.draft(
          clientId: client.id,
          number: 'INV-DUPLICATE',
        );
        await invoiceRepo.add(existingInvoice);

        final command = CreateInvoiceCommand(
          clientId: client.id,
          number: '  INV-DUPLICATE  ',
        );

        final result = await createInvoice.execute(command);

        expect(result.isFailure, isTrue);
        expect(result.failureOrNull, isA<ConflictFailure>());
        expect(result.failureOrNull!.message, contains('INV-DUPLICATE'));
      },
    );

    test('returns ValidationFailure when line currencies mismatch', () async {
      final line1 = InvoiceLine.create(
        description: 'DZD Line',
        quantity: 1,
        unitPrice: Money.dzd(1000),
      );
      final eur = Currency(code: 'EUR');
      final line2 = InvoiceLine.create(
        description: 'EUR Line',
        quantity: 1,
        unitPrice: Money.fromSubunits(500, eur),
      );

      final command = CreateInvoiceCommand(
        clientId: client.id,
        number: 'INV-CURRENCY-MISMATCH',
        lines: [line1, line2],
      );

      final result = await createInvoice.execute(command);

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<ValidationFailure>());
    });
  });
}
