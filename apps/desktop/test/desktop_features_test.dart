import 'package:data/data.dart';
import 'package:design_system/design_system.dart';
import 'package:desktop/desktop_app.dart';
import 'package:desktop/features/allocations/screens/desktop_allocations_screen.dart';
import 'package:desktop/features/dashboard/screens/desktop_dashboard_screen.dart';
import 'package:desktop/features/financial/screens/desktop_financial_screen.dart';
import 'package:desktop/features/invoices/screens/desktop_invoices_screen.dart';
import 'package:desktop/features/payments/screens/desktop_payments_screen.dart';
import 'package:desktop/features/settings/screens/desktop_settings_screen.dart';
import 'package:desktop/features/sync_status/screens/desktop_sync_status_screen.dart';
import 'package:domain/domain.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Desktop Features Suite', () {
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
      'DesktopDashboardScreen renders KPI metric cards and quick actions',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          CupertinoApp(home: DesktopDashboardScreen(dependencies: deps)),
        );
        await tester.pumpAndSettle();

        expect(find.text('Dashboard'), findsWidgets);
        expect(find.text('Outstanding Debt'), findsOneWidget);
        expect(find.text('Unallocated Credit'), findsOneWidget);
        expect(find.text('Total Invoiced'), findsOneWidget);
        expect(find.text('Portfolio Net Position'), findsOneWidget);
        expect(find.text('New Client'), findsOneWidget);
        expect(find.text('New Invoice'), findsOneWidget);
        expect(find.text('Record Payment'), findsOneWidget);
      },
    );

    testWidgets('DesktopInvoicesScreen renders empty state then invoice item', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        CupertinoApp(
          home: DesktopInvoicesScreen(
            key: const ValueKey('inv_empty'),
            dependencies: deps,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Invoices'), findsWidgets);
      expect(find.text('No Invoices Found'), findsOneWidget);

      final client = Client.create(name: 'Wayne Enterprises');
      await deps.clientRepository.add(client);

      final invoice = Invoice.create(
        number: 'INV-DESK-01',
        clientId: client.id,
        currency: Currency.dzd,
        lines: [
          InvoiceLine.create(
            description: 'Security Audit',
            quantity: 1,
            unitPrice: Money(25000, Currency.dzd),
          ),
        ],
      );
      await deps.invoiceRepository.add(invoice);

      await tester.pumpWidget(
        CupertinoApp(
          home: DesktopInvoicesScreen(
            key: const ValueKey('inv_populated'),
            dependencies: deps,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('INV-DESK-01'), findsWidgets);
      expect(find.text('Wayne Enterprises'), findsWidgets);
    });

    testWidgets(
      'DesktopPaymentsScreen renders empty state then recorded payment',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          CupertinoApp(
            home: DesktopPaymentsScreen(
              key: const ValueKey('pay_empty'),
              dependencies: deps,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Payments'), findsWidgets);
        expect(find.text('No Payments Recorded'), findsOneWidget);

        final client = Client.create(name: 'Queen Industries');
        await deps.clientRepository.add(client);

        final payment = Payment.create(
          clientId: client.id,
          amount: Money(50000, Currency.dzd),
          receivedAt: DateTime.now(),
          notes: 'Retainer deposit',
        );
        await deps.paymentRepository.add(payment);

        await tester.pumpWidget(
          CupertinoApp(
            home: DesktopPaymentsScreen(
              key: const ValueKey('pay_populated'),
              dependencies: deps,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Queen Industries'), findsWidgets);
        expect(find.text('Retainer deposit'), findsWidgets);
      },
    );

    testWidgets('DesktopAllocationsScreen renders empty state', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        CupertinoApp(home: DesktopAllocationsScreen(dependencies: deps)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Payment Allocations'), findsOneWidget);
      expect(find.text('No Payment Allocations'), findsOneWidget);
    });

    testWidgets('DesktopFinancialsScreen renders portfolio cards and search', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        CupertinoApp(home: DesktopFinancialsScreen(dependencies: deps)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Financial Overview'), findsOneWidget);
      expect(find.text('Total Outstanding Debt'), findsOneWidget);
      expect(find.text('Total Client Credit'), findsOneWidget);
      expect(find.text('Total Invoiced'), findsOneWidget);
      expect(find.text('Net Portfolio Balance'), findsOneWidget);
    });

    testWidgets('DesktopSyncStatusScreen renders offline active badge', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        CupertinoApp(home: DesktopSyncStatusScreen(dependencies: deps)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sync Status & Outbox'), findsOneWidget);
      expect(
        find.text('Offline-First Local Foundation (Phase 1)'),
        findsOneWidget,
      );
      expect(find.text('Pending Outbox'), findsOneWidget);
    });

    testWidgets('DesktopSettingsScreen renders appearance and SQLite stats', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        CupertinoApp(home: DesktopSettingsScreen(dependencies: deps)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsWidgets);
      expect(find.text('Appearance'), findsOneWidget);
      expect(find.text('Currency & Subunits'), findsOneWidget);
      expect(find.text('Local Database Diagnostics'), findsOneWidget);
      expect(find.text('SQLite Schema Version'), findsOneWidget);
    });
  });
}
