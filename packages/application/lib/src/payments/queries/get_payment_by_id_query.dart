/// Query for retrieving a payment by unique identifier.
library;

import 'package:domain/domain.dart';

/// Query input for looking up a single [Payment] by its unique [PaymentId].
final class GetPaymentByIdQuery {
  const GetPaymentByIdQuery(this.id);

  /// Unique payment identifier to look up.
  final PaymentId id;
}
