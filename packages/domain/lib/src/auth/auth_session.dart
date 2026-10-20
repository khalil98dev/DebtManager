import 'package:meta/meta.dart';

import 'jwt_service.dart';
import 'permission.dart';
import 'role.dart';
import 'user.dart';

/// Represents an active authenticated session backed by a verified JWT.
@immutable
class AuthSession {
  const AuthSession({
    required this.user,
    required this.role,
    required this.jwtToken,
    required this.payload,
  });

  final User user;
  final Role role;
  final String jwtToken;
  final JwtPayload payload;

  bool get isAdmin => role.isAdmin;

  /// Checks whether the session grants [permission] in both its JWT claims and active role.
  bool hasPermission(AppPermission permission) {
    return payload.hasPermission(permission) && role.hasPermission(permission);
  }
}
