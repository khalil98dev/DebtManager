import 'dart:convert';
import 'package:meta/meta.dart';

import 'password_hasher.dart';
import 'permission.dart';
import 'role.dart';
import 'user.dart';

/// Decoded and verified claims inside a signed RFC 7519 JWT token.
@immutable
class JwtPayload {
  JwtPayload({
    required this.sub,
    required this.username,
    required this.displayName,
    required this.roleId,
    required this.roleName,
    required Iterable<AppPermission> permissions,
    required this.issuedAt,
    required this.expiresAt,
  }) : permissions = Set<AppPermission>.unmodifiable(permissions.toSet());

  factory JwtPayload.fromJson(Map<String, dynamic> json) {
    final rawPerms = (json['permissions'] as List<dynamic>? ?? const [])
        .map((e) => e.toString())
        .map(AppPermission.tryFromName)
        .whereType<AppPermission>();

    final iatSeconds = (json['iat'] as num?)?.toInt() ?? 0;
    final expSeconds = (json['exp'] as num?)?.toInt() ?? 0;

    return JwtPayload(
      sub: (json['sub'] ?? '').toString(),
      username: (json['username'] ?? '').toString(),
      displayName: (json['name'] ?? '').toString(),
      roleId: (json['roleId'] ?? '').toString(),
      roleName: (json['roleName'] ?? '').toString(),
      permissions: rawPerms,
      issuedAt: DateTime.fromMillisecondsSinceEpoch(
        iatSeconds * 1000,
        isUtc: true,
      ),
      expiresAt: DateTime.fromMillisecondsSinceEpoch(
        expSeconds * 1000,
        isUtc: true,
      ),
    );
  }

  final String sub;
  final String username;
  final String displayName;
  final String roleId;
  final String roleName;
  final Set<AppPermission> permissions;
  final DateTime issuedAt;
  final DateTime expiresAt;

  bool isExpired({DateTime? now}) {
    final checkTime = (now ?? DateTime.now()).toUtc();
    return checkTime.isAfter(expiresAt);
  }

  bool hasPermission(AppPermission permission) =>
      permissions.contains(permission);

  Map<String, dynamic> toJson() => {
    'sub': sub,
    'username': username,
    'name': displayName,
    'roleId': roleId,
    'roleName': roleName,
    'permissions': permissions.map((p) => p.name).toList(),
    'iat': issuedAt.toUtc().millisecondsSinceEpoch ~/ 1000,
    'exp': expiresAt.toUtc().millisecondsSinceEpoch ~/ 1000,
  };
}

/// Service that issues and verifies RFC 7519 HS256 JSON Web Tokens (JWT).
class JwtService {
  const JwtService({
    this.secretKey = 'depts_manager_local_jwt_signing_key_v1_hmac_sha256',
    this.defaultTtl = const Duration(hours: 24),
  });

  final String secretKey;
  final Duration defaultTtl;

  /// Generates a signed HS256 JWT token for the given [user] and [role].
  String generateToken({
    required User user,
    required Role role,
    Duration? ttl,
    DateTime? issuedAt,
  }) {
    final nowUtc = (issuedAt ?? DateTime.now()).toUtc();
    final expUtc = nowUtc.add(ttl ?? defaultTtl);

    final payload = JwtPayload(
      sub: user.id.value,
      username: user.username,
      displayName: user.displayName,
      roleId: role.id.value,
      roleName: role.name,
      permissions: role.permissions,
      issuedAt: nowUtc,
      expiresAt: expUtc,
    );

    final headerJson = jsonEncode(const {'alg': 'HS256', 'typ': 'JWT'});
    final payloadJson = jsonEncode(payload.toJson());

    final encodedHeader = _base64UrlEncodeNoPad(utf8.encode(headerJson));
    final encodedPayload = _base64UrlEncodeNoPad(utf8.encode(payloadJson));
    final signingInput = '$encodedHeader.$encodedPayload';

    final signatureBytes = PasswordHasher.hmacSha256(
      utf8.encode(secretKey),
      utf8.encode(signingInput),
    );
    final encodedSignature = _base64UrlEncodeNoPad(signatureBytes);

    return '$signingInput.$encodedSignature';
  }

  /// Verifies the cryptographic signature and expiration of [token].
  /// Returns the decoded [JwtPayload] if valid, or `null` if tampered or expired.
  JwtPayload? verifyToken(String token, {DateTime? now}) {
    final parts = token.split('.');
    if (parts.length != 3) return null;

    final signingInput = '${parts[0]}.${parts[1]}';
    final expectedSigBytes = PasswordHasher.hmacSha256(
      utf8.encode(secretKey),
      utf8.encode(signingInput),
    );
    final expectedSig = _base64UrlEncodeNoPad(expectedSigBytes);

    if (!_constantTimeEquals(parts[2], expectedSig)) {
      return null;
    }

    try {
      final payloadBytes = base64Url.decode(base64Url.normalize(parts[1]));
      final payloadMap =
          jsonDecode(utf8.decode(payloadBytes)) as Map<String, dynamic>;
      final payload = JwtPayload.fromJson(payloadMap);
      if (payload.isExpired(now: now)) {
        return null;
      }
      return payload;
    } catch (_) {
      return null;
    }
  }

  static String _base64UrlEncodeNoPad(List<int> bytes) {
    return base64UrlEncode(bytes).replaceAll('=', '');
  }

  static bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }
}
