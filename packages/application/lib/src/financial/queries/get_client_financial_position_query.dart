/// Query for retrieving a client's financial position.
library;

import 'package:domain/domain.dart';

/// Query input for retrieving a client's computed financial position.
final class GetClientFinancialPositionQuery {
  const GetClientFinancialPositionQuery({
    required this.clientId,
    this.currency,
  });

  /// Client identifier whose position is being queried.
  final ClientId clientId;

  /// Expected currency for the financial calculation (optional).
  final Currency? currency;
}
