import 'package:meta/meta.dart';

import '../clients/client_id.dart';
import '../common/validation_utils.dart';
import '../value_objects/money.dart';
import 'invoice_id.dart';
import 'invoice_line.dart';
import 'invoice_status.dart';

export 'invoice_id.dart';
export 'invoice_status.dart';

/// An immutable aggregate root representing a financial invoice within the domain.
///
/// Encapsulates invoice metadata, client relationship, lifecycle states, and an
/// unmodifiable collection of [InvoiceLine] items. All monetary totals are strictly
/// calculated from child lines using integer-based [Money] arithmetic.
@immutable
class Invoice {
  /// Internal generative constructor with pre-materialized and validated state.
  const Invoice._({
    required this.id,
    required this.clientId,
    required this.number,
    required this.lines,
    required this.createdAt,
    this.issuedAt,
    this.status = InvoiceStatus.draft,
    this.notes,
    required this.currency,
  });

  /// Creates an [Invoice] instance with strict invariant validation.
  ///
  /// - Materializes [lines] exactly once into an unmodifiable collection.
  /// - [clientId] links the invoice to a specific client.
  /// - [number] is trimmed and must not be empty.
  /// - All [lines] must share the same [currency].
  /// - If [status] is [InvoiceStatus.draft], [issuedAt] must be `null`.
  /// - If [status] is [InvoiceStatus.issued], [issuedAt] is required, cannot be
  ///   before [createdAt], and [lines] must contain at least one item.
  factory Invoice({
    required InvoiceId id,
    required ClientId clientId,
    required String number,
    Iterable<InvoiceLine> lines = const [],
    required DateTime createdAt,
    DateTime? issuedAt,
    InvoiceStatus status = InvoiceStatus.draft,
    String? notes,
    Currency? currency,
  }) {
    final materializedLines = List<InvoiceLine>.unmodifiable(lines);
    final resolvedCurrency = _resolveCurrency(materializedLines, currency);
    final validatedNumber = ValidationUtils.validateAndTrimNumber(number);
    final normalizedNotes = ValidationUtils.normalizeOptionalString(notes);

    _validateLifecycleAndLines(
      status: status,
      createdAt: createdAt,
      issuedAt: issuedAt,
      lines: materializedLines,
      currency: resolvedCurrency,
    );

    return Invoice._(
      id: id,
      clientId: clientId,
      number: validatedNumber,
      lines: materializedLines,
      createdAt: createdAt,
      issuedAt: issuedAt,
      status: status,
      notes: normalizedNotes,
      currency: resolvedCurrency,
    );
  }

  /// Creates a new draft [Invoice].
  ///
  /// Sets [status] to [InvoiceStatus.draft] and [issuedAt] to `null`.
  /// Automatically generates an offline-ready [InvoiceId] and sets [createdAt]
  /// to the current timestamp if not explicitly supplied.
  factory Invoice.draft({
    InvoiceId? id,
    required ClientId clientId,
    required String number,
    Iterable<InvoiceLine> lines = const [],
    DateTime? createdAt,
    String? notes,
    Currency? currency,
  }) {
    final now = createdAt ?? DateTime.now();
    return Invoice(
      id: id ?? InvoiceId.generate(),
      clientId: clientId,
      number: number,
      lines: lines,
      createdAt: now,
      status: InvoiceStatus.draft,
      notes: notes,
      currency: currency,
    );
  }

  /// Convenience alias for [Invoice.draft].
  factory Invoice.create({
    InvoiceId? id,
    required ClientId clientId,
    required String number,
    Iterable<InvoiceLine> lines = const [],
    DateTime? createdAt,
    String? notes,
    Currency? currency,
  }) => Invoice.draft(
    id: id,
    clientId: clientId,
    number: number,
    lines: lines,
    createdAt: createdAt,
    notes: notes,
    currency: currency,
  );

  /// Unique identifier of this invoice.
  final InvoiceId id;

  /// Identifier of the client this invoice is billed to.
  final ClientId clientId;

  /// Human-readable invoice number (e.g. `"INV-2026-001"`).
  final String number;

  /// Unmodifiable collection of itemized lines belonging to this invoice.
  final List<InvoiceLine> lines;

  /// Timestamp when this invoice aggregate was initially created.
  final DateTime createdAt;

  /// Timestamp when this invoice was finalized and issued, or `null` if draft.
  final DateTime? issuedAt;

  /// Current lifecycle status of this invoice.
  final InvoiceStatus status;

  /// Optional notes or payment terms.
  final String? notes;

  /// Monetary currency used by this invoice and all its lines.
  final Currency currency;

