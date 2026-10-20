import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PasswordHasher & JwtService & RBAC Domain', () {
    test('PasswordHasher hashes and verifies passwords accurately', () {
      final hash = PasswordHasher.hashPassword('MySecretPass123!');
      expect(hash.contains('\$'), isTrue);
      expect(PasswordHasher.verifyPassword('MySecretPass123!', hash), isTrue);
      expect(PasswordHasher.verifyPassword('WrongPassword', hash), isFalse);
    });

    test(
      'Role.systemAdmin has all permissions and Role.systemOperator has Print Invoice & Record Payment base permissions',
      () {
        final admin = Role.systemAdmin();
        final operatorRole = Role.systemOperator();

        expect(admin.isAdmin, isTrue);
        for (final perm in AppPermission.values) {
          expect(admin.hasPermission(perm), isTrue);
        }

        expect(operatorRole.isAdmin, isFalse);
        expect(operatorRole.hasPermission(AppPermission.printInvoices), isTrue);
        expect(
          operatorRole.hasPermission(AppPermission.recordPayments),
          isTrue,
        );
        expect(operatorRole.hasPermission(AppPermission.viewInvoices), isTrue);
        expect(operatorRole.hasPermission(AppPermission.viewPayments), isTrue);
        expect(
          operatorRole.hasPermission(AppPermission.manageInvoices),
          isFalse,
        );
        expect(
          operatorRole.hasPermission(AppPermission.manageUsersAndRoles),
          isFalse,
        );
      },
    );

    test(
      'JwtService issues valid HS256 JWT token, verifies claims, and rejects tampered or expired tokens',
      () {
        const jwtService = JwtService(secretKey: 'unit_test_secret_key');
        final operatorRole = Role.systemOperator();
        final user = User.create(
          username: 'cashier1',
          displayName: 'Cashier One',
          passwordHash: PasswordHasher.hashPassword('secret123'),
          roleId: operatorRole.id,
        );

        final issuedAt = DateTime.utc(2026, 10, 20, 12, 0);
        final token = jwtService.generateToken(
          user: user,
          role: operatorRole,
          issuedAt: issuedAt,
          ttl: const Duration(hours: 2),
        );

        expect(token.split('.').length, equals(3));

        final payload = jwtService.verifyToken(
          token,
          now: DateTime.utc(2026, 10, 20, 13, 0),
        );
        expect(payload, isNotNull);
        expect(payload!.sub, equals(user.id.value));
        expect(payload.username, equals('cashier1'));
        expect(payload.roleName, equals('Operator'));
        expect(payload.hasPermission(AppPermission.printInvoices), isTrue);
        expect(payload.hasPermission(AppPermission.recordPayments), isTrue);
        expect(payload.hasPermission(AppPermission.manageInvoices), isFalse);

        // Expired check
        final expiredPayload = jwtService.verifyToken(
          token,
          now: DateTime.utc(2026, 10, 20, 15, 0),
        );
        expect(expiredPayload, isNull);

        // Tampered signature check
        final tampered = '${token}tampered';
        expect(
          jwtService.verifyToken(
            tampered,
            now: DateTime.utc(2026, 10, 20, 13, 0),
          ),
          isNull,
        );
      },
    );
  });
}
