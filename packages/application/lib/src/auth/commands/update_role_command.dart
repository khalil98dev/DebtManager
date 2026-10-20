import 'package:domain/domain.dart';
import 'package:meta/meta.dart';

/// Command to update an existing role's name, description, or permissions.
@immutable
final class UpdateRoleCommand {
  const UpdateRoleCommand({
    required this.roleId,
    required this.name,
    this.description,
    required this.permissions,
  });

  final RoleId roleId;
  final String name;
  final String? description;
  final Set<AppPermission> permissions;
}