  /// Total gross amount before discounts across all invoice lines.
  ///
  /// Calculated strictly from child lines using [Money] addition.
  Money get grossTotal => lines.fold<Money>(
    Money.zero(currency),
    (sum, line) => sum + line.grossTotal,
  );

  /// Total discounts deducted across all invoice lines.
  ///
  /// Calculated strictly from child lines using [Money] addition.
  Money get discountTotal => lines.fold<Money>(
    Money.zero(currency),
    (sum, line) => sum + line.discount,
  );

  /// Net total amount payable after discounts: `grossTotal - discountTotal`.
  Money get netTotal => grossTotal - discountTotal;

  /// Alias for [netTotal].
  Money get total => netTotal;

  /// The number of line items currently in this invoice.
  int get lineCount => lines.length;

  /// Whether this invoice is in an editable draft state.
  bool get isDraft => status == InvoiceStatus.draft;

  /// Whether this invoice has been finalized and issued.
  bool get isIssued => status == InvoiceStatus.issued;

  /// Adds a new [newLine] to the invoice lines.
  ///
  /// Throws [StateError] if the invoice is not in a draft state.
  /// Throws [CurrencyMismatchException] if [newLine.currency] does not match [currency].
  /// Throws [ArgumentError] if a line with the same ID already exists in this invoice.
  Invoice addLine(InvoiceLine newLine) {
    _assertIsDraft('add line to');
    final targetCurrency = lines.isEmpty ? newLine.currency : currency;
    if (newLine.currency != targetCurrency) {
      throw CurrencyMismatchException(
        targetCurrency.code,
        newLine.currency.code,
      );
    }
    if (lines.any((l) => l.id == newLine.id)) {
      throw ArgumentError.value(
        newLine.id,
        'newLine',
        'Cannot add line: a line with ID ${newLine.id} already exists in this invoice.',
      );
    }
    return Invoice._(
      id: id,
      clientId: clientId,
      number: number,
      lines: List<InvoiceLine>.unmodifiable([...lines, newLine]),
      createdAt: createdAt,
      issuedAt: issuedAt,
      status: status,
      notes: notes,
      currency: targetCurrency,
    );
  }

  /// Updates an existing line in this invoice matching [updatedLine.id].
  ///
  /// Throws [StateError] if the invoice is not in a draft state.
  /// Throws [CurrencyMismatchException] if [updatedLine.currency] does not match [currency].
  /// Throws [ArgumentError] if no line with matching ID exists.
  Invoice updateLine(InvoiceLine updatedLine) {
    _assertIsDraft('update line in');
    if (updatedLine.currency != currency) {
      throw CurrencyMismatchException(currency.code, updatedLine.currency.code);
    }
    final index = lines.indexWhere((l) => l.id == updatedLine.id);
    if (index == -1) {
      throw ArgumentError.value(
        updatedLine.id,
        'updatedLine',
        'Cannot update line: no line with ID ${updatedLine.id} exists in this invoice.',
      );
    }
    final newLines = List<InvoiceLine>.unmodifiable(
      List<InvoiceLine>.of(lines)..[index] = updatedLine,
    );
    return Invoice._(
      id: id,
      clientId: clientId,
      number: number,
      lines: newLines,
      createdAt: createdAt,
      issuedAt: issuedAt,
      status: status,
      notes: notes,
      currency: currency,
    );
  }

  /// Removes the line matching [lineId] from this invoice.
  ///
  /// Throws [StateError] if the invoice is not in a draft state.
  /// Throws [ArgumentError] if no line with matching ID exists.
  Invoice removeLine(InvoiceLineId lineId) {
    _assertIsDraft('remove line from');
    final index = lines.indexWhere((l) => l.id == lineId);
    if (index == -1) {
      throw ArgumentError.value(
        lineId,
        'lineId',
        'Cannot remove line: no line with ID $lineId exists in this invoice.',
      );
    }
    final newLines = List<InvoiceLine>.unmodifiable(
      List<InvoiceLine>.of(lines)..removeAt(index),
    );
    return Invoice._(
      id: id,
      clientId: clientId,
      number: number,
      lines: newLines,
      createdAt: createdAt,
      issuedAt: issuedAt,
      status: status,
      notes: notes,
      currency: currency,
    );
  }

