import '../common/entity_id.dart';
import 'invoice_line.dart';

/// Identifier for an [InvoiceLine] entity.
///
/// Aliases [EntityId<InvoiceLine>] to reuse centralized UUID generation,
/// validation, equality, hashing, and serialization.
typedef InvoiceLineId = EntityId<InvoiceLine>;
