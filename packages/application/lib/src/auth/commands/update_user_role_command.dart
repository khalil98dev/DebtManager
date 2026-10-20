import 'package:domain/domain.dart';
import 'package:meta/meta.dart';

/// Command to change a user's assigned role.
@immutable
final class UpdateUserRoleCommand {
  const UpdateUserRoleCommand({
    required this.userId,
    required this.roleId,
  });

  final UserId userId;
  final RoleId roleId;
}
