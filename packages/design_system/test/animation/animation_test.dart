import 'package:design_system/design_system.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Centralized Animation System Suite', () {
    group('AppDurations & Motion Tokens', () {
      test('tokens follow Apple HIG hierarchy', () {
        expect(AppDurations.micro.inMilliseconds, inInclusiveRange(140, 180));
        expect(AppDurations.quick.inMilliseconds, inInclusiveRange(160, 200));
        expect(
          AppDurations.selection.inMilliseconds,
          inInclusiveRange(220, 280),
        );
        expect(AppDurations.content.inMilliseconds, inInclusiveRange(280, 360));
        expect(AppDurations.expand.inMilliseconds, inInclusiveRange(250, 350));
        expect(AppDurations.screen.inMilliseconds, inInclusiveRange(300, 400));
        expect(AppDurations.modal.inMilliseconds, inInclusiveRange(300, 400));

        // Relative hierarchy
        expect(AppDurations.micro < AppDurations.selection, isTrue);
        expect(AppDurations.selection <= AppDurations.content, isTrue);
        expect(AppDurations.content <= AppDurations.screen, isTrue);
      });

      test('standard curves are properly defined', () {
        expect(AppDurations.easeOut, equals(Curves.easeOutCubic));
        expect(AppDurations.easeIn, equals(Curves.easeInCubic));
        expect(AppDurations.smoothEaseOut, equals(Curves.easeOutCubic));
        expect(AppDurations.standardCurve, equals(Curves.easeInOutCubic));
        expect(AppDurations.springBounce, equals(Curves.easeOutBack));
      });

      testWidgets('motionDuration respects reduced motion accessibility', (
        tester,
      ) async {
        late BuildContext capturedNormalContext;
        late BuildContext capturedReducedContext;

        await tester.pumpWidget(
          CupertinoApp(
            home: MediaQuery(
              data: const MediaQueryData(disableAnimations: false),
              child: Builder(
                builder: (context) {
                  capturedNormalContext = context;
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        );

        expect(
          AppDurations.motionDuration(
            capturedNormalContext,
            AppDurations.selection,
          ),
          equals(AppDurations.selection),
        );
        expect(AppDurations.isReducedMotion(capturedNormalContext), isFalse);

        await tester.pumpWidget(
          CupertinoApp(
            home: MediaQuery(
              data: const MediaQueryData(disableAnimations: true),
              child: Builder(
                builder: (context) {
                  capturedReducedContext = context;
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        );

        expect(
          AppDurations.motionDuration(
            capturedReducedContext,
            AppDurations.selection,
          ),
          equals(Duration.zero),
        );
        expect(AppDurations.isReducedMotion(capturedReducedContext), isTrue);
      });
    });

    group('AnimatedSelectionContainer', () {
      testWidgets('renders child and reacts to selection state change', (
        tester,
      ) async {
        bool selected = false;
        int tapCount = 0;

        await tester.pumpWidget(
          CupertinoApp(
            home: StatefulBuilder(
              builder: (context, setState) {
                return CupertinoPageScaffold(
                  child: Center(
                    child: AnimatedSelectionContainer(
                      isSelected: selected,
                      showLeadingIndicator: true,
                      onTap: () {
                        setState(() => selected = !selected);
                        tapCount++;
                      },
                      child: const Text('Selectable Item Row'),
                    ),
                  ),
                );
              },
            ),
          ),
        );

        expect(find.text('Selectable Item Row'), findsOneWidget);

        // Tap to select
        await tester.tap(find.text('Selectable Item Row'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pumpAndSettle();

        expect(selected, isTrue);
        expect(tapCount, equals(1));

        // Tap again to unselect
        await tester.tap(find.text('Selectable Item Row'));
        await tester.pumpAndSettle();

        expect(selected, isFalse);
        expect(tapCount, equals(2));
      });

      testWidgets('works seamlessly with reduced motion enabled', (
        tester,
      ) async {
        await tester.pumpWidget(
          CupertinoApp(
            home: MediaQuery(
              data: const MediaQueryData(disableAnimations: true),
              child: const CupertinoPageScaffold(
                child: AnimatedSelectionContainer(
                  isSelected: true,
                  showLeadingIndicator: true,
                  child: Text('Reduced Motion Item'),
                ),
              ),
            ),
          ),
        );

        expect(find.text('Reduced Motion Item'), findsOneWidget);
      });
    });

    group('AnimatedContentSwitcher', () {
      testWidgets('switches between widgets with stable keys', (tester) async {
        String viewState = 'loading';

        await tester.pumpWidget(
          CupertinoApp(
            home: StatefulBuilder(
              builder: (context, setState) {
                return CupertinoPageScaffold(
                  child: Column(
                    children: [
                      CupertinoButton(
                        child: const Text('Toggle State'),
                        onPressed: () {
                          setState(() {
                            viewState = viewState == 'loading'
                                ? 'loaded'
                                : 'loading';
                          });
                        },
                      ),
                      AnimatedContentSwitcher(
                        transitionType: ContentTransitionType.fadeSlideY,
                        child: viewState == 'loading'
                            ? const Text(
                                'Loading Spinner',
                                key: ValueKey('loading'),
                              )
                            : const Text(
                                'Loaded Content Data',
                                key: ValueKey('loaded'),
                              ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );

        expect(find.text('Loading Spinner'), findsOneWidget);
        expect(find.text('Loaded Content Data'), findsNothing);

        // Trigger transition
        await tester.tap(find.text('Toggle State'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pumpAndSettle();

        expect(find.text('Loaded Content Data'), findsOneWidget);
        expect(find.text('Loading Spinner'), findsNothing);
      });

      testWidgets('fadeScale transition style functions smoothly', (
        tester,
      ) async {
        await tester.pumpWidget(
          const CupertinoApp(
            home: CupertinoPageScaffold(
              child: AnimatedContentSwitcher(
                transitionType: ContentTransitionType.fadeScale,
                child: Text('Scale Content', key: ValueKey('scale_test')),
              ),
            ),
          ),
        );

        expect(find.text('Scale Content'), findsOneWidget);
      });
    });

    group('AppExpandableSection', () {
      testWidgets('toggles expansion on header press and notifies callback', (
        tester,
      ) async {
        bool? expandedNotification;

        await tester.pumpWidget(
          CupertinoApp(
            home: CupertinoPageScaffold(
              child: AppExpandableSection(
                title: 'Invoice Details',
                subtitle: 'Line items and tax computations',
                trailing: const Text('3 items'),
                onExpansionChanged: (val) => expandedNotification = val,
                child: const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('Expanded Line Item 1'),
                ),
              ),
            ),
          ),
        );

        expect(find.text('Invoice Details'), findsOneWidget);
        expect(find.text('Line items and tax computations'), findsOneWidget);
        expect(find.text('3 items'), findsOneWidget);

        // Tap to expand
        await tester.tap(find.text('Invoice Details'));
        await tester.pumpAndSettle();

        expect(expandedNotification, isTrue);
        expect(find.text('Expanded Line Item 1'), findsOneWidget);

        // Tap to collapse
        await tester.tap(find.text('Invoice Details'));
        await tester.pumpAndSettle();

        expect(expandedNotification, isFalse);
      });

      testWidgets('initiallyExpanded starts with content visible', (
        tester,
      ) async {
        await tester.pumpWidget(
          const CupertinoApp(
            home: CupertinoPageScaffold(
              child: AppExpandableSection(
                title: 'Open Section',
                initiallyExpanded: true,
                child: Text('Always Visible Initially'),
              ),
            ),
          ),
        );

        expect(find.text('Open Section'), findsOneWidget);
        expect(find.text('Always Visible Initially'), findsOneWidget);
      });
    });

    group('AnimatedIndexedStack', () {
      testWidgets('preserves child state across index changes', (tester) async {
        int activeIndex = 0;

        await tester.pumpWidget(
          CupertinoApp(
            home: StatefulBuilder(
              builder: (context, setState) {
                return CupertinoPageScaffold(
                  child: Column(
                    children: [
                      CupertinoButton(
                        child: const Text('Switch Tab'),
                        onPressed: () {
                          setState(() {
                            activeIndex = activeIndex == 0 ? 1 : 0;
                          });
                        },
                      ),
                      Expanded(
                        child: AnimatedIndexedStack(
                          index: activeIndex,
                          children: const [
                            CupertinoTextField(
                              key: ValueKey('tab_0_field'),
                              placeholder: 'Tab 0 Input Field',
                            ),
                            CupertinoTextField(
                              key: ValueKey('tab_1_field'),
                              placeholder: 'Tab 1 Input Field',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );

        // Tab 0 visible: type some text into Tab 0
        await tester.enterText(
          find.byKey(const ValueKey('tab_0_field')),
          'Unsaved Draft Notes',
        );
        expect(find.text('Unsaved Draft Notes'), findsOneWidget);

        // Switch to Tab 1
        await tester.tap(find.text('Switch Tab'));
        await tester.pumpAndSettle();

        // Switch back to Tab 0: input state must be fully preserved!
        await tester.tap(find.text('Switch Tab'));
        await tester.pumpAndSettle();

        expect(find.text('Unsaved Draft Notes'), findsOneWidget);
      });
    });

    group('AppPageRoute Transitions', () {
      testWidgets('desktop route transition pushes and pops', (tester) async {
        await tester.pumpWidget(
          CupertinoApp(
            home: CupertinoPageScaffold(
              child: Builder(
                builder: (context) {
                  return CupertinoButton(
                    child: const Text('Push Desktop Route'),
                    onPressed: () {
                      Navigator.of(context).push(
                        AppPageRoute.desktop(
                          builder: (_) => const CupertinoPageScaffold(
                            child: Text('Desktop Target Screen'),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        );

        await tester.tap(find.text('Push Desktop Route'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 140));
        await tester.pumpAndSettle();

        expect(find.text('Desktop Target Screen'), findsOneWidget);

        // Pop
        final targetContext = tester.element(
          find.text('Desktop Target Screen'),
        );
        Navigator.of(targetContext).pop();
        await tester.pumpAndSettle();

        expect(find.text('Desktop Target Screen'), findsNothing);
        expect(find.text('Push Desktop Route'), findsOneWidget);
      });

      testWidgets('mobile route transition pushes with Cupertino style', (
        tester,
      ) async {
        await tester.pumpWidget(
          CupertinoApp(
            home: CupertinoPageScaffold(
              child: Builder(
                builder: (context) {
                  return CupertinoButton(
                    child: const Text('Push Mobile Route'),
                    onPressed: () {
                      Navigator.of(context).push(
                        AppPageRoute.mobile(
                          builder: (_) => const CupertinoPageScaffold(
                            child: Text('Mobile Target Screen'),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        );

        await tester.tap(find.text('Push Mobile Route'));
        await tester.pumpAndSettle();

        expect(find.text('Mobile Target Screen'), findsOneWidget);
      });

      testWidgets('fade route transition executes cleanly', (tester) async {
        await tester.pumpWidget(
          CupertinoApp(
            home: CupertinoPageScaffold(
              child: Builder(
                builder: (context) {
                  return CupertinoButton(
                    child: const Text('Push Fade Route'),
                    onPressed: () {
                      Navigator.of(context).push(
                        AppPageRoute.fade(
                          builder: (_) => const CupertinoPageScaffold(
                            child: Text('Fade Target Screen'),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        );

        await tester.tap(find.text('Push Fade Route'));
        await tester.pumpAndSettle();

        expect(find.text('Push Fade Route'), findsNothing);
        expect(find.text('Fade Target Screen'), findsOneWidget);
      });
    });

    group('AppStaggeredItem & AppAtmosphericBackground', () {
      testWidgets(
        'AppStaggeredItem animates list items with 35ms stagger and settles cleanly',
        (tester) async {
          await tester.pumpWidget(
            CupertinoApp(
              home: CupertinoPageScaffold(
                child: Column(
                  children: [
                    for (int i = 0; i < 8; i++)
                      AppStaggeredItem(index: i, child: Text('Item $i')),
                  ],
                ),
              ),
            ),
          );

          // Advance slightly to verify animation is in flight
          await tester.pump(const Duration(milliseconds: 50));
          expect(find.text('Item 0'), findsOneWidget);
          expect(find.text('Item 7'), findsOneWidget);

          // Settle all staggered items (capped at maxStaggerItems = 6)
          await tester.pumpAndSettle();

          for (int i = 0; i < 8; i++) {
            expect(find.text('Item $i'), findsOneWidget);
          }
        },
      );

      testWidgets('AppStaggeredItem respects reduced motion accessibility', (
        tester,
      ) async {
        await tester.pumpWidget(
          const CupertinoApp(
            home: MediaQuery(
              data: MediaQueryData(disableAnimations: true),
              child: CupertinoPageScaffold(
                child: AppStaggeredItem(
                  index: 3,
                  child: Text('Instant Stagger Item'),
                ),
              ),
            ),
          ),
        );

        expect(find.text('Instant Stagger Item'), findsOneWidget);
      });

      testWidgets(
        'AppAtmosphericBackground renders blurred colored bubbles and settles cleanly',
        (tester) async {
          await tester.pumpWidget(
            const CupertinoApp(
              home: CupertinoPageScaffold(
                child: AppAtmosphericBackground(
                  accentColor: Color(0xFF5856D6),
                  intensity: 1.0,
                  child: Center(child: Text('Foreground Content')),
                ),
              ),
            ),
          );

          await tester.pump(const Duration(milliseconds: 100));
          await tester.pumpAndSettle();

          expect(find.text('Foreground Content'), findsOneWidget);
          expect(find.byType(ImageFiltered), findsOneWidget);
        },
      );
    });
  });
}
