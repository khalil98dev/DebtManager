import 'package:domain/domain.dart';

import '../../common/result.dart';
import '../../repositories/role_repository.dart';
import 'create_custom_role_command.dart';

/// Creates and persists a new custom [Role] with custom [AppPermission]s.
final class CreateCustomRole {
  const CreateCustomRole(this._roleRepository);

  final RoleRepository _roleRepository;

  Future<Result<Role>> execute(CreateCustomRoleCommand command) async {
    try {
      await _roleRepository.ensureSystemRoles();

      final trimmedName = command.name.trim();
      if (trimmedName.isEmpty) {
        return const Result.failure(
          ValidationFailure(message: 'Role name cannot be empty.'),
        );
      }
      if (command.permissions.isEmpty) {
        return const Result.failure(
          ValidationFailure(
            message: 'Select at least one permission for the custom role.',
          ),
        );
      }

      final existing = await _roleRepository.getByName(trimmedName);
      if (existing != null) {
        return Result.failure(
          ConflictFailure(
            message: 'A role named "$trimmedName" already exists.',
          ),
        );
      }

      final role = Role.create(
        id: command.id,
        name: trimmedName,
        description: command.description,
        permissions: command.permissions,
        isSystem: false,
        createdAt: command.createdAt,
      );

      await _roleRepository.add(role);
      return Result.success(role);
    } on ArgumentError catch (e) {
      return Result.failure(
        ValidationFailure(
          message: e.message?.toString() ?? 'Invalid role definition.',
          cause: e,
        ),
      );
    } catch (e) {
      return Result.failure(
        RepositoryFailure(message: 'Failed to create custom role: $e', cause: e),
      );
    }
  }
}
