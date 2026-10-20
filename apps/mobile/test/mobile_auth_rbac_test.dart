import 'package:data/data.dart';
import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/mobile_app.dart';

void main() {
  group('Mobile Auth & RBAC Flow', () {
    late AppDatabase db;
    late AppDependencies deps;

    setUp(() {
      db = AppDatabase.inMemory();
      deps = createMobileAppDependenciesFromDb(db);
    });

    tearDown(() async {
      await db.close();
    });

    testWidgets(
      'MobileApp boots into Create Admin Account at start and authenticates with JWT',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          MobileApp(dependencies: deps, requireAuth: true),
        );
        await tester.pumpAndSettle();

        expect(find.text('Create Admin Account'), findsOneWidget);
        expect(find.text('FIRST RUN · ADMIN SETUP'), findsOneWidget);

        await tester.enterText(
          find.byKey(const ValueKey('auth_display_name_field')),
          'Mobile Admin',
        );
        await tester.enterText(
          find.byKey(const ValueKey('auth_username_field')),
          'madmin',
        );
        await tester.enterText(
          find.byKey(const ValueKey('auth_password_field')),
          'secret123',
        );

        final submitBtn = find.byKey(const ValueKey('auth_submit_button'));
        await tester.ensureVisible(submitBtn);
        await tester.tap(submitBtn);
        await tester.pumpAndSettle();

        expect(deps.authViewModel.isAuthenticated, isTrue);
        expect(deps.authViewModel.currentSession?.isAdmin, isTrue);
        expect(find.text('Clients'), findsWidgets);
        expect(
          deps.hasPermission(AppPermission.manageUsersAndRoles),
          isTrue,
        );
      },
    );
  });
}
