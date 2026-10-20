import '../common/entity_id.dart';
import 'client.dart';

/// Identifier for a [Client] entity.
///
/// Aliases [EntityId<Client>] to reuse centralized UUID generation,
/// validation, equality, hashing, and serialization.
typedef ClientId = EntityId<Client>;
