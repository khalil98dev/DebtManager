import 'package:application/application.dart';
import 'package:data/data.dart';
import 'package:domain/domain.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late DriftInvoiceRepository invoiceRepo;
  late DriftClientRepository clientRepo;

  // Helper client for tests
  final testClient = Client(
    id: ClientId.fromString('client-001'),
    name: 'Ahmed Benali',
    createdAt: DateTime.utc(2026, 1, 1, 10, 0),
    updatedAt: DateTime.utc(2026, 1, 1, 10, 0),
  );

  setUp(() async {
    db = AppDatabase.inMemory();
    invoiceRepo = DriftInvoiceRepository(db);
    clientRepo = DriftClientRepository(db);

    // Seed test client to satisfy foreign key constraints
    await clientRepo.add(testClient);
  });

  tearDown(() async {
    await db.close();
  });

  group('DriftInvoiceRepository - CRUD & Aggregates', () {
    test(
      'persists draft invoice with lines and retrieves exact aggregate',
      () async {
        final line1 = InvoiceLine(
          id: InvoiceLineId.fromString('line-1'),
          description: 'Hardware installation',
          quantity: 2,
          unitPrice: Money.fromSubunits(500000, Currency.dzd), // 5,000.00 DZD
          discount: Money.fromSubunits(50000, Currency.dzd), // 500.00 DZD
          createdAt: DateTime.utc(2026, 1, 15, 9, 30),
        );
        final line2 = InvoiceLine(
          id: InvoiceLineId.fromString('line-2'),
          description: 'Network configuration',
          quantity: 1,
          unitPrice: Money.fromSubunits(300000, Currency.dzd), // 3,000.00 DZD
          discount: Money.zero(Currency.dzd),
          createdAt: DateTime.utc(2026, 1, 15, 9, 35),
        );

        final invoice = Invoice.draft(
          id: InvoiceId.fromString('inv-001'),
          clientId: testClient.id,
          number: 'INV-2026-001',
          lines: [line1, line2],
          notes: 'Net 30 days',
          currency: Currency.dzd,
          createdAt: DateTime.utc(2026, 1, 15, 9, 0),
        );

        await invoiceRepo.add(invoice);

        final retrieved = await invoiceRepo.getById(invoice.id);
        expect(retrieved, isNotNull);
        expect(retrieved!.id, equals(invoice.id));
        expect(retrieved.clientId, equals(testClient.id));
        expect(retrieved.number, equals('INV-2026-001'));
        expect(retrieved.status, equals(InvoiceStatus.draft));
        expect(retrieved.isDraft, isTrue);
        expect(retrieved.isIssued, isFalse);
        expect(retrieved.issuedAt, isNull);
        expect(retrieved.notes, equals('Net 30 days'));
        expect(retrieved.currency, equals(Currency.dzd));
        expect(retrieved.createdAt, equals(DateTime.utc(2026, 1, 15, 9, 0)));

        // Verify lines
        expect(retrieved.lines.length, equals(2));
        final retLine1 = retrieved.lines[0];
        expect(retLine1.id, equals(line1.id));
        expect(retLine1.description, equals('Hardware installation'));
        expect(retLine1.quantity, equals(2));
        expect(
          retLine1.unitPrice,
          equals(Money.fromSubunits(500000, Currency.dzd)),
        );
        expect(
          retLine1.discount,
          equals(Money.fromSubunits(50000, Currency.dzd)),
        );
        expect(
          retLine1.grossTotal,
          equals(Money.fromSubunits(1000000, Currency.dzd)),
        );
        expect(
          retLine1.lineTotal,
          equals(Money.fromSubunits(950000, Currency.dzd)),
        );

        final retLine2 = retrieved.lines[1];
        expect(retLine2.id, equals(line2.id));
        expect(retLine2.description, equals('Network configuration'));
        expect(retLine2.quantity, equals(1));
        expect(
          retLine2.unitPrice,
          equals(Money.fromSubunits(300000, Currency.dzd)),
        );
        expect(retLine2.discount, equals(Money.zero(Currency.dzd)));
        expect(
          retLine2.lineTotal,
          equals(Money.fromSubunits(300000, Currency.dzd)),
        );

        // Verify calculated totals across aggregate
        expect(
          retrieved.grossTotal,
          equals(Money.fromSubunits(1300000, Currency.dzd)),
        );
        expect(
          retrieved.discountTotal,
          equals(Money.fromSubunits(50000, Currency.dzd)),
        );
        expect(
          retrieved.netTotal,
          equals(Money.fromSubunits(1250000, Currency.dzd)),
        );
        expect(
          retrieved.total,
          equals(Money.fromSubunits(1250000, Currency.dzd)),
        );
      },
    );

    test('persists empty draft invoice without lines', () async {
      final invoice = Invoice.draft(
        id: InvoiceId.fromString('inv-empty'),
        clientId: testClient.id,
        number: 'INV-EMPTY-001',
        lines: const [],
        currency: Currency.dzd,
        createdAt: DateTime.utc(2026, 2, 1, 10, 0),
      );

      await invoiceRepo.add(invoice);

      final retrieved = await invoiceRepo.getById(invoice.id);
      expect(retrieved, isNotNull);
      expect(retrieved!.lines, isEmpty);
      expect(retrieved.total, equals(Money.zero(Currency.dzd)));
    });

    test('getById returns null when invoice does not exist', () async {
      final result = await invoiceRepo.getById(
        InvoiceId.fromString('non-existent'),
      );
      expect(result, isNull);
    });

    test(
      'existsById returns true for existing and false for non-existing',
      () async {
        final invoice = Invoice.draft(
          id: InvoiceId.fromString('inv-exists'),
          clientId: testClient.id,
          number: 'INV-EXISTS',
          currency: Currency.dzd,
          createdAt: DateTime.utc(2026, 2, 1),
        );

        expect(await invoiceRepo.existsById(invoice.id), isFalse);
        await invoiceRepo.add(invoice);
        expect(await invoiceRepo.existsById(invoice.id), isTrue);
      },
    );

    test('getByNumber returns invoice matching number or null', () async {
      final invoice = Invoice.draft(
        id: InvoiceId.fromString('inv-by-num'),
        clientId: testClient.id,
        number: 'INV-NUM-42',
        currency: Currency.dzd,
        createdAt: DateTime.utc(2026, 2, 1),
      );
      await invoiceRepo.add(invoice);

      final found = await invoiceRepo.getByNumber('INV-NUM-42');
      expect(found, isNotNull);
      expect(found!.id, equals(invoice.id));

      final trimmed = await invoiceRepo.getByNumber('  INV-NUM-42  ');
      expect(trimmed, isNotNull);
      expect(trimmed!.id, equals(invoice.id));

      final notFound = await invoiceRepo.getByNumber('INV-UNKNOWN');
      expect(notFound, isNull);
    });

    test(
      'getAll returns all invoices ordered by createdAt descending with child lines',
      () async {
        final inv1 = Invoice.draft(
          id: InvoiceId.fromString('inv-1'),
          clientId: testClient.id,
          number: 'INV-001',
          lines: [
            InvoiceLine(
              id: InvoiceLineId.fromString('l-1'),
              description: 'Item 1',
              quantity: 1,
              unitPrice: Money.fromSubunits(100, Currency.dzd),
              createdAt: DateTime.utc(2026, 1, 1),
            ),
          ],
          createdAt: DateTime.utc(2026, 1, 1),
          currency: Currency.dzd,
        );

        final inv2 = Invoice.draft(
          id: InvoiceId.fromString('inv-2'),
          clientId: testClient.id,
          number: 'INV-002',
          lines: [
            InvoiceLine(
              id: InvoiceLineId.fromString('l-2'),
              description: 'Item 2',
              quantity: 2,
              unitPrice: Money.fromSubunits(200, Currency.dzd),
              createdAt: DateTime.utc(2026, 1, 2),
            ),
          ],
          createdAt: DateTime.utc(2026, 1, 2),
          currency: Currency.dzd,
        );

        await invoiceRepo.add(inv1);
        await invoiceRepo.add(inv2);

        final all = await invoiceRepo.getAll();
        expect(all.length, equals(2));
        expect(all[0].id, equals(inv2.id)); // Newer first
        expect(all[0].lines.length, equals(1));
        expect(all[0].lines[0].description, equals('Item 2'));
        expect(all[1].id, equals(inv1.id));
        expect(all[1].lines.length, equals(1));
        expect(all[1].lines[0].description, equals('Item 1'));
      },
    );

    test('getByClientId filters by client and optional status', () async {
      final client2 = Client(
        id: ClientId.fromString('client-002'),
        name: 'Fatima Zohra',
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1),
      );
      await clientRepo.add(client2);

      final draftLine = InvoiceLine(
        id: InvoiceLineId.fromString('dl-1'),
        description: 'Draft line',
        quantity: 1,
        unitPrice: Money.fromSubunits(100, Currency.dzd),
        createdAt: DateTime.utc(2026, 1, 1),
      );
      final issuedLine = InvoiceLine(
        id: InvoiceLineId.fromString('il-1'),
        description: 'Issued line',
        quantity: 1,
        unitPrice: Money.fromSubunits(200, Currency.dzd),
        createdAt: DateTime.utc(2026, 1, 1),
      );

      final invDraft = Invoice.draft(
        id: InvoiceId.fromString('c1-draft'),
        clientId: testClient.id,
        number: 'INV-C1-DRAFT',
        lines: [draftLine],
        createdAt: DateTime.utc(2026, 1, 1),
        currency: Currency.dzd,
      );

      final invIssued = Invoice.draft(
        id: InvoiceId.fromString('c1-issued'),
        clientId: testClient.id,
        number: 'INV-C1-ISSUED',
        lines: [issuedLine],
        createdAt: DateTime.utc(2026, 1, 2),
        currency: Currency.dzd,
      ).issue(issuedAt: DateTime.utc(2026, 1, 3));

      final c2Line = InvoiceLine(
        id: InvoiceLineId.fromString('dl-2'),
        description: 'Client 2 draft line',
        quantity: 1,
        unitPrice: Money.fromSubunits(100, Currency.dzd),
        createdAt: DateTime.utc(2026, 1, 1),
      );

      final invClient2 = Invoice.draft(
        id: InvoiceId.fromString('c2-draft'),
        clientId: client2.id,
        number: 'INV-C2-DRAFT',
        lines: [c2Line],
        createdAt: DateTime.utc(2026, 1, 4),
        currency: Currency.dzd,
      );

      await invoiceRepo.add(invDraft);
      await invoiceRepo.add(invIssued);
      await invoiceRepo.add(invClient2);

      // Filter by testClient only
      final client1Invoices = await invoiceRepo.getByClientId(testClient.id);
      expect(client1Invoices.length, equals(2));

      // Filter by testClient and draft status
      final client1Drafts = await invoiceRepo.getByClientId(
        testClient.id,
        status: InvoiceStatus.draft,
      );
      expect(client1Drafts.length, equals(1));
      expect(client1Drafts.first.id, equals(invDraft.id));

      // Filter by testClient and issued status
      final client1Issued = await invoiceRepo.getByClientId(
        testClient.id,
        status: InvoiceStatus.issued,
      );
      expect(client1Issued.length, equals(1));
      expect(client1Issued.first.id, equals(invIssued.id));
    });
  });

  group('DriftInvoiceRepository - Line Item Synchronization', () {
    test(
      'updates existing line, deletes removed line, and adds new line',
      () async {
        final line1 = InvoiceLine(
          id: InvoiceLineId.fromString('line-keep'),
          description: 'Original line',
          quantity: 1,
          unitPrice: Money.fromSubunits(1000, Currency.dzd),
          createdAt: DateTime.utc(2026, 1, 1),
        );
        final line2 = InvoiceLine(
          id: InvoiceLineId.fromString('line-remove'),
          description: 'To be removed',
          quantity: 2,
          unitPrice: Money.fromSubunits(500, Currency.dzd),
          createdAt: DateTime.utc(2026, 1, 1),
        );

        final initialInvoice = Invoice.draft(
          id: InvoiceId.fromString('inv-sync'),
          clientId: testClient.id,
          number: 'INV-SYNC-01',
          lines: [line1, line2],
          currency: Currency.dzd,
          createdAt: DateTime.utc(2026, 1, 1),
        );
        await invoiceRepo.add(initialInvoice);

        // Modified line1: quantity changed to 5, unit price to 1200
        final updatedLine1 = line1
            .changeQuantity(5)
            .changeUnitPrice(Money.fromSubunits(1200, Currency.dzd));

        // New line3
        final line3 = InvoiceLine(
          id: InvoiceLineId.fromString('line-new'),
          description: 'Brand new line',
          quantity: 3,
          unitPrice: Money.fromSubunits(800, Currency.dzd),
          createdAt: DateTime.utc(2026, 1, 2),
        );

        // Update invoice: remove line2, update line1, add line3
        final updatedInvoice = initialInvoice
            .removeLine(line2.id)
            .updateLine(updatedLine1)
            .addLine(line3);

        await invoiceRepo.add(updatedInvoice);

        final retrieved = await invoiceRepo.getById(initialInvoice.id);
        expect(retrieved, isNotNull);
        expect(retrieved!.lines.length, equals(2));

        // Check updated line1
        final rLine1 = retrieved.lines.firstWhere((l) => l.id == line1.id);
        expect(rLine1.quantity, equals(5));
        expect(
          rLine1.unitPrice,
          equals(Money.fromSubunits(1200, Currency.dzd)),
        );

        // Check new line3
        final rLine3 = retrieved.lines.firstWhere((l) => l.id == line3.id);
        expect(rLine3.description, equals('Brand new line'));
        expect(rLine3.quantity, equals(3));

        // Check line2 was deleted from SQLite
        expect(retrieved.lines.any((l) => l.id == line2.id), isFalse);
      },
    );
  });

  group('DriftInvoiceRepository - Lifecycle & Immutability Enforcement', () {
    test(
      'transitions draft to issued and persists issuedAt timestamp',
      () async {
        final line = InvoiceLine(
          id: InvoiceLineId.fromString('line-issuance'),
          description: 'Consulting',
          quantity: 10,
          unitPrice: Money.fromSubunits(10000, Currency.dzd),
          createdAt: DateTime.utc(2026, 1, 1),
        );
        final draft = Invoice.draft(
          id: InvoiceId.fromString('inv-to-issue'),
          clientId: testClient.id,
          number: 'INV-ISSUE-01',
          lines: [line],
          currency: Currency.dzd,
          createdAt: DateTime.utc(2026, 1, 1),
        );
        await invoiceRepo.add(draft);

        final issueTimestamp = DateTime.utc(2026, 1, 10, 15, 0);
        final issued = draft.issue(issuedAt: issueTimestamp);
        await invoiceRepo.add(issued);

        final retrieved = await invoiceRepo.getById(draft.id);
        expect(retrieved, isNotNull);
        expect(retrieved!.isIssued, isTrue);
        expect(retrieved.status, equals(InvoiceStatus.issued));
        expect(retrieved.issuedAt, equals(issueTimestamp));
      },
    );

    test(
      'throws StateError when attempting to modify an already issued invoice',
      () async {
        final line = InvoiceLine(
          id: InvoiceLineId.fromString('line-imm'),
          description: 'Audit service',
          quantity: 1,
          unitPrice: Money.fromSubunits(50000, Currency.dzd),
          createdAt: DateTime.utc(2026, 1, 1),
        );
        final draft = Invoice.draft(
          id: InvoiceId.fromString('inv-immutable'),
          clientId: testClient.id,
          number: 'INV-IMMUTABLE-01',
          lines: [line],
          currency: Currency.dzd,
          createdAt: DateTime.utc(2026, 1, 1),
        );
        await invoiceRepo.add(draft);

        final issued = draft.issue(issuedAt: DateTime.utc(2026, 1, 2));
        await invoiceRepo.add(issued);

        // Attempting to modify via repository add throws StateError
        expect(
          () => invoiceRepo.add(issued),
          throwsA(
            isA<StateError>().having(
              (e) => e.message,
              'message',
              contains('Cannot modify an invoice that has already been issued'),
            ),
          ),
        );
      },
    );

    test(
      'throws StateError when attempting to delete an issued invoice',
      () async {
        final line = InvoiceLine(
          id: InvoiceLineId.fromString('line-no-del'),
          description: 'Delivered goods',
          quantity: 1,
          unitPrice: Money.fromSubunits(20000, Currency.dzd),
          createdAt: DateTime.utc(2026, 1, 1),
        );
        final draft = Invoice.draft(
          id: InvoiceId.fromString('inv-no-del'),
          clientId: testClient.id,
          number: 'INV-NO-DEL-01',
          lines: [line],
          currency: Currency.dzd,
          createdAt: DateTime.utc(2026, 1, 1),
        );
        await invoiceRepo.add(draft);

        final issued = draft.issue(issuedAt: DateTime.utc(2026, 1, 2));
        await invoiceRepo.add(issued);

        // Deleting issued invoice must throw StateError
        expect(
          () => invoiceRepo.deleteById(issued.id),
          throwsA(
            isA<StateError>().having(
              (e) => e.message,
              'message',
              contains('Cannot delete an issued invoice'),
            ),
          ),
        );

        // Verify invoice is still present in database
        final stillExists = await invoiceRepo.getById(issued.id);
        expect(stillExists, isNotNull);
      },
    );

    test(
      'deleteById on draft invoice cascades and deletes child lines',
      () async {
        final line = InvoiceLine(
          id: InvoiceLineId.fromString('line-cascade-del'),
          description: 'Draft item',
          quantity: 1,
          unitPrice: Money.fromSubunits(100, Currency.dzd),
          createdAt: DateTime.utc(2026, 1, 1),
        );
        final draft = Invoice.draft(
          id: InvoiceId.fromString('inv-draft-del'),
          clientId: testClient.id,
          number: 'INV-DRAFT-DEL',
          lines: [line],
          currency: Currency.dzd,
          createdAt: DateTime.utc(2026, 1, 1),
        );
        await invoiceRepo.add(draft);

        // Delete draft invoice
        await invoiceRepo.deleteById(draft.id);

        // Invoice is deleted
        final retrieved = await invoiceRepo.getById(draft.id);
        expect(retrieved, isNull);

        // Lines are deleted by cascade in SQLite
        final linesInDb = await (db.select(
          db.invoiceLinesTable,
        )..where((t) => t.invoiceId.equals(draft.id.value))).get();
        expect(linesInDb, isEmpty);
      },
    );
  });

  group('DriftInvoiceRepository - Relational Integrity & Constraints', () {
    test(
      'rejects duplicate invoice numbers via SQLite unique constraint',
      () async {
        final inv1 = Invoice.draft(
          id: InvoiceId.fromString('inv-num-1'),
          clientId: testClient.id,
          number: 'INV-DUPLICATE',
          currency: Currency.dzd,
          createdAt: DateTime.utc(2026, 1, 1),
        );
        final inv2 = Invoice.draft(
          id: InvoiceId.fromString('inv-num-2'),
          clientId: testClient.id,
          number: 'INV-DUPLICATE', // duplicate number!
          currency: Currency.dzd,
          createdAt: DateTime.utc(2026, 1, 2),
        );

        await invoiceRepo.add(inv1);

        expect(() => invoiceRepo.add(inv2), throwsA(isA<SqliteException>()));
      },
    );

    test(
      'foreign key restrict prevents deleting client with existing invoices',
      () async {
        final invoice = Invoice.draft(
          id: InvoiceId.fromString('inv-fk-test'),
          clientId: testClient.id,
          number: 'INV-FK-01',
          currency: Currency.dzd,
          createdAt: DateTime.utc(2026, 1, 1),
        );
        await invoiceRepo.add(invoice);

        // Attempting to delete client must fail due to ON DELETE RESTRICT
        expect(
          () => clientRepo.deleteById(testClient.id),
          throwsA(isA<SqliteException>()),
        );
      },
    );

    test('rejects invoice referencing non-existent clientId', () async {
      final invalidInvoice = Invoice.draft(
        id: InvoiceId.fromString('inv-bad-client'),
        clientId: ClientId.fromString('non-existent-client'),
        number: 'INV-BAD-01',
        currency: Currency.dzd,
        createdAt: DateTime.utc(2026, 1, 1),
      );

      expect(
        () => invoiceRepo.add(invalidInvoice),
        throwsA(isA<SqliteException>()),
      );
    });
  });

  group('DriftInvoiceRepository + Application Layer Integration', () {
    test('CreateInvoice usecase persists draft invoice via Drift', () async {
      final createInvoice = CreateInvoice(
        clientRepository: clientRepo,
        invoiceRepository: invoiceRepo,
      );

      final line = InvoiceLine(
        id: InvoiceLineId.fromString('app-line-1'),
        description: 'Consulting package',
        quantity: 1,
        unitPrice: Money.fromSubunits(1500000, Currency.dzd),
        createdAt: DateTime.utc(2026, 1, 1),
      );

      final command = CreateInvoiceCommand(
        clientId: testClient.id,
        number: 'INV-APP-001',
        lines: [line],
        notes: 'Application usecase test',
        currency: Currency.dzd,
        createdAt: DateTime.utc(2026, 1, 20),
      );

      final result = await createInvoice.execute(command);
      expect(result.isSuccess, isTrue);

      final created = result.dataOrNull!;
      expect(created.number, equals('INV-APP-001'));

      final fromDb = await invoiceRepo.getById(created.id);
      expect(fromDb, isNotNull);
      expect(fromDb!.number, equals('INV-APP-001'));
      expect(fromDb.lines.length, equals(1));
      expect(fromDb.total, equals(Money.fromSubunits(1500000, Currency.dzd)));
    });

    test(
      'IssueInvoice usecase transitions draft invoice to issued in SQLite',
      () async {
        final createInvoice = CreateInvoice(
          clientRepository: clientRepo,
          invoiceRepository: invoiceRepo,
        );
        final issueInvoice = IssueInvoice(invoiceRepo);

        final line = InvoiceLine(
          id: InvoiceLineId.fromString('issue-line-1'),
          description: 'Delivered equipment',
          quantity: 2,
          unitPrice: Money.fromSubunits(50000, Currency.dzd),
          createdAt: DateTime.utc(2026, 1, 1),
        );

        final createResult = await createInvoice.execute(
          CreateInvoiceCommand(
            clientId: testClient.id,
            number: 'INV-TO-BE-ISSUED',
            lines: [line],
            currency: Currency.dzd,
            createdAt: DateTime.utc(2026, 1, 10),
          ),
        );
        expect(createResult.isSuccess, isTrue);
        final invoice = createResult.dataOrNull!;

        final issueTimestamp = DateTime.utc(2026, 1, 12, 14, 0);
        final issueResult = await issueInvoice.execute(
          IssueInvoiceCommand(invoiceId: invoice.id, issuedAt: issueTimestamp),
        );

        expect(issueResult.isSuccess, isTrue);
        final issued = issueResult.dataOrNull!;
        expect(issued.isIssued, isTrue);
        expect(issued.issuedAt, equals(issueTimestamp));

        final fromDb = await invoiceRepo.getById(invoice.id);
        expect(fromDb!.isIssued, isTrue);
        expect(fromDb.status, equals(InvoiceStatus.issued));
        expect(fromDb.issuedAt, equals(issueTimestamp));
      },
    );

    test('GetInvoiceById query handler retrieves persisted invoice', () async {
      final line = InvoiceLine(
        id: InvoiceLineId.fromString('query-line-1'),
        description: 'Development hours',
        quantity: 40,
        unitPrice: Money.fromSubunits(10000, Currency.dzd),
        createdAt: DateTime.utc(2026, 1, 1),
      );
      final invoice = Invoice.draft(
        id: InvoiceId.fromString('inv-query-test'),
        clientId: testClient.id,
        number: 'INV-QUERY-01',
        lines: [line],
        currency: Currency.dzd,
        createdAt: DateTime.utc(2026, 1, 15),
      );
      await invoiceRepo.add(invoice);

      final getInvoiceById = GetInvoiceById(invoiceRepo);
      final result = await getInvoiceById.execute(
        GetInvoiceByIdQuery(invoice.id),
      );

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull!.id, equals(invoice.id));
      expect(
        result.dataOrNull!.total,
        equals(Money.fromSubunits(400000, Currency.dzd)),
      );

      final notFoundResult = await getInvoiceById.execute(
        GetInvoiceByIdQuery(InvoiceId.fromString('non-existent')),
      );
      expect(notFoundResult.isFailure, isTrue);
      expect(notFoundResult.failureOrNull, isA<NotFoundFailure>());
    });
  });
}
