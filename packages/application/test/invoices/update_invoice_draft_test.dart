import 'package:application/application.dart';
import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/in_memory_repositories.dart';

void main() {
  group('UpdateInvoiceDraft Command', () {
    late InMemoryClientRepository clientRepo;
    late InMemoryInvoiceRepository invoiceRepo;
    late UpdateInvoiceDraft updateInvoiceDraft;

    late Client client;
    late Invoice draftInvoice;

    setUp(() async {
      clientRepo = InMemoryClientRepository();
      invoiceRepo = InMemoryInvoiceRepository();
      updateInvoiceDraft = UpdateInvoiceDraft(
        clientRepository: clientRepo,
        invoiceRepository: invoiceRepo,
      );

      client = Client.create(name: 'Test Client');
      await clientRepo.add(client);

      draftInvoice = Invoice.draft(
        clientId: client.id,
        number: 'INV-001',
        lines: [
          InvoiceLine(
            id: InvoiceLineId.generate(),
            description: 'Item 1',
            quantity: 1,
            unitPrice: Money.fromSubunits(100000, Currency.dzd),
            createdAt: DateTime.now(),
          ),
        ],
      );
      await invoiceRepo.add(draftInvoice);
    });

    test('updates draft invoice lines and number successfully', () async {
      final newLine = InvoiceLine(
        id: InvoiceLineId.generate(),
        description: 'Updated Item',
        quantity: 2,
        unitPrice: Money.fromSubunits(200000, Currency.dzd),
        createdAt: DateTime.now(),
      );

      final result = await updateInvoiceDraft.execute(
        UpdateInvoiceDraftCommand(
          id: draftInvoice.id,
          clientId: client.id,
          number: 'INV-001-MOD',
          lines: [newLine],
          notes: 'Updated notes',
        ),
      );

      expect(result.isSuccess, isTrue);
      final updated = result.dataOrNull!;
      expect(updated.number, equals('INV-001-MOD'));
      expect(updated.lines.length, equals(1));
      expect(updated.lines.first.description, equals('Updated Item'));
      expect(updated.notes, equals('Updated notes'));
      expect(updated.total, equals(Money.fromSubunits(400000, Currency.dzd)));
    });

    test(
      'returns ConflictFailure when invoice has already been issued',
      () async {
        final issued = draftInvoice.issue(issuedAt: DateTime.now());
        await invoiceRepo.add(issued);

        final result = await updateInvoiceDraft.execute(
          UpdateInvoiceDraftCommand(
            id: draftInvoice.id,
            clientId: client.id,
            number: 'INV-NEW',
          ),
        );

        expect(result.isFailure, isTrue);
        expect(result.failureOrNull, isA<ConflictFailure>());
      },
    );

    test('returns NotFoundFailure when invoice does not exist', () async {
      final result = await updateInvoiceDraft.execute(
        UpdateInvoiceDraftCommand(
          id: InvoiceId.generate(),
          clientId: client.id,
          number: 'INV-NEW',
        ),
      );

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<NotFoundFailure>());
    });

    test(
      'returns ConflictFailure when updating to an existing duplicate number',
      () async {
        final secondInvoice = Invoice.draft(
          clientId: client.id,
          number: 'INV-002',
        );
        await invoiceRepo.add(secondInvoice);

        final result = await updateInvoiceDraft.execute(
          UpdateInvoiceDraftCommand(
            id: draftInvoice.id,
            clientId: client.id,
            number: 'INV-002',
          ),
        );

        expect(result.isFailure, isTrue);
        expect(result.failureOrNull, isA<ConflictFailure>());
      },
    );
  });
}
