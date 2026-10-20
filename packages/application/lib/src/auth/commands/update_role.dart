import 'package:domain/domain.dart';

import '../../common/result.dart';
import '../../repositories/role_repository.dart';
import 'update_role_command.dart';

/// Updates an existing [Role]'s permissions and metadata.
final class UpdateRole {
  const UpdateRole(this._roleRepository);

  final RoleRepository _roleRepository;

  Future<Result<Role>> execute(UpdateRoleCommand command) async {
    try {
      await _roleRepository.ensureSystemRoles();

      final existing = await _roleRepository.getById(command.roleId);
      if (existing == null) {
        return Result.failure(
          NotFoundFailure(
            message: 'Role not found.',
            entityType: 'Role',
            entityId: command.roleId,
          ),
        );
      }

      if (existing.id == Role.adminRoleId) {
        return const Result.failure(
          ValidationFailure(
            message: 'The built-in Admin role permissions cannot be restricted.',
          ),
        );
      }

      if (command.permissions.isEmpty) {
        return const Result.failure(
          ValidationFailure(
            message: 'A role must grant at least one permission.',
          ),
        );
      }

      final updated = existing.copyWith(
        name: existing.isSystem ? existing.name : command.name.trim(),
        description: command.description,
        permissions: command.permissions,
      );

      await _roleRepository.update(updated);
      return Result.success(updated);
    } on ArgumentError catch (e) {
      return Result.failure(
        ValidationFailure(
          message: e.message?.toString() ?? 'Invalid role data.',
          cause: e,
        ),
      );
    } catch (e) {
      return Result.failure(
        RepositoryFailure(message: 'Failed to update role: $e', cause: e),
      );
    }
  }
}
