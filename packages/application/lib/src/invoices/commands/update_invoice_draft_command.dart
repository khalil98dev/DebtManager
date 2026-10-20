import 'package:domain/domain.dart';

/// Command to update an existing draft invoice's lines and metadata.
final class UpdateInvoiceDraftCommand {
  const UpdateInvoiceDraftCommand({
    required this.id,
    required this.clientId,
    required this.number,
    this.lines = const [],
    this.notes,
    this.currency,
  });

  final InvoiceId id;
  final ClientId clientId;
  final String number;
  final Iterable<InvoiceLine> lines;
  final String? notes;
  final Currency? currency;
}
