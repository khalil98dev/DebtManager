/// Query for retrieving a payment allocation by unique identifier.
library;

import 'package:domain/domain.dart';

/// Query input for looking up a single [PaymentAllocation] by its unique [PaymentAllocationId].
final class GetPaymentAllocationByIdQuery {
  const GetPaymentAllocationByIdQuery(this.id);

  /// Unique payment allocation identifier to look up.
  final PaymentAllocationId id;
}