  /// Finalizes and issues this draft invoice.
  ///
  /// - Sets [status] to [InvoiceStatus.issued].
  /// - Sets [issuedAt] to [issuedAt] or [DateTime.now()].
  /// - Throws [StateError] if the invoice is not currently a draft.
  /// - Throws [StateError] if the invoice has no lines.
  /// - Throws [ArgumentError] if [issuedAt] is before [createdAt].
  Invoice issue({DateTime? issuedAt}) {
    if (status != InvoiceStatus.draft) {
      throw StateError(
        'Cannot issue an invoice with status ${status.name}. Only draft invoices can be issued.',
      );
    }
    if (lines.isEmpty) {
      throw StateError(
        'Cannot issue an invoice with no lines. At least one line is required.',
      );
    }
    final timestamp = issuedAt ?? DateTime.now();
    if (timestamp.isBefore(createdAt)) {
      throw ArgumentError.value(
        timestamp,
        'issuedAt',
        'issuedAt cannot be before createdAt.',
      );
    }
    return Invoice._(
      id: id,
      clientId: clientId,
      number: number,
      lines: lines,
      createdAt: createdAt,
      issuedAt: timestamp,
      status: InvoiceStatus.issued,
      notes: notes,
      currency: currency,
    );
  }

  /// Updates the optional notes for this draft invoice.
  ///
  /// Throws [StateError] if the invoice is not a draft.
  Invoice updateNotes(String? newNotes) {
    _assertIsDraft('update notes of');
    return Invoice._(
      id: id,
      clientId: clientId,
      number: number,
      lines: lines,
      createdAt: createdAt,
      issuedAt: issuedAt,
      status: status,
      notes: ValidationUtils.normalizeOptionalString(newNotes),
      currency: currency,
    );
  }

  /// Alias for [updateNotes].
  Invoice changeNotes(String? newNotes) => updateNotes(newNotes);

  /// Updates the human-readable number of this draft invoice.
  ///
  /// Throws [StateError] if the invoice is not a draft.
  /// Throws [ArgumentError] if [newNumber] is empty or whitespace only.
  Invoice updateNumber(String newNumber) {
    _assertIsDraft('update number of');
    final validatedNumber = ValidationUtils.validateAndTrimNumber(newNumber);
    return Invoice._(
      id: id,
      clientId: clientId,
      number: validatedNumber,
      lines: lines,
      createdAt: createdAt,
      issuedAt: issuedAt,
      status: status,
      notes: notes,
      currency: currency,
    );
  }

  /// Alias for [updateNumber].
  Invoice changeNumber(String newNumber) => updateNumber(newNumber);

  /// Reassigns this draft invoice to [newClientId].
  ///
  /// Throws [StateError] if the invoice is not a draft.
  Invoice changeClient(ClientId newClientId) {
    _assertIsDraft('change client of');
    return Invoice._(
      id: id,
      clientId: newClientId,
      number: number,
      lines: lines,
      createdAt: createdAt,
      issuedAt: issuedAt,
      status: status,
      notes: notes,
      currency: currency,
    );
  }

  /// Alias for [changeClient].
  Invoice updateClient(ClientId newClientId) => changeClient(newClientId);

  void _assertIsDraft(String action) {
    if (status != InvoiceStatus.draft) {
      throw StateError(
        'Cannot $action a non-draft invoice (current status: ${status.name}).',
      );
    }
  }

  static Currency _resolveCurrency(
    List<InvoiceLine> lines,
    Currency? explicitCurrency,
  ) {
    if (explicitCurrency != null) return explicitCurrency;
    if (lines.isNotEmpty) return lines.first.currency;
    return Currency.dzd;
  }

  static void _validateLifecycleAndLines({
    required InvoiceStatus status,
    required DateTime createdAt,
    required DateTime? issuedAt,
    required List<InvoiceLine> lines,
    required Currency currency,
  }) {
    switch (status) {
      case InvoiceStatus.draft:
        if (issuedAt != null) {
          throw ArgumentError.value(
            issuedAt,
            'issuedAt',
            'A draft invoice cannot have an issuedAt timestamp.',
          );
        }
      case InvoiceStatus.issued:
        if (issuedAt == null) {
          throw ArgumentError.value(
            issuedAt,
            'issuedAt',
            'An issued invoice must have an issuedAt timestamp.',
          );
        }
        if (issuedAt.isBefore(createdAt)) {
          throw ArgumentError.value(
            issuedAt,
            'issuedAt',
            'issuedAt cannot be before createdAt.',
          );
        }
        if (lines.isEmpty) {
          throw ArgumentError.value(
            lines,
            'lines',
            'An issued invoice must contain at least one line item.',
          );
        }
    }

    final seenIds = <InvoiceLineId>{};
    for (final line in lines) {
      if (!seenIds.add(line.id)) {
        throw ArgumentError.value(
          line.id,
          'lines',
          'Duplicate invoice line ID found in invoice: ${line.id}.',
        );
      }
      if (line.currency != currency) {
        throw CurrencyMismatchException(currency.code, line.currency.code);
      }
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Invoice && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Invoice(id: $id, clientId: $clientId, number: $number, '
      'status: ${status.name}, lines: ${lines.length}, total: $netTotal, '
      'createdAt: $createdAt, issuedAt: $issuedAt)';
}
