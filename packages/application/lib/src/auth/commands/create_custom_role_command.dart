import 'package:domain/domain.dart';
import 'package:meta/meta.dart';

/// Command to create a custom role with a tailored set of [AppPermission]s.
@immutable
final class CreateCustomRoleCommand {
  const CreateCustomRoleCommand({
    this.id,
    required this.name,
    this.description,
    required this.permissions,
    this.createdAt,
  });

  final RoleId? id;
  final String name;
  final String? description;
  final Set<AppPermission> permissions;
  final DateTime? createdAt;
}
