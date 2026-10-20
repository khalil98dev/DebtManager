import '../common/entity_id.dart';
import 'payment_allocation.dart';

/// Identifier for a [PaymentAllocation] entity.
///
/// Aliases [EntityId<PaymentAllocation>] to reuse centralized UUID generation,
/// validation, equality, hashing, and serialization.
typedef PaymentAllocationId = EntityId<PaymentAllocation>;
