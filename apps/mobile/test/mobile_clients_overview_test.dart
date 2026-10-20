import 'package:data/data.dart';
import 'package:domain/domain.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/clients/screens/mobile_clients_screen.dart';
import 'package:mobile/mobile_app.dart';

void main() {
  group('Mobile Application & Clients Overview', () {
    testWidgets('MobileApp boots with iOS tab bar and seeded clients', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(
        390,
        844,
      ); // iPhone 14 / modern iOS screen size
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final fakeRepo = FakeClientRepository(seeded: true);

      await tester.pumpWidget(MobileApp(repository: fakeRepo));
      await tester.pumpAndSettle();

      // Check tab items
      expect(find.text('Clients'), findsWidgets);
      expect(find.text('Invoices'), findsOneWidget);
      expect(find.text('Payments'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);

      // Check client overview
      expect(find.text('Acme Corporation'), findsOneWidget);
      expect(find.byType(MobileClientsScreen), findsOneWidget);
      expect(find.byType(CustomScrollView), findsOneWidget);
    });

    testWidgets(
      'MobileClientsScreen search filters clients and handles clear',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final repo = FakeClientRepository();
        await repo.add(
          Client.create(name: 'Sarah Connor', phone: '+2135551122'),
        );
        await repo.add(
          Client.create(name: 'John Connor', phone: '+2135553344'),
        );

        await tester.pumpWidget(
          CupertinoApp(home: MobileClientsScreen(repository: repo)),
        );
        await tester.pumpAndSettle();

        expect(find.text('Sarah Connor'), findsOneWidget);
        expect(find.text('John Connor'), findsOneWidget);

        // Search for Sarah
        await tester.enterText(find.byType(CupertinoTextField), 'Sarah');
        await tester.pumpAndSettle();

        expect(find.text('Sarah Connor'), findsOneWidget);
        expect(find.text('John Connor'), findsNothing);

        // Clear search
        final clearButton = find.byIcon(CupertinoIcons.clear_thick_circled);
        await tester.tap(clearButton);
        await tester.pumpAndSettle();

        expect(find.text('Sarah Connor'), findsOneWidget);
        expect(find.text('John Connor'), findsOneWidget);
      },
    );

    testWidgets('Tapping a client displays CupertinoActionSheet with details', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final repo = FakeClientRepository();
      await repo.add(
        Client.create(
          name: 'Wayne Enterprises',
          phone: '+1 234 567',
          notes: 'Important account',
        ),
      );

      await tester.pumpWidget(
        CupertinoApp(home: MobileClientsScreen(repository: repo)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Wayne Enterprises'));
      await tester.pumpAndSettle();

      // Modal action sheet should be presented
      expect(find.byType(CupertinoActionSheet), findsOneWidget);
      expect(find.text('View Financial History'), findsOneWidget);
      expect(find.text('Edit Client'), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);

      // Dismiss modal
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      expect(find.byType(CupertinoActionSheet), findsNothing);
    });

    testWidgets(
      'MobileClientsScreen displays empty state when repository has no clients',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final repo = FakeClientRepository(seeded: false);

        await tester.pumpWidget(
          CupertinoApp(home: MobileClientsScreen(repository: repo)),
        );
        await tester.pumpAndSettle();

        expect(find.text('No Clients Yet'), findsOneWidget);
        expect(find.text('Add Client'), findsOneWidget);
      },
    );

    testWidgets('MobileClientsScreen displays search-no-results state', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final repo = FakeClientRepository(seeded: true);

      await tester.pumpWidget(
        CupertinoApp(home: MobileClientsScreen(repository: repo)),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(CupertinoTextField),
        'XYZ-NoSuchClient',
      );
      await tester.pumpAndSettle();

      expect(find.text('No Clients Found'), findsOneWidget);
      expect(find.text('Clear Search'), findsOneWidget);

      await tester.tap(find.text('Clear Search'));
      await tester.pumpAndSettle();

      expect(find.text('Acme Corporation'), findsOneWidget);
    });
  });
}
