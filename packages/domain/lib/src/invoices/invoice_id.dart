import '../common/entity_id.dart';
import 'invoice.dart';

/// Identifier for an [Invoice] entity.
///
/// Aliases [EntityId<Invoice>] to reuse centralized UUID generation,
/// validation, equality, hashing, and serialization.
typedef InvoiceId = EntityId<Invoice>;
