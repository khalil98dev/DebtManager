import 'package:domain/domain.dart';

import '../../common/result.dart';
import '../../repositories/role_repository.dart';
import '../../repositories/user_repository.dart';
import 'register_user_command.dart';

/// Orchestrates creating a new [User] account and issuing an initial signed JWT [AuthSession].
///
/// - If no users exist yet in [UserRepository], the first registered account is
///   automatically assigned the built-in [Role.adminRoleId] (`Admin`).
/// - Subsequent accounts are assigned [RegisterUserCommand.roleId] if specified,
///   or default to [Role.operatorRoleId] (`Operator`).
final class RegisterUser {
  const RegisterUser({
    required this.userRepository,
    required this.roleRepository,
    this.jwtService = const JwtService(),
  });

  final UserRepository userRepository;
  final RoleRepository roleRepository;
  final JwtService jwtService;

  Future<Result<AuthSession>> execute(RegisterUserCommand command) async {
    try {
      await roleRepository.ensureSystemRoles();

      final trimmedUsername = command.username.trim().toLowerCase();
      final trimmedDisplayName = command.displayName.trim();
      if (trimmedUsername.length < 3) {
        return const Result.failure(
          ValidationFailure(
            message: 'Username must be at least 3 characters long.',
          ),
        );
      }
      if (trimmedDisplayName.isEmpty) {
        return const Result.failure(
          ValidationFailure(message: 'Full name cannot be empty.'),
        );
      }
      if (command.password.length < 6) {
        return const Result.failure(
          ValidationFailure(
            message: 'Password must be at least 6 characters long.',
          ),
        );
      }

      final existingUser = await userRepository.getByUsername(trimmedUsername);
      if (existingUser != null) {
        return Result.failure(
          ConflictFailure(
            message: 'Username "$trimmedUsername" is already registered.',
          ),
        );
      }

      final existingCount = await userRepository.count();
      final targetRoleId = existingCount == 0
          ? Role.adminRoleId
          : (command.roleId ?? Role.operatorRoleId);

      final role =
          await roleRepository.getById(targetRoleId) ??
          (existingCount == 0 ? Role.systemAdmin() : Role.systemOperator());

      final passwordHash = PasswordHasher.hashPassword(command.password);
      final user = User.create(
        id: command.id,
        username: trimmedUsername,
        displayName: trimmedDisplayName,
        passwordHash: passwordHash,
        roleId: role.id,
        createdAt: command.createdAt,
      );

      await userRepository.add(user);

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
    } on ArgumentError catch (e) {
      return Result.failure(
        ValidationFailure(
          message: e.message?.toString() ?? 'Invalid registration data.',
          cause: e,
        ),
      );
    } catch (e) {
      return Result.failure(
        RepositoryFailure(message: 'Failed to create account: $e', cause: e),
      );
    }
  }
}
