/// Query for retrieving an invoice by unique identifier.
library;

import 'package:domain/domain.dart';

/// Query input for looking up a single [Invoice] by its unique [InvoiceId].
final class GetInvoiceByIdQuery {
  const GetInvoiceByIdQuery(this.id);

  /// Unique invoice identifier to look up.
  final InvoiceId id;
}
