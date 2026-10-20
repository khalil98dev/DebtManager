/// Get client by ID execution.
library;

import 'package:domain/domain.dart';

import '../../common/result.dart';
import '../../repositories/client_repository.dart';
import 'get_client_by_id_query.dart';

/// Orchestrates retrieving a single [Client] by its unique [ClientId].
final class GetClientById {
  const GetClientById(this._clientRepository);

  final ClientRepository _clientRepository;

  /// Executes the client retrieval query.
  Future<Result<Client>> execute(GetClientByIdQuery query) async {
    try {
      final client = await _clientRepository.getById(query.id);
      if (client == null) {
        return Result.failure(
          NotFoundFailure(
            message: 'Client with ID ${query.id} was not found.',
            entityType: 'Client',
            entityId: query.id,
          ),
        );
      }
      return Result.success(client);
    } catch (e) {
      return Result.failure(
        RepositoryFailure(message: 'Failed to retrieve client: $e', cause: e),
      );
    }
  }
}
