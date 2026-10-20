import 'package:domain/domain.dart';

import '../../common/result.dart';
import '../../repositories/client_repository.dart';
import 'update_client_command.dart';

/// Orchestrates updating an existing [Client] entity.
final class UpdateClient {
  const UpdateClient(this._clientRepository);

  final ClientRepository _clientRepository;

  /// Executes client update and persistence.
  Future<Result<Client>> execute(UpdateClientCommand command) async {
    try {
      final existingClient = await _clientRepository.getById(command.id);
      if (existingClient == null) {
        return Result.failure(
          NotFoundFailure(
            message: 'Client with ID ${command.id} does not exist.',
            entityType: 'Client',
            entityId: command.id,
          ),
        );
      }

      final updated = existingClient
          .rename(command.name)
          .changePhone(command.phone)
          .changeNotes(command.notes);

      await _clientRepository.add(updated);
      return Result.success(updated);
    } on ArgumentError catch (e) {
      return Result.failure(
        ValidationFailure(
          message: e.message?.toString() ?? 'Invalid client update data.',
          cause: e,
        ),
      );
    } catch (e) {
      return Result.failure(
        RepositoryFailure(message: 'Failed to update client: $e', cause: e),
      );
    }
  }
}
