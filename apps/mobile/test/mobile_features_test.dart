import 'package:data/data.dart';
import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/allocations/screens/mobile_allocations_screen.dart';
import 'package:mobile/features/financial/screens/mobile_financial_screen.dart';
import 'package:mobile/features/invoices/screens/mobile_invoices_screen.dart';
import 'package:mobile/features/payments/screens/mobile_payments_screen.dart';
import 'package:mobile/features/settings/screens/mobile_settings_screen.dart';
import 'package:mobile/mobile_app.dart';

void main() {
  group('Mobile Features Suite', () {
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
      'MobileInvoicesScreen renders empty state then populated list',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          CupertinoApp(
            home: MobileInvoicesScreen(
              key: const ValueKey('invoices_empty'),
              dependencies: deps,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Invoices'), findsWidgets);
        expect(find.text('No Invoices Yet'), findsOneWidget);

        // Seed a client and an invoice
        final client = Client.create(name: 'Wayne Tech', phone: '12345');
        await deps.clientRepository.add(client);

        final invoice = Invoice.create(
          number: 'INV-001',
          clientId: client.id,
          currency: Currency.dzd,
          lines: [
            InvoiceLine.create(
              description: 'Consulting',
              quantity: 2,
              unitPrice: Money(5000, Currency.dzd),
            ),
          ],
        );
        await deps.invoiceRepository.add(invoice);

        await tester.pumpWidget(
          CupertinoApp(
            home: MobileInvoicesScreen(
              key: const ValueKey('invoices_populated'),
              dependencies: deps,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('INV-001'), findsOneWidget);
        expect(find.text('Wayne Tech'), findsOneWidget);
        expect(find.text('DRAFT'), findsOneWidget);
      },
    );

    testWidgets(
      'MobilePaymentsScreen renders empty state then recorded payment',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          CupertinoApp(
            home: MobilePaymentsScreen(
              key: const ValueKey('payments_empty'),
              dependencies: deps,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Payments'), findsWidgets);
        expect(find.text('No Payments Yet'), findsOneWidget);

        // Seed a client and a payment
        final client = Client.create(name: 'LexCorp', phone: '99999');
        await deps.clientRepository.add(client);

        final payment = Payment.create(
          clientId: client.id,
          amount: Money(15000, Currency.dzd),
          receivedAt: DateTime.now(),
          notes: 'Advance deposit',
        );
        await deps.paymentRepository.add(payment);

        await tester.pumpWidget(
          CupertinoApp(
            home: MobilePaymentsScreen(
              key: const ValueKey('payments_populated'),
              dependencies: deps,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('LexCorp'), findsOneWidget);
        expect(find.text('Advance deposit'), findsOneWidget);
      },
    );

    testWidgets('MobileSettingsScreen renders preferences and stats', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        CupertinoApp(home: MobileSettingsScreen(dependencies: deps)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsWidgets);
      expect(find.text('Appearance'), findsOneWidget);
      expect(find.text('Primary Currency'), findsOneWidget);
      expect(find.text('Management Tools'), findsOneWidget);
      expect(find.text('Financial Overview'), findsOneWidget);
      expect(find.text('Payment Allocations'), findsOneWidget);
      expect(find.text('Offline Sync Diagnostics'), findsOneWidget);
      expect(find.text('Offline Storage Stats'), findsOneWidget);
      expect(find.text('Database Schema'), findsOneWidget);
    });

    testWidgets('MobileFinancialScreen renders portfolio metrics', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        CupertinoApp(home: MobileFinancialScreen(dependencies: deps)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Financial Overview'), findsOneWidget);
      expect(find.text('Total Debt'), findsOneWidget);
      expect(find.text('Client Credit'), findsOneWidget);
      expect(find.text('Net Position'), findsOneWidget);
    });

    testWidgets('MobileAllocationsScreen renders empty state', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        CupertinoApp(home: MobileAllocationsScreen(dependencies: deps)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Payment Allocations'), findsOneWidget);
      expect(find.text('No Allocations Yet'), findsOneWidget);
    });
  });
}
