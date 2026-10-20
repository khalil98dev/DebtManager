/// Create client execution.
library;

import 'package:domain/domain.dart';

import '../../common/result.dart';
import '../../repositories/client_repository.dart';
import 'create_client_command.dart';

/// Orchestrates creating and persisting a new [Client] entity.
///
/// Supports offline-first creation:
/// - If [CreateClientCommand.id] is omitted, generates a new stable [ClientId].
/// - If [CreateClientCommand.id] is supplied, verifies whether a client with that ID exists:
///   - If matching existing data is found, handles as an idempotent retry.
///   - If differing existing data is found, returns a [ConflictFailure].
final class CreateClient {
  const CreateClient(this._clientRepository);

  final ClientRepository _clientRepository;

  /// Executes client creation and persistence.
  Future<Result<Client>> execute(CreateClientCommand command) async {
    try {
      if (command.id != null) {
        final existingClient = await _clientRepository.getById(command.id!);
        if (existingClient != null) {
          final trimmedName = command.name.trim();
          final normalizedPhone = ValidationUtils.normalizeOptionalString(
            command.phone,
          );
          final normalizedNotes = ValidationUtils.normalizeOptionalString(
            command.notes,
          );

          final isMatch =
              existingClient.name == trimmedName &&
              existingClient.phone == normalizedPhone &&
              existingClient.notes == normalizedNotes;

          if (isMatch) {
            // Idempotent retry: exact same client data replayed with the same ID.
            return Result.success(existingClient);
          } else {
            // ID collision: existing record with differing data.
            return Result.failure(
              ConflictFailure(
                message:
                    'Client with ID ${command.id} already exists with differing data.',
              ),
            );
          }
        }
      }

      final client = Client.create(
        id: command.id,
        name: command.name,
        phone: command.phone,
        notes: command.notes,
        createdAt: command.createdAt,
      );

      await _clientRepository.add(client);
      return Result.success(client);
    } on ArgumentError catch (e) {
      return Result.failure(
        ValidationFailure(
          message: e.message?.toString() ?? 'Invalid client data.',
          cause: e,
        ),
      );
    } catch (e) {
      return Result.failure(
        RepositoryFailure(message: 'Failed to create client: $e', cause: e),
      );
    }
  }
}
