import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child, {Brightness brightness = Brightness.light}) {
  return CupertinoApp(
    theme: brightness == Brightness.dark
        ? AppTheme.cupertinoDark
        : AppTheme.cupertinoLight,
    home: CupertinoPageScaffold(child: Center(child: child)),
  );
}

void main() {
  group('Design System Reusable Components', () {
    testWidgets('AppButton invokes onPressed when tapped and enabled', (
      tester,
    ) async {
      var pressed = false;

      await tester.pumpWidget(
        _wrap(AppButton(text: 'Save Client', onPressed: () => pressed = true)),
      );

      expect(find.text('Save Client'), findsOneWidget);
      await tester.tap(find.text('Save Client'));
      await tester.pump();

      expect(pressed, isTrue);
    });

    testWidgets(
      'AppButton displays activity indicator when isLoading is true',
      (tester) async {
        await tester.pumpWidget(
          _wrap(const AppButton(text: 'Saving', isLoading: true)),
        );

        expect(find.byType(CupertinoActivityIndicator), findsOneWidget);
      },
    );

    testWidgets('AppSearchField inputs text and handles clear action', (
      tester,
    ) async {
      String lastQuery = '';
      final controller = TextEditingController();

      await tester.pumpWidget(
        _wrap(
          AppSearchField(
            controller: controller,
            placeholder: 'Search test...',
            onChanged: (q) => lastQuery = q,
          ),
        ),
      );

      expect(find.text('Search test...'), findsOneWidget);

      await tester.enterText(find.byType(CupertinoTextField), 'Acme');
      await tester.pump();

      expect(lastQuery, 'Acme');
      expect(controller.text, 'Acme');

      // Clear button should be visible
      final clearButton = find.byIcon(CupertinoIcons.clear_thick_circled);
      expect(clearButton, findsOneWidget);

      await tester.tap(clearButton);
      await tester.pump();

      expect(controller.text, '');
      expect(lastQuery, '');
    });

    testWidgets(
      'AppEmptyState displays title, description, and action button',
      (tester) async {
        var actionTriggered = false;

        await tester.pumpWidget(
          _wrap(
            AppEmptyState(
              icon: CupertinoIcons.person_2,
              title: 'No Clients Yet',
              description: 'Add your first client to start managing debts.',
              actionLabel: 'Add Client',
              onAction: () => actionTriggered = true,
            ),
          ),
        );

        expect(find.text('No Clients Yet'), findsOneWidget);
        expect(
          find.text('Add your first client to start managing debts.'),
          findsOneWidget,
        );
        expect(find.text('Add Client'), findsOneWidget);

        await tester.tap(find.text('Add Client'));
        await tester.pump();

        expect(actionTriggered, isTrue);
      },
    );

    testWidgets('ClientListRow computes initials and triggers onTap callback', (
      tester,
    ) async {
      var tapped = false;
      final client = Client.create(
        name: 'Alpha Beta Solutions',
        phone: '+213 555 12 34',
        notes: 'Priority client',
      );

      await tester.pumpWidget(
        _wrap(ClientListRow(client: client, onTap: () => tapped = true)),
      );

      // Initials should be AB
      expect(find.text('AB'), findsOneWidget);
      expect(find.text('Alpha Beta Solutions'), findsOneWidget);
      expect(find.text('+213 555 12 34'), findsOneWidget);
      expect(find.text('Priority client'), findsOneWidget);

      await tester.tap(find.text('Alpha Beta Solutions'));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets(
      'ClientSelectDialog renders clients, filters search, and selects client on tap',
      (tester) async {
        final clientA = Client.create(
          name: 'Alpha Systems',
          phone: '+213 555 11 11',
        );
        final clientB = Client.create(
          name: 'Beta Logistics',
          phone: '+213 555 22 22',
        );

        Client? selected;

        await tester.pumpWidget(
          CupertinoApp(
            home: CupertinoPageScaffold(
              child: Builder(
                builder: (context) => CupertinoButton(
                  child: const Text('Open Picker'),
                  onPressed: () async {
                    selected = await ClientSelectDialog.show(
                      context: context,
                      clients: [clientA, clientB],
                    );
                  },
                ),
              ),
            ),
          ),
        );

        // Open picker
        await tester.tap(find.text('Open Picker'));
        await tester.pumpAndSettle();

        // Both clients rendered with initials
        expect(find.text('Alpha Systems'), findsOneWidget);
        expect(find.text('Beta Logistics'), findsOneWidget);
        expect(find.text('AS'), findsOneWidget);
        expect(find.text('BL'), findsOneWidget);

        // Search filtering
        await tester.enterText(find.byType(CupertinoTextField), 'Beta');
        await tester.pumpAndSettle();

        expect(find.text('Alpha Systems'), findsNothing);
        expect(find.text('Beta Logistics'), findsOneWidget);

        // Click to select
        await tester.tap(find.text('Beta Logistics'));
        await tester.pumpAndSettle();

        // Dialog closed and client returned
        expect(find.text('Select Client'), findsNothing);
        expect(selected, isNotNull);
        expect(selected?.id, equals(clientB.id));
      },
    );

    testWidgets(
      'DesktopSidebar renders clean value badges and toggles between expanded and collapsed states',
      (tester) async {
        bool? collapsedState;
        int selectedIdx = 0;

        await tester.pumpWidget(
          CupertinoApp(
            home: CupertinoPageScaffold(
              child: Row(
                children: [
                  DesktopSidebar(
                    selectedIndex: selectedIdx,
                    onDestinationSelected: (idx) => selectedIdx = idx,
                    onCollapsedChanged: (collapsed) =>
                        collapsedState = collapsed,
                    destinations: const [
                      NavigationDestinationItem(
                        label: 'Dashboard',
                        icon: CupertinoIcons.square_grid_2x2,
                        activeIcon: CupertinoIcons.square_grid_2x2_fill,
                        valueLabel: 'Live',
                        section: 'Overview',
                      ),
                      NavigationDestinationItem(
                        label: 'Clients',
                        icon: CupertinoIcons.person_2,
                        activeIcon: CupertinoIcons.person_2_fill,
                        badgeCount: 14,
                        section: 'Operations',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );

        // Expanded by default: labels and values are visible
        expect(find.text('Debt Manager'), findsOneWidget);
        expect(find.text('Dashboard'), findsOneWidget);
        expect(find.text('Clients'), findsOneWidget);
        expect(find.text('Live'), findsOneWidget);
        expect(find.text('14'), findsOneWidget);

        // Click collapse button
        final toggleBtn = find.byKey(const ValueKey('sidebar_toggle_button'));
        expect(toggleBtn, findsOneWidget);
        await tester.tap(toggleBtn);
        await tester.pumpAndSettle();

        expect(collapsedState, isTrue);
        // In collapsed rail mode, text labels hide while value badges remain visible
        expect(find.text('Debt Manager'), findsNothing);
        expect(find.text('14'), findsOneWidget);

        // Click expand button again
        await tester.tap(toggleBtn);
        await tester.pumpAndSettle();

        expect(collapsedState, isFalse);
        expect(find.text('Debt Manager'), findsOneWidget);
      },
    );

    testWidgets(
      'InvoicePrintPreviewDialog opens in View Mode first and supports Download PDF and Print Invoice',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final client = Client.create(
          name: 'Stark Industries',
          phone: '+1 555 9000',
        );
        final invoice = Invoice.create(
          number: 'INV-PDF-100',
          clientId: client.id,
          currency: Currency.dzd,
          lines: [
            InvoiceLine.create(
              description: 'Arc Reactor Maintenance',
              quantity: 2,
              unitPrice: Money(15000, Currency.dzd),
            ),
          ],
        );

        // Verify pure-Dart PDF bytes header
        final pdfBytes = InvoicePdfGenerator.generatePdfBytes(
          invoice: invoice,
          client: client,
          preparedByUser: 'Tony',
          preparedByRole: 'Admin',
        );
        expect(String.fromCharCodes(pdfBytes.take(8)), equals('%PDF-1.4'));

        await tester.pumpWidget(
          CupertinoApp(
            home: CupertinoPageScaffold(
              child: InvoicePrintPreviewDialog(
                invoice: invoice,
                client: client,
                printedByUser: 'Tony',
                printedByRole: 'Admin',
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Starts in View Mode first with A4 Document preview
        expect(find.text('VIEW MODE'), findsOneWidget);
        expect(find.text('A4 Document'), findsOneWidget);
        expect(find.text('Receipt View'), findsOneWidget);
        expect(find.text('Stark Industries'), findsOneWidget);
        expect(find.text('Arc Reactor Maintenance'), findsOneWidget);

        // Both Download PDF and Print Invoice buttons are available
        final downloadBtn = find.byKey(
          const ValueKey('download_invoice_pdf_button'),
        );
        final printBtn = find.byKey(
          const ValueKey('print_invoice_action_button'),
        );
        expect(downloadBtn, findsOneWidget);
        expect(printBtn, findsOneWidget);

        // Switch to Receipt View
        await tester.tap(find.text('Receipt View'));
        await tester.pumpAndSettle();
        expect(find.text('DEBT MANAGER RECEIPT'), findsOneWidget);
      },
    );
  });
}
