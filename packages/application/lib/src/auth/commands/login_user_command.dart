import 'package:meta/meta.dart';

/// Command to authenticate an existing user with username and password.
@immutable
final class LoginUserCommand {
  const LoginUserCommand({
    required this.username,
    required this.password,
  });

  final String username;
  final String password;
}
