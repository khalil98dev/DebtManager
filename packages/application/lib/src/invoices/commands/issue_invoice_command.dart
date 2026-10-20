/// Issue invoice command.
library;

import 'package:domain/domain.dart';

/// Command input for finalizing and issuing a draft invoice.
final class IssueInvoiceCommand {
  const IssueInvoiceCommand({required this.invoiceId, this.issuedAt});

  /// Unique identifier of the invoice to issue.
  final InvoiceId invoiceId;

  /// Optional issue timestamp (defaults to current time if omitted).
  final DateTime? issuedAt;
}
