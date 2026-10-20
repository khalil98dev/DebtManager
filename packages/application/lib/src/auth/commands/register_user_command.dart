import 'package:domain/domain.dart';
import 'package:meta/meta.dart';

/// Command to register a new user account.
@immutable
final class RegisterUserCommand {
  const RegisterUserCommand({
    this.id,
    required this.username,
    required this.displayName,
    required this.password,
    this.roleId,
    this.createdAt,
  });

  final UserId? id;
  final String username;
  final String displayName;
  final String password;
  final RoleId? roleId;
  final DateTime? createdAt;
}
