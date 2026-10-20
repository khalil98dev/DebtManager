import 'package:application/application.dart';
import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Authentication & RBAC Use Cases', () {
    late InMemoryUserRepository userRepo;
    late InMemoryRoleRepository roleRepo;
    late RegisterUser registerUser;
    late LoginUser loginUser;
    late CreateCustomRole createCustomRole;
    late UpdateUserRole updateUserRole;

    setUp(() {
      userRepo = InMemoryUserRepository();
      roleRepo = InMemoryRoleRepository();
      registerUser = RegisterUser(
        userRepository: userRepo,
        roleRepository: roleRepo,
      );
      loginUser = LoginUser(
        userRepository: userRepo,
        roleRepository: roleRepo,
      );
      createCustomRole = CreateCustomRole(roleRepo);
      updateUserRole = UpdateUserRole(
        userRepository: userRepo,
        roleRepository: roleRepo,
      );
    });

    test(
      'First account created at start automatically becomes Admin; second account defaults to Operator',
      () async {
        final firstResult = await registerUser.execute(
          const RegisterUserCommand(
            username: 'founder',
            displayName: 'Founder Admin',
            password: 'password123',
          ),
        );

        expect(firstResult.isSuccess, isTrue);
        final adminSession = firstResult.dataOrNull!;
        expect(adminSession.isAdmin, isTrue);
        expect(adminSession.role.id, equals(Role.adminRoleId));
        expect(
          adminSession.hasPermission(AppPermission.manageUsersAndRoles),
          isTrue,
        );

        final secondResult = await registerUser.execute(
          const RegisterUserCommand(
            username: 'staff1',
            displayName: 'Staff Member',
            password: 'password123',
          ),
        );

        expect(secondResult.isSuccess, isTrue);
        final operatorSession = secondResult.dataOrNull!;
        expect(operatorSession.isAdmin, isFalse);
        expect(operatorSession.role.id, equals(Role.operatorRoleId));
        expect(
          operatorSession.hasPermission(AppPermission.printInvoices),
          isTrue,
        );
        expect(
          operatorSession.hasPermission(AppPermission.recordPayments),
          isTrue,
        );
        expect(
          operatorSession.hasPermission(AppPermission.manageInvoices),
          isFalse,
        );
      },
    );

    test(
      'Custom Role creation and assignment encodes custom permissions in JWT on Login',
      () async {
        // Register initial admin and second user
        await registerUser.execute(
          const RegisterUserCommand(
            username: 'admin',
            displayName: 'Admin',
            password: 'password123',
          ),
        );
        final staffReg = await registerUser.execute(
          const RegisterUserCommand(
            username: 'billing_agent',
            displayName: 'Billing Agent',
            password: 'password123',
          ),
        );
        final staffUser = staffReg.dataOrNull!.user;

        // Create custom role with specific permissions
        final customRoleRes = await createCustomRole.execute(
          const CreateCustomRoleCommand(
            name: 'Billing Specialist',
            description: 'Can create/print invoices and record payments',
            permissions: {
              AppPermission.viewClients,
              AppPermission.viewInvoices,
              AppPermission.manageInvoices,
              AppPermission.printInvoices,
              AppPermission.recordPayments,
            },
          ),
        );
        expect(customRoleRes.isSuccess, isTrue);
        final customRole = customRoleRes.dataOrNull!;

        // Assign custom role to user
        final updateRes = await updateUserRole.execute(
          UpdateUserRoleCommand(userId: staffUser.id, roleId: customRole.id),
        );
        expect(updateRes.isSuccess, isTrue);

        // Login as billing_agent and check JWT permissions
        final loginRes = await loginUser.execute(
          const LoginUserCommand(
            username: 'billing_agent',
            password: 'password123',
          ),
        );
        expect(loginRes.isSuccess, isTrue);
        final session = loginRes.dataOrNull!;
        expect(session.role.name, equals('Billing Specialist'));
        expect(session.hasPermission(AppPermission.manageInvoices), isTrue);
        expect(session.hasPermission(AppPermission.printInvoices), isTrue);
        expect(session.hasPermission(AppPermission.recordPayments), isTrue);
        expect(session.hasPermission(AppPermission.issueInvoices), isFalse);
      },
    );
  });
}
