import 'package:data/data.dart';
import 'package:design_system/design_system.dart';
import 'package:desktop/desktop_app.dart';
import 'package:desktop/features/clients/screens/desktop_clients_screen.dart';
import 'package:domain/domain.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Desktop Application & Clients Overview', () {
    testWidgets('DesktopApp boots with persistent sidebar and seeded clients', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final fakeRepo = FakeClientRepository(seeded: true);

      await tester.pumpWidget(DesktopApp(repository: fakeRepo));
      await tester.pumpAndSettle();

      // Check sidebar items
      expect(find.text('Debt Manager'), findsOneWidget);
      expect(find.text('Clients'), findsWidgets);
      expect(find.text('Invoices'), findsOneWidget);
      expect(find.text('Payments'), findsOneWidget);
      expect(find.text('Financials'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);

      // Check client overview
      expect(find.text('Acme Corporation'), findsWidgets);
      expect(find.text('New Client'), findsOneWidget);
      expect(find.text('Financial Summary'), findsOneWidget);
    });

    testWidgets(
      'DesktopClientsScreen search filters clients and handles clear',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final repo = FakeClientRepository();
        await repo.add(Client.create(name: 'Apple Inc', phone: '+14089961010'));
        await repo.add(
          Client.create(name: 'Banana Corp', phone: '+1234567890'),
        );

        await tester.pumpWidget(
          CupertinoApp(home: DesktopClientsScreen(repository: repo)),
        );
        await tester.pumpAndSettle();

        expect(find.text('Apple Inc'), findsWidgets);
        expect(find.text('Banana Corp'), findsOneWidget);

        // Search for Apple
        await tester.enterText(find.byType(CupertinoTextField), 'Apple');
        await tester.pumpAndSettle();

        expect(find.text('Apple Inc'), findsWidgets);
        expect(find.text('Banana Corp'), findsNothing);

        // Clear search
        final clearButton = find.byIcon(CupertinoIcons.clear_thick_circled);
        await tester.tap(clearButton);
        await tester.pumpAndSettle();

        expect(find.text('Apple Inc'), findsWidgets);
        expect(find.text('Banana Corp'), findsOneWidget);
      },
    );

    testWidgets(
      'DesktopClientsScreen shows empty state when repository is empty',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final repo = FakeClientRepository(seeded: false);

        await tester.pumpWidget(
          CupertinoApp(home: DesktopClientsScreen(repository: repo)),
        );
        await tester.pumpAndSettle();

        expect(find.text('No Clients Found'), findsOneWidget);
        expect(find.text('Create First Client'), findsOneWidget);
      },
    );

    testWidgets(
      'DesktopClientsScreen shows search no-results state when query matches nothing',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final repo = FakeClientRepository(seeded: true);

        await tester.pumpWidget(
          CupertinoApp(home: DesktopClientsScreen(repository: repo)),
        );
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byType(CupertinoTextField),
          'XYZ-NoSuchClient',
        );
        await tester.pumpAndSettle();

        expect(find.text('No Matching Clients'), findsOneWidget);
        expect(find.text('Clear Search'), findsOneWidget);

        await tester.tap(find.text('Clear Search'));
        await tester.pumpAndSettle();

        expect(find.text('Acme Corporation'), findsWidgets);
      },
    );

    testWidgets(
      'Tapping New Client opens client form dialog and saves client',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final repo = FakeClientRepository(seeded: true);
        await tester.pumpWidget(DesktopApp(repository: repo));
        await tester.pumpAndSettle();

        // Click New Client
        final newClientBtn = find.text('New Client');
        expect(newClientBtn, findsOneWidget);
        await tester.tap(newClientBtn);
        await tester.pumpAndSettle();

        // Dialog should be displayed with frosted blur
        expect(find.byType(ClientFormDialog), findsOneWidget);
        expect(find.text('Full Name / Company'), findsOneWidget);

        // Enter new client name
        await tester.enterText(
          find
              .descendant(
                of: find.byType(ClientFormDialog),
                matching: find.byType(CupertinoTextField),
              )
              .first,
          'Zenith Enterprises',
        );
        await tester.pump();

        // Submit client
        await tester.tap(find.text('Create Client'));
        await tester.pumpAndSettle();

        // Client dialog dismissed and client appears in list
        expect(find.byType(ClientFormDialog), findsNothing);
        expect(find.text('Zenith Enterprises'), findsWidgets);
      },
    );

    testWidgets(
      'Client Composite panel triggers New Invoice and Record Payment dialogs',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final repo = FakeClientRepository(seeded: true);
        await tester.pumpWidget(DesktopApp(repository: repo));
        await tester.pumpAndSettle();

        // Verify Composite panel elements for selected client
        expect(find.text('Actions & Operations'), findsOneWidget);
        expect(find.text('Billed Invoices'), findsOneWidget);
        expect(find.text('Payments & Receipts'), findsOneWidget);

        // Tap New Invoice from Client composite actions
        final newInvoiceAction = find.text('New Invoice');
        expect(newInvoiceAction, findsOneWidget);
        await tester.tap(newInvoiceAction);
        await tester.pumpAndSettle();

        // Invoice dialog should open
        expect(find.byType(InvoiceFormDialog), findsOneWidget);

        // Dismiss invoice dialog
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        expect(find.byType(InvoiceFormDialog), findsNothing);

        // Tap Record Payment from Client composite actions
        final recordPaymentAction = find.text('Record Payment');
        expect(recordPaymentAction, findsOneWidget);
        await tester.tap(recordPaymentAction);
        await tester.pumpAndSettle();

        // Payment dialog should open
        expect(find.byType(PaymentFormDialog), findsOneWidget);

        // Dismiss payment dialog
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        expect(find.byType(PaymentFormDialog), findsNothing);
      },
    );
  });
}
