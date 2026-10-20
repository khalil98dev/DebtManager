import 'package:meta/meta.dart';

/// Query to verify a signed JWT token and resolve the active [AuthSession].
@immutable
final class VerifySessionQuery {
  const VerifySessionQuery({required this.jwtToken});

  final String jwtToken;
}
