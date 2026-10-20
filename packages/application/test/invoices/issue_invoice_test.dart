import 'package:application/application.dart';
import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/in_memory_repositories.dart';

void main() {
  group('IssueInvoice Command', () {
    late InMemoryInvoiceRepository invoiceRepo;
    late IssueInvoice issueInvoice;
    late ClientId clientId;

    setUp(() {
      invoiceRepo = InMemoryInvoiceRepository();
      issueInvoice = IssueInvoice(invoiceRepo);
      clientId = ClientId.generate();
    });

    test('issues a draft invoice with lines successfully', () async {
      final line = InvoiceLine.create(
        description: 'Delivered Product',
        quantity: 5,
        unitPrice: Money.dzd(2000),
      );
      final createdTime = DateTime.utc(2026, 1, 15, 10, 0);
      final draftInvoice = Invoice.draft(
        clientId: clientId,
        number: 'INV-2026-002',
        lines: [line],
        createdAt: createdTime,
      );
      await invoiceRepo.add(draftInvoice);

      final issueTime = DateTime.utc(2026, 2, 1, 14, 0);
      final result = await issueInvoice.execute(
        IssueInvoiceCommand(invoiceId: draftInvoice.id, issuedAt: issueTime),
      );

      expect(result.isSuccess, isTrue);
      final issued = result.dataOrNull!;
      expect(issued.isIssued, isTrue);
      expect(issued.status, InvoiceStatus.issued);
      expect(issued.issuedAt, issueTime);

      final saved = await invoiceRepo.getById(draftInvoice.id);
      expect(saved!.isIssued, isTrue);
    });

    test('returns NotFoundFailure when invoice does not exist', () async {
      final missingInvoiceId = InvoiceId.generate();
      final result = await issueInvoice.execute(
        IssueInvoiceCommand(invoiceId: missingInvoiceId),
      );

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<NotFoundFailure>());
      final nf = result.failureOrNull! as NotFoundFailure;
      expect(nf.entityType, 'Invoice');
      expect(nf.entityId, missingInvoiceId);
    });

    test('returns ConflictFailure when invoice is already issued', () async {
      final line = InvoiceLine.create(
        description: 'Consulting',
        quantity: 1,
        unitPrice: Money.dzd(10000),
      );
      final draft = Invoice.draft(
        clientId: clientId,
        number: 'INV-ALREADY-ISSUED',
        lines: [line],
      );
      final issued = draft.issue();
      await invoiceRepo.add(issued);

      final result = await issueInvoice.execute(
        IssueInvoiceCommand(invoiceId: issued.id),
      );

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<ConflictFailure>());
      expect(result.failureOrNull!.message, contains('already issued'));
    });

    test(
      'returns ValidationFailure when issuing an invoice with 0 lines',
      () async {
        final emptyDraft = Invoice.draft(
          clientId: clientId,
          number: 'INV-NO-LINES',
          lines: const [],
        );
        await invoiceRepo.add(emptyDraft);

        final result = await issueInvoice.execute(
          IssueInvoiceCommand(invoiceId: emptyDraft.id),
        );

        expect(result.isFailure, isTrue);
        expect(result.failureOrNull, isA<ValidationFailure>());
        expect(result.failureOrNull!.message, contains('no lines'));
      },
    );

    test(
      'returns ValidationFailure when issuedAt is before createdAt',
      () async {
        final line = InvoiceLine.create(
          description: 'Audit',
          quantity: 1,
          unitPrice: Money.dzd(5000),
        );
        final createdAt = DateTime.utc(2026, 3, 10, 12, 0);
        final draft = Invoice.draft(
          clientId: clientId,
          number: 'INV-TIMESTAMP',
          lines: [line],
          createdAt: createdAt,
        );
        await invoiceRepo.add(draft);

        final invalidIssuedAt = DateTime.utc(2026, 3, 9, 12, 0);
        final result = await issueInvoice.execute(
          IssueInvoiceCommand(invoiceId: draft.id, issuedAt: invalidIssuedAt),
        );

        expect(result.isFailure, isTrue);
        expect(result.failureOrNull, isA<ValidationFailure>());
      },
    );
  });
}
