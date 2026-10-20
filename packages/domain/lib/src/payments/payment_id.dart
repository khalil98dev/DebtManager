import '../common/entity_id.dart';
import 'payment.dart';

/// Identifier for a [Payment] entity.
///
/// Aliases [EntityId<Payment>] to reuse centralized UUID generation,
/// validation, equality, hashing, and serialization.
typedef PaymentId = EntityId<Payment>;
