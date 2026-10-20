import 'package:domain/domain.dart';

import '../../common/result.dart';
import '../../repositories/role_repository.dart';
import '../../repositories/user_repository.dart';
import 'update_user_role_command.dart';

/// Updates the assigned [RoleId] of an existing [User].
final class UpdateUserRole {
  const UpdateUserRole({
    required this.userRepository,
    required this.roleRepository,
  });

  final UserRepository userRepository;
  final RoleRepository roleRepository;

  Future<Result<User>> execute(UpdateUserRoleCommand command) async {
    try {
      await roleRepository.ensureSystemRoles();

      final user = await userRepository.getById(command.userId);
      if (user == null) {
        return Result.failure(
          NotFoundFailure(
            message: 'User not found.',
            entityType: 'User',
            entityId: command.userId,
          ),
        );
      }

      final role = await roleRepository.getById(command.roleId);
      if (role == null) {
        return Result.failure(
          NotFoundFailure(
            message: 'Target role not found.',
            entityType: 'Role',
            entityId: command.roleId,
          ),
        );
      }

      final updated = user.changeRole(role.id);
      await userRepository.update(updated);
      return Result.success(updated);
    } catch (e) {
      return Result.failure(
        RepositoryFailure(message: 'Failed to update user role: $e', cause: e),
      );
    }
  }
}
