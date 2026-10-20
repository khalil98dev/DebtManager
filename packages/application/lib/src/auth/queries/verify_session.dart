import 'package:domain/domain.dart';

import '../../common/result.dart';
import '../../repositories/role_repository.dart';
import '../../repositories/user_repository.dart';
import 'verify_session_query.dart';

/// Verifies a signed JWT token and resolves the active [User] and [Role].
final class VerifySession {
  const VerifySession({
    required this.userRepository,
    required this.roleRepository,
    this.jwtService = const JwtService(),
  });

  final UserRepository userRepository;
  final RoleRepository roleRepository;
  final JwtService jwtService;

  Future<Result<AuthSession>> execute(VerifySessionQuery query) async {
    try {
      await roleRepository.ensureSystemRoles();

      final payload = jwtService.verifyToken(query.jwtToken);
      if (payload == null) {
        return const Result.failure(
          AuthenticationFailure(
            message: 'Session token is invalid or has expired.',
          ),
        );
      }

      final user = await userRepository.getById(UserId(payload.sub));
      if (user == null || !user.isActive) {
        return const Result.failure(
          AuthenticationFailure(
            message: 'Authenticated user no longer exists or is inactive.',
          ),
        );
      }

      final role =
          await roleRepository.getById(user.roleId) ?? Role.systemOperator();

      // Re-issue fresh token if role permissions were updated since token creation
      final refreshedToken = jwtService.generateToken(user: user, role: role);
      final refreshedPayload = jwtService.verifyToken(refreshedToken)!;

      return Result.success(
        AuthSession(
          user: user,
          role: role,
          jwtToken: refreshedToken,
          payload: refreshedPayload,
        ),
      );
    } catch (e) {
      return Result.failure(
        RepositoryFailure(message: 'Failed to verify JWT session: $e', cause: e),
      );
    }
  }
}
