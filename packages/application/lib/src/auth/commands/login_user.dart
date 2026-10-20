import 'package:domain/domain.dart';

import '../../common/result.dart';
import '../../repositories/role_repository.dart';
import '../../repositories/user_repository.dart';
import 'login_user_command.dart';

/// Authenticates a user by username and password and issues a signed JWT [AuthSession].
final class LoginUser {
  const LoginUser({
    required this.userRepository,
    required this.roleRepository,
    this.jwtService = const JwtService(),
  });

  final UserRepository userRepository;
  final RoleRepository roleRepository;
  final JwtService jwtService;

  Future<Result<AuthSession>> execute(LoginUserCommand command) async {
    try {
      await roleRepository.ensureSystemRoles();

      final normalizedUsername = command.username.trim().toLowerCase();
      if (normalizedUsername.isEmpty || command.password.isEmpty) {
        return const Result.failure(
          ValidationFailure(message: 'Username and password are required.'),
        );
      }

      final user = await userRepository.getByUsername(normalizedUsername);
      if (user == null ||
          !PasswordHasher.verifyPassword(command.password, user.passwordHash)) {
        return const Result.failure(
          AuthenticationFailure(
            message: 'Invalid username or password.',
          ),
        );
      }

      if (!user.isActive) {
        return const Result.failure(
          AuthorizationFailure(
            message: 'This user account has been deactivated.',
          ),
        );
      }

      final role =
          await roleRepository.getById(user.roleId) ?? Role.systemOperator();

      final token = jwtService.generateToken(user: user, role: role);
      final payload = jwtService.verifyToken(token)!;

      return Result.success(
        AuthSession(
          user: user,
          role: role,
          jwtToken: token,
          payload: payload,
        ),
      );
    } catch (e) {
      return Result.failure(
        RepositoryFailure(message: 'Failed to authenticate user: $e', cause: e),
      );
    }
  }
}
