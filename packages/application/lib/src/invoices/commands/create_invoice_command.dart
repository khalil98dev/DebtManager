/// Create draft invoice command.
library;

import 'package:domain/domain.dart';

/// Command input for creating a new draft invoice.
///
/// Encapsulates all data required to request creation of an [Invoice] in draft state.
/// Supports optional pre-generated [id] for offline creation and synchronization.
final class CreateInvoiceCommand {
  const CreateInvoiceCommand({
    required this.clientId,
    required this.number,
    this.lines = const [],
    this.notes,
    this.currency,
    this.id,
    this.createdAt,
  });

  /// Client this invoice is billed to.
  final ClientId clientId;

  /// Human-readable invoice number.
  final String number;

  /// Itemized lines to include in the draft invoice (can be empty).
  final Iterable<InvoiceLine> lines;

  /// Optional notes or payment terms.
  final String? notes;

  /// Optional monetary currency (derived from lines if omitted).
  final Currency? currency;

  /// Optional pre-generated invoice identifier (for offline generation and sync).
  final InvoiceId? id;

  /// Optional creation timestamp.
  final DateTime? createdAt;
}
