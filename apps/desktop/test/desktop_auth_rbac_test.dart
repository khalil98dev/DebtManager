import 'package:data/data.dart';
import 'package:design_system/design_system.dart';
import 'package:desktop/desktop_app.dart';
import 'package:domain/domain.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Desktop Auth & RBAC Flow', () {
    late AppDatabase db;
    late AppDependencies deps;

    setUp(() {
      db = AppDatabase.inMemory();
      deps = createAppDependenciesFromDb(db);
    });

    tearDown(() async {
      await db.close();
    });

    testWidgets(
      'Boots into Create Admin Account at start, logs in with JWT, and enforces RBAC for Operator role',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          DesktopApp(dependencies: deps, requireAuth: true),
        );
        await tester.pumpAndSettle();

        // 1. Verify initial startup shows First-Run Create Admin Account screen
        expect(find.text('Create Admin Account'), findsOneWidget);
        expect(find.text('FIRST RUN · ADMIN SETUP'), findsOneWidget);

        await tester.enterText(
          find.byKey(const ValueKey('auth_display_name_field')),
          'Khalil Admin',
        );
        await tester.enterText(
          find.byKey(const ValueKey('auth_username_field')),
          'khalil',
        );
        await tester.enterText(
          find.byKey(const ValueKey('auth_password_field')),
          'secret123',
        );

        final submitBtn = find.byKey(const ValueKey('auth_submit_button'));
        await tester.ensureVisible(submitBtn);
        await tester.tap(submitBtn);
        await tester.pumpAndSettle();

        // 2. Verify signed in as Admin and Dashboard is visible
        expect(deps.authViewModel.isAuthenticated, isTrue);
        expect(deps.authViewModel.currentSession?.isAdmin, isTrue);
        expect(find.text('Khalil Admin'), findsWidgets);
        expect(find.text('Role: Admin'), findsOneWidget);
        expect(find.text('Outstanding Debt'), findsOneWidget);

        // 3. Sign out and create an Operator account (base non-admin role)
        deps.authViewModel.logout();
        await tester.pumpAndSettle();

        expect(find.text('Sign In to Debt Manager'), findsOneWidget);

        // Switch to Create Account tab
        await tester.tap(find.text('Create Account'));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const ValueKey('auth_display_name_field')),
          'Cashier Staff',
        );
        await tester.enterText(
          find.byKey(const ValueKey('auth_username_field')),
          'cashier',
        );
        await tester.enterText(
          find.byKey(const ValueKey('auth_password_field')),
          'secret123',
        );

        await tester.ensureVisible(submitBtn);
        await tester.tap(submitBtn);
        await tester.pumpAndSettle();

        // 4. Verify Operator role is active and Dashboard is restricted
        expect(deps.authViewModel.isAuthenticated, isTrue);
        expect(deps.authViewModel.currentSession?.role.name, equals('Operator'));
        expect(find.text('Dashboard Restricted'), findsOneWidget);
        expect(
          deps.hasPermission(AppPermission.printInvoices),
          isTrue,
        );
        expect(
          deps.hasPermission(AppPermission.recordPayments),
          isTrue,
        );
        expect(
          deps.hasPermission(AppPermission.manageInvoices),
          isFalse,
        );
      },
    );
  });
}
