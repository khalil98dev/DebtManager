import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final fixedClientId = ClientId('client-001');
  final fixedInvoiceId = InvoiceId('inv-001');
  final fixedCreatedAt = DateTime.utc(2026, 1, 1, 10, 0, 0);
  final usdCurrency = Currency(code: 'USD', decimalDigits: 2, symbol: '\$');

  InvoiceLine createTestLine({
    String id = 'line-1',
    String description = 'Test Item',
    int quantity = 1,
    Money? unitPrice,
    Money? discount,
  }) {
    return InvoiceLine(
      id: InvoiceLineId(id),
      description: description,
      quantity: quantity,
      unitPrice: unitPrice ?? Money.dzd(100, 0),
      discount: discount,
      createdAt: fixedCreatedAt,
    );
  }

  group('Invoice - Draft Construction and Normalization', () {
    test(
      'constructs valid draft with explicit parameters and trims number and notes',
      () {
        final line1 = createTestLine(id: 'l-1', unitPrice: Money.dzd(50, 0));
        final line2 = createTestLine(id: 'l-2', unitPrice: Money.dzd(150, 0));

        final invoice = Invoice(
          id: fixedInvoiceId,
          clientId: fixedClientId,
          number: '   INV-2026-001   ',
          lines: [line1, line2],
          createdAt: fixedCreatedAt,
          status: InvoiceStatus.draft,
          notes: '   Payment due on receipt   ',
        );

        expect(invoice.id, equals(fixedInvoiceId));
        expect(invoice.clientId, equals(fixedClientId));
        expect(invoice.number, equals('INV-2026-001'));
        expect(invoice.status, equals(InvoiceStatus.draft));
        expect(invoice.isDraft, isTrue);
        expect(invoice.isIssued, isFalse);
        expect(invoice.issuedAt, isNull);
        expect(invoice.createdAt, equals(fixedCreatedAt));
        expect(invoice.notes, equals('Payment due on receipt'));
        expect(invoice.lines, equals([line1, line2]));
        expect(invoice.lineCount, equals(2));
        expect(invoice.grossTotal, equals(Money.dzd(200, 0)));
        expect(invoice.netTotal, equals(Money.dzd(200, 0)));
        expect(invoice.total, equals(invoice.netTotal));
      },
    );

    test('normalizes empty and whitespace-only notes to null', () {
      final invNull = Invoice.draft(
        clientId: fixedClientId,
        number: 'INV-1',
        notes: null,
      );
      expect(invNull.notes, isNull);

      final invBlank = Invoice.draft(
        clientId: fixedClientId,
        number: 'INV-2',
        notes: '   \t\n  ',
      );
      expect(invBlank.notes, isNull);
    });

    test(
      'rejects empty or whitespace-only invoice number with ArgumentError',
      () {
        expect(
          () => Invoice.draft(clientId: fixedClientId, number: ''),
          throwsArgumentError,
        );

        expect(
          () => Invoice.draft(clientId: fixedClientId, number: '   \t\n '),
          throwsArgumentError,
        );
      },
    );

    test('draft factory automatically generates ID and sets timestamp', () {
      final draft = Invoice.draft(clientId: fixedClientId, number: 'INV-AUTO');

      expect(draft.id.value, isNotEmpty);
      expect(draft.createdAt, isNotNull);
      expect(draft.status, equals(InvoiceStatus.draft));
      expect(draft.issuedAt, isNull);
    });
  });

  group('Invoice - Empty Drafts', () {
    test('supports empty drafts with zero lines and zero totals', () {
      final draft = Invoice.draft(clientId: fixedClientId, number: 'INV-EMPTY');

      expect(draft.lines, isEmpty);
      expect(draft.lineCount, equals(0));
      expect(draft.currency, equals(Currency.dzd));
      expect(draft.grossTotal, equals(Money.zero(Currency.dzd)));
      expect(draft.discountTotal, equals(Money.zero(Currency.dzd)));
      expect(draft.netTotal, equals(Money.zero(Currency.dzd)));
      expect(draft.total, equals(Money.zero(Currency.dzd)));
    });

    test('adding line to empty draft adopts the currency of that line', () {
      final draft = Invoice.draft(clientId: fixedClientId, number: 'INV-EMPTY');

      final usdLine = InvoiceLine(
        id: InvoiceLineId('usd-1'),
        description: 'USD Service',
        quantity: 2,
        unitPrice: Money.fromSubunits(500, usdCurrency),
        createdAt: fixedCreatedAt,
      );

      final updated = draft.addLine(usdLine);
      expect(updated.currency, equals(usdCurrency));
      expect(updated.lineCount, equals(1));
      expect(updated.total, equals(Money.fromSubunits(1000, usdCurrency)));
    });
  });

  group('Invoice - Issuing and Lifecycle Rules', () {
    test('cannot issue an invoice with zero lines', () {
      final draft = Invoice.draft(clientId: fixedClientId, number: 'INV-EMPTY');

      expect(() => draft.issue(), throwsStateError);
    });

    test('successfully issues a draft invoice with lines', () {
      final line = createTestLine(id: 'l-1', unitPrice: Money.dzd(150, 0));
      final draft = Invoice.draft(
        id: fixedInvoiceId,
        clientId: fixedClientId,
        number: 'INV-001',
        lines: [line],
        createdAt: fixedCreatedAt,
        notes: 'Test notes',
      );

      final issueTime = fixedCreatedAt.add(const Duration(hours: 2));
      final issued = draft.issue(issuedAt: issueTime);

      expect(issued.status, equals(InvoiceStatus.issued));
      expect(issued.isIssued, isTrue);
      expect(issued.isDraft, isFalse);
      expect(issued.issuedAt, equals(issueTime));

      // Preserves all identity and metadata
      expect(issued.id, equals(fixedInvoiceId));
      expect(issued.clientId, equals(fixedClientId));
      expect(issued.number, equals('INV-001'));
      expect(issued.createdAt, equals(fixedCreatedAt));
      expect(issued.notes, equals('Test notes'));
      expect(issued.lines, equals([line]));
      expect(issued.total, equals(Money.dzd(150, 0)));

      // Original draft remains unchanged
      expect(draft.isDraft, isTrue);
      expect(draft.issuedAt, isNull);
    });

    test('rejects issuing an already issued invoice', () {
      final line = createTestLine();
      final draft = Invoice.draft(
        clientId: fixedClientId,
        number: 'INV-001',
        lines: [line],
        createdAt: fixedCreatedAt,
      );

      final issued = draft.issue();
      expect(() => issued.issue(), throwsStateError);
    });

    test('rejects issuedAt before createdAt with ArgumentError', () {
      final line = createTestLine();
      final draft = Invoice.draft(
        clientId: fixedClientId,
        number: 'INV-001',
        lines: [line],
        createdAt: fixedCreatedAt,
      );

      final invalidTime = fixedCreatedAt.subtract(const Duration(seconds: 1));
      expect(() => draft.issue(issuedAt: invalidTime), throwsArgumentError);
    });

    test('rejects direct construction of draft with non-null issuedAt', () {
      expect(
        () => Invoice(
          id: fixedInvoiceId,
          clientId: fixedClientId,
          number: 'INV-001',
          createdAt: fixedCreatedAt,
          status: InvoiceStatus.draft,
          issuedAt: fixedCreatedAt,
        ),
        throwsArgumentError,
      );
    });

    test(
      'rejects direct construction of issued invoice with null issuedAt',
      () {
        final line = createTestLine();
        expect(
          () => Invoice(
            id: fixedInvoiceId,
            clientId: fixedClientId,
            number: 'INV-001',
            lines: [line],
            createdAt: fixedCreatedAt,
            status: InvoiceStatus.issued,
            issuedAt: null,
          ),
          throwsArgumentError,
        );
      },
    );

    test('rejects direct construction of issued invoice with zero lines', () {
      expect(
        () => Invoice(
          id: fixedInvoiceId,
          clientId: fixedClientId,
          number: 'INV-001',
          lines: const [],
          createdAt: fixedCreatedAt,
          status: InvoiceStatus.issued,
          issuedAt: fixedCreatedAt,
        ),
        throwsArgumentError,
      );
    });

    test('rejects mutations on issued invoices with StateError', () {
      final line1 = createTestLine(id: 'l-1');
      final line2 = createTestLine(id: 'l-2');
      final issued = Invoice.draft(
        clientId: fixedClientId,
        number: 'INV-001',
        lines: [line1],
        createdAt: fixedCreatedAt,
      ).issue();

      expect(() => issued.addLine(line2), throwsStateError);
      expect(() => issued.updateLine(line1), throwsStateError);
      expect(() => issued.removeLine(line1.id), throwsStateError);
      expect(() => issued.updateNotes('New notes'), throwsStateError);
      expect(() => issued.updateNumber('INV-NEW'), throwsStateError);
      expect(() => issued.changeClient(ClientId('client-2')), throwsStateError);
    });
  });

  group('Invoice - Immutable Line Collection Operations', () {
    late Invoice draft;
    late InvoiceLine line1;
    late InvoiceLine line2;

    setUp(() {
      line1 = createTestLine(id: 'l-1', unitPrice: Money.dzd(100), quantity: 1);
      line2 = createTestLine(id: 'l-2', unitPrice: Money.dzd(50), quantity: 2);
      draft = Invoice.draft(
        id: fixedInvoiceId,
        clientId: fixedClientId,
        number: 'INV-001',
        lines: [line1, line2],
        createdAt: fixedCreatedAt,
      );
    });

    test('lines list is unmodifiable from outside the aggregate', () {
      expect(
        () => draft.lines.add(createTestLine(id: 'l-3')),
        throwsUnsupportedError,
      );
      expect(() => draft.lines.clear(), throwsUnsupportedError);
    });

    test('external list modification does not affect invoice lines', () {
      final externalList = [line1, line2];
      final inv = Invoice.draft(
        clientId: fixedClientId,
        number: 'INV-EXT',
        lines: externalList,
      );

      externalList.clear();
      expect(inv.lines, hasLength(2));
    });

    test(
      'addLine appends line, recalculates totals, and preserves identity',
      () {
        final line3 = createTestLine(
          id: 'l-3',
          unitPrice: Money.dzd(200),
          quantity: 1,
        );
        final updated = draft.addLine(line3);

        expect(updated.lineCount, equals(3));
        expect(updated.lines[2], equals(line3));
        expect(updated.id, equals(fixedInvoiceId));
        expect(updated.createdAt, equals(fixedCreatedAt));
        expect(updated.total, equals(Money.dzd(400)));

        // Original draft remains unchanged
        expect(draft.lineCount, equals(2));
        expect(draft.total, equals(Money.dzd(200)));
      },
    );

    test('addLine rejects duplicate line ID with ArgumentError', () {
      final duplicate = createTestLine(id: 'l-1');
      expect(() => draft.addLine(duplicate), throwsArgumentError);
    });

    test(
      'updateLine replaces existing line matching ID and recalculates totals',
      () {
        final updatedLine2 = line2.updateQuantity(
          4,
        ); // gross becomes 200 instead of 100
        final updated = draft.updateLine(updatedLine2);

        expect(updated.lineCount, equals(2));
        expect(updated.lines[1].quantity, equals(4));
        expect(updated.total, equals(Money.dzd(300))); // 100 + 200

        // Original unchanged
        expect(draft.lines[1].quantity, equals(2));
        expect(draft.total, equals(Money.dzd(200)));
      },
    );

    test('updateLine rejects non-existent line ID with ArgumentError', () {
      final nonExistent = createTestLine(id: 'l-999');
      expect(() => draft.updateLine(nonExistent), throwsArgumentError);
    });

    test('removeLine removes line by ID and recalculates totals', () {
      final updated = draft.removeLine(line1.id);

      expect(updated.lineCount, equals(1));
      expect(updated.lines.first.id, equals(line2.id));
      expect(updated.total, equals(Money.dzd(100)));

      // Original unchanged
      expect(draft.lineCount, equals(2));
      expect(draft.total, equals(Money.dzd(200)));
    });

    test('removeLine rejects non-existent line ID with ArgumentError', () {
      expect(
        () => draft.removeLine(InvoiceLineId('l-999')),
        throwsArgumentError,
      );
    });
  });

  group('Invoice - Total Calculations', () {
    test(
      'calculates grossTotal, discountTotal, and netTotal correctly across multiple lines',
      () {
        final line1 = createTestLine(
          id: 'l-1',
          quantity: 3,
          unitPrice: Money.dzd(100, 50), // gross: 301.50
          discount: Money.dzd(20, 0), // discount: 20.00
        );
        final line2 = createTestLine(
          id: 'l-2',
          quantity: 2,
          unitPrice: Money.dzd(200, 0), // gross: 400.00
          discount: Money.dzd(50, 50), // discount: 50.50
        );

        final invoice = Invoice.draft(
          clientId: fixedClientId,
          number: 'INV-TOTALS',
          lines: [line1, line2],
        );

        expect(invoice.grossTotal, equals(Money.dzd(701, 50)));
        expect(invoice.discountTotal, equals(Money.dzd(70, 50)));
        expect(invoice.netTotal, equals(Money.dzd(631, 0)));
        expect(invoice.total, equals(invoice.netTotal));
      },
    );
  });

  group('Invoice - Mixed Currency Rejection', () {
    test('rejects construction with mixed currency lines', () {
      final dzdLine = createTestLine(id: 'dzd-1', unitPrice: Money.dzd(100));
      final usdLine = InvoiceLine(
        id: InvoiceLineId('usd-1'),
        description: 'USD item',
        quantity: 1,
        unitPrice: Money.fromSubunits(100, usdCurrency),
        createdAt: fixedCreatedAt,
      );

      expect(
        () => Invoice.draft(
          clientId: fixedClientId,
          number: 'INV-MIXED',
          lines: [dzdLine, usdLine],
        ),
        throwsA(isA<CurrencyMismatchException>()),
      );
    });

    test('rejects addLine with currency different from invoice currency', () {
      final dzdLine = createTestLine(id: 'dzd-1', unitPrice: Money.dzd(100));
      final invoice = Invoice.draft(
        clientId: fixedClientId,
        number: 'INV-DZD',
        lines: [dzdLine],
      );

      final usdLine = InvoiceLine(
        id: InvoiceLineId('usd-1'),
        description: 'USD item',
        quantity: 1,
        unitPrice: Money.fromSubunits(100, usdCurrency),
        createdAt: fixedCreatedAt,
      );

      expect(
        () => invoice.addLine(usdLine),
        throwsA(isA<CurrencyMismatchException>()),
      );
    });

    test(
      'rejects updateLine with currency different from invoice currency',
      () {
        final dzdLine = createTestLine(id: 'dzd-1', unitPrice: Money.dzd(100));
        final invoice = Invoice.draft(
          clientId: fixedClientId,
          number: 'INV-DZD',
          lines: [dzdLine],
        );

        final modifiedLineWithUsd = InvoiceLine(
          id: dzdLine.id,
          description: 'Updated item',
          quantity: 1,
          unitPrice: Money.fromSubunits(100, usdCurrency),
          createdAt: fixedCreatedAt,
        );

        expect(
          () => invoice.updateLine(modifiedLineWithUsd),
          throwsA(isA<CurrencyMismatchException>()),
        );
      },
    );
  });

  group('Invoice - Metadata Updates', () {
    late Invoice draft;

    setUp(() {
      draft = Invoice.draft(
        id: fixedInvoiceId,
        clientId: fixedClientId,
        number: 'INV-ORIGINAL',
        createdAt: fixedCreatedAt,
        notes: 'Original notes',
      );
    });

    test('updateNotes updates notes and preserves identity', () {
      final updated = draft.updateNotes('   Updated notes   ');
      expect(updated.notes, equals('Updated notes'));
      expect(updated.id, equals(fixedInvoiceId));
      expect(updated.createdAt, equals(fixedCreatedAt));

      final cleared = updated.changeNotes(null);
      expect(cleared.notes, isNull);
    });

    test('updateNumber updates number and preserves identity', () {
      final updated = draft.updateNumber('   INV-UPDATED   ');
      expect(updated.number, equals('INV-UPDATED'));
      expect(updated.id, equals(fixedInvoiceId));
      expect(updated.createdAt, equals(fixedCreatedAt));

      expect(() => draft.updateNumber('   '), throwsArgumentError);
    });

    test('changeClient reassigns client and preserves identity', () {
      final newClient = ClientId('client-999');
      final updated = draft.changeClient(newClient);
      expect(updated.clientId, equals(newClient));
      expect(updated.id, equals(fixedInvoiceId));
      expect(updated.createdAt, equals(fixedCreatedAt));
    });
  });

  group('Invoice - Entity Equality, HashCode, and String Representation', () {
    test(
      'two invoices with identical id are equal even with different fields',
      () {
        final inv1 = Invoice.draft(
          id: fixedInvoiceId,
          clientId: fixedClientId,
          number: 'INV-1',
          createdAt: fixedCreatedAt,
        );

        final inv2 = Invoice.draft(
          id: fixedInvoiceId,
          clientId: ClientId('client-different'),
          number: 'INV-2',
          createdAt: fixedCreatedAt.add(const Duration(days: 5)),
        );

        expect(inv1, equals(inv2));
        expect(inv1.hashCode, equals(inv2.hashCode));
      },
    );

    test('two invoices with different ids are not equal', () {
      final inv1 = Invoice.draft(
        id: InvoiceId('inv-1'),
        clientId: fixedClientId,
        number: 'INV-SAME',
        createdAt: fixedCreatedAt,
      );

      final inv2 = Invoice.draft(
        id: InvoiceId('inv-2'),
        clientId: fixedClientId,
        number: 'INV-SAME',
        createdAt: fixedCreatedAt,
      );

      expect(inv1, isNot(equals(inv2)));
    });

    test(
      'toString includes id, clientId, number, status, lineCount, and total',
      () {
        final invoice = Invoice.draft(
          id: fixedInvoiceId,
          clientId: fixedClientId,
          number: 'INV-2026-001',
          lines: [createTestLine(unitPrice: Money.dzd(100))],
        );

        final str = invoice.toString();
        expect(str, contains('inv-001'));
        expect(str, contains('client-001'));
        expect(str, contains('INV-2026-001'));
        expect(str, contains('draft'));
        expect(str, contains('100.00 DZD'));
      },
    );
  });

  group('Invoice - Iterable Materialization & Custom Iterables', () {
    test(
      'materializes single-use iterable exactly once during constructor execution',
      () {
        final line1 = createTestLine(id: 'l-1', unitPrice: Money.dzd(100));
        final line2 = createTestLine(id: 'l-2', unitPrice: Money.dzd(50));
        final singleUse = _SingleUseIterable([line1, line2]);

        // If materialization was not done exactly once, this would throw StateError.
        final invoice = Invoice(
          id: fixedInvoiceId,
          clientId: fixedClientId,
          number: 'INV-SINGLE-USE',
          lines: singleUse,
          createdAt: fixedCreatedAt,
        );

        expect(invoice.lines, hasLength(2));
        expect(invoice.grossTotal, equals(Money.dzd(150)));
        expect(invoice.currency, equals(Currency.dzd));
      },
    );

    test(
      'materializes single-use iterable in Invoice.draft factory exactly once',
      () {
        final line1 = createTestLine(id: 'l-1', unitPrice: Money.dzd(200));
        final singleUse = _SingleUseIterable([line1]);

        final invoice = Invoice.draft(
          clientId: fixedClientId,
          number: 'INV-DRAFT-SINGLE-USE',
          lines: singleUse,
        );

        expect(invoice.lines, hasLength(1));
        expect(invoice.total, equals(Money.dzd(200)));
      },
    );

    test('rejects construction with duplicate line IDs in lines iterable', () {
      final line1 = createTestLine(id: 'l-dup', unitPrice: Money.dzd(50));
      final line2 = createTestLine(id: 'l-dup', unitPrice: Money.dzd(75));

      expect(
        () => Invoice.draft(
          clientId: fixedClientId,
          number: 'INV-DUPLICATE-LINES',
          lines: [line1, line2],
        ),
        throwsArgumentError,
      );
    });
  });

  group('Invoice - Persisted Issued Invoice Reconstruction', () {
    test('safely reconstructs persisted issued invoice with valid fields', () {
      final line = createTestLine(id: 'l-1', unitPrice: Money.dzd(300));
      final issueTime = fixedCreatedAt.add(const Duration(days: 1));

      final persistedInvoice = Invoice(
        id: fixedInvoiceId,
        clientId: fixedClientId,
        number: 'INV-PERSISTED',
        lines: [line],
        createdAt: fixedCreatedAt,
        issuedAt: issueTime,
        status: InvoiceStatus.issued,
        notes: 'Archived notes',
      );

      expect(persistedInvoice.id, equals(fixedInvoiceId));
      expect(persistedInvoice.status, equals(InvoiceStatus.issued));
      expect(persistedInvoice.isIssued, isTrue);
      expect(persistedInvoice.issuedAt, equals(issueTime));
      expect(persistedInvoice.lines, hasLength(1));
      expect(persistedInvoice.total, equals(Money.dzd(300)));
      expect(persistedInvoice.notes, equals('Archived notes'));
    });

    test(
      'reconstructed issued invoice rejects all domain modification operations',
      () {
        final line1 = createTestLine(id: 'l-1', unitPrice: Money.dzd(300));
        final line2 = createTestLine(id: 'l-2', unitPrice: Money.dzd(100));
        final issueTime = fixedCreatedAt.add(const Duration(days: 1));

        final persistedInvoice = Invoice(
          id: fixedInvoiceId,
          clientId: fixedClientId,
          number: 'INV-PERSISTED',
          lines: [line1],
          createdAt: fixedCreatedAt,
          issuedAt: issueTime,
          status: InvoiceStatus.issued,
        );

        expect(() => persistedInvoice.addLine(line2), throwsStateError);
        expect(() => persistedInvoice.updateLine(line1), throwsStateError);
        expect(() => persistedInvoice.removeLine(line1.id), throwsStateError);
        expect(() => persistedInvoice.issue(), throwsStateError);
        expect(
          () => persistedInvoice.updateNotes('New notes'),
          throwsStateError,
        );
        expect(
          () => persistedInvoice.updateNumber('INV-NEW'),
          throwsStateError,
        );
        expect(
          () => persistedInvoice.changeClient(ClientId('client-2')),
          throwsStateError,
        );
      },
    );
  });
}

/// A test-only iterable that enforces being traversed at most once.
class _SingleUseIterable<T> extends Iterable<T> {
  _SingleUseIterable(this._items);
  final List<T> _items;
  bool _iterated = false;

  @override
  Iterator<T> get iterator {
    if (_iterated) {
      throw StateError('This iterable can only be iterated once!');
    }
    _iterated = true;
    return _items.iterator;
  }
}
