/// Query for retrieving a client by unique identifier.
library;

import 'package:domain/domain.dart';

/// Query input for looking up a single [Client] by its unique [ClientId].
final class GetClientByIdQuery {
  const GetClientByIdQuery(this.id);

  /// Unique client identifier to look up.
  final ClientId id;
}
