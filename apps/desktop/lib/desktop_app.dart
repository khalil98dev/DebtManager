import 'package:application/application.dart';
import 'package:data/data.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/cupertino.dart';

import 'features/allocations/screens/desktop_allocations_screen.dart';
import 'features/clients/screens/desktop_clients_screen.dart';
import 'features/dashboard/screens/desktop_dashboard_screen.dart';
import 'features/financial/screens/desktop_financial_screen.dart';
import 'features/invoices/screens/desktop_invoices_screen.dart';
import 'features/payments/screens/desktop_payments_screen.dart';
import 'features/settings/screens/desktop_settings_screen.dart';
import 'features/sync_status/screens/desktop_sync_status_screen.dart';

/// Creates [AppDependencies] backed by Drift SQLite with optional repository overrides.
AppDependencies createAppDependenciesFromDb(
  AppDatabase db, {
  ClientRepository? clientOverride,
}) {
  final clientRepo = clientOverride ?? DriftClientRepository(db);
  final invoiceRepo = DriftInvoiceRepository(db);
  final paymentRepo = DriftPaymentRepository(db);
  final allocationRepo = DriftPaymentAllocationRepository(db);
  final outboxRepo = DriftSyncOutboxRepository(db);
  final uow = DriftUnitOfWork(db);
  final userRepo = DriftUserRepository(db);
  final roleRepo = DriftRoleRepository(db);

  return AppDependencies(
    clientRepository: clientRepo,
    invoiceRepository: invoiceRepo,
    paymentRepository: paymentRepo,
    paymentAllocationRepository: allocationRepo,
    syncOutboxRepository: outboxRepo,
    unitOfWork: uow,
    userRepository: userRepo,
    roleRepository: roleRepo,
  );
}

/// The root desktop application shell with JWT Authentication gate, Role-Based
/// Access Control (RBAC), and macOS-style closable sidebar navigation.
class DesktopApp extends StatefulWidget {
  const DesktopApp({
    super.key,
    this.dependencies,
    this.repository,
    this.initialDestinationIndex,
    this.requireAuth,
  });

  /// Injected application dependencies.
  final AppDependencies? dependencies;

  /// Injected client repository for backwards-compatible test fixtures.
  final ClientRepository? repository;

  /// Initial sidebar selection index (defaults to 1 if [repository] is provided, else 0).
  final int? initialDestinationIndex;

  /// Whether to enforce the JWT Login / First-Account Setup gate.
  /// Defaults to `true` when [repository] is null.
  final bool? requireAuth;

  @override
  State<DesktopApp> createState() => _DesktopAppState();
}

class _DesktopAppState extends State<DesktopApp> {
  late final AppDependencies _dependencies;
  late final bool _requireAuth;
  late int _selectedDestination;

  int _clientCount = 0;
  int _invoiceCount = 0;
  int _paymentCount = 0;
  int _allocationCount = 0;
  int _outboxCount = 0;

  @override
  void initState() {
    super.initState();
    if (widget.dependencies != null) {
      _dependencies = widget.dependencies!;
    } else if (widget.repository != null) {
      final db = AppDatabase.inMemory();
      _dependencies = createAppDependenciesFromDb(
        db,
        clientOverride: widget.repository,
      );
    } else {
      final db = AppDatabase.defaults();
      _dependencies = createAppDependenciesFromDb(db);
    }

    _requireAuth = widget.requireAuth ?? (widget.repository == null);

    if (!_requireAuth && !_dependencies.authViewModel.isAuthenticated) {
      _dependencies.authViewModel.bootstrapTestAdminSession();
    } else if (_requireAuth && !_dependencies.authViewModel.isAuthenticated) {
      _dependencies.authViewModel.initialize();
    }

    _selectedDestination =
        widget.initialDestinationIndex ?? (widget.repository != null ? 1 : 0);

    _dependencies.dataRevision.addListener(_loadSidebarMetrics);
    _dependencies.primaryCurrency.addListener(_onCurrencyChanged);
    _loadSidebarMetrics();
  }

  @override
  void dispose() {
    _dependencies.dataRevision.removeListener(_loadSidebarMetrics);
    _dependencies.primaryCurrency.removeListener(_onCurrencyChanged);
    super.dispose();
  }

  void _onCurrencyChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadSidebarMetrics() async {
    try {
      final clients = await _dependencies.clientRepository.getAll();
      final invoices = await _dependencies.invoiceRepository.getAll();
      final payments = await _dependencies.paymentRepository.getAll();
      final allocations = await _dependencies.paymentAllocationRepository
          .getAll();
      final outbox = await _dependencies.syncOutboxRepository.getPending();
      if (!mounted) return;
      setState(() {
        _clientCount = clients.length;
        _invoiceCount = invoices.length;
        _paymentCount = payments.length;
        _allocationCount = allocations.length;
        _outboxCount = outbox.length;
      });
    } catch (_) {
      // Ignore transient repository errors during teardown
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      dependencies: _dependencies,
      child: CupertinoApp(
        title: 'Debt Manager Desktop',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.cupertinoLight,
        home: ListenableBuilder(
          listenable: _dependencies.authViewModel,
          builder: (context, _) {
            final authVm = _dependencies.authViewModel;
            if (_requireAuth && !authVm.isAuthenticated) {
              return AuthScreen(authViewModel: authVm);
            }

            final session = authVm.currentSession;
            final activeCurrency = _dependencies.primaryCurrency.value.code;

            return CupertinoPageScaffold(
              child: Row(
                children: [
                  // Closable macOS Sidebar with Clean Icons & Live Values
                  DesktopSidebar(
                    selectedIndex: _selectedDestination,
                    onDestinationSelected: (index) {
                      setState(() => _selectedDestination = index);
                      _dependencies.notifyDataChanged();
                    },
                    destinations: [
                      const NavigationDestinationItem(
                        label: 'Dashboard',
                        icon: CupertinoIcons.square_grid_2x2,
                        activeIcon: CupertinoIcons.square_grid_2x2_fill,
                        accentColor: Color(0xFF2563EB),
                        valueLabel: 'Live',
                        section: 'Overview',
                      ),
                      NavigationDestinationItem(
                        label: 'Clients',
                        icon: CupertinoIcons.person_2,
                        activeIcon: CupertinoIcons.person_2_fill,
                        accentColor: const Color(0xFF0EA5E9),
                        badgeCount: _clientCount,
                        section: 'Operations',
                      ),
                      NavigationDestinationItem(
                        label: 'Invoices',
                        icon: CupertinoIcons.doc_text,
                        activeIcon: CupertinoIcons.doc_text_fill,
                        accentColor: const Color(0xFF6366F1),
                        badgeCount: _invoiceCount,
                        section: 'Operations',
                      ),
                      NavigationDestinationItem(
                        label: 'Payments',
                        icon: CupertinoIcons.arrow_down_circle,
                        activeIcon: CupertinoIcons.arrow_down_circle_fill,
                        accentColor: const Color(0xFF10B981),
                        badgeCount: _paymentCount,
                        section: 'Operations',
                      ),
                      NavigationDestinationItem(
                        label: 'Allocations',
                        icon: CupertinoIcons.arrow_right_arrow_left_circle,
                        activeIcon:
                            CupertinoIcons.arrow_right_arrow_left_circle_fill,
                        accentColor: const Color(0xFFF59E0B),
                        badgeCount: _allocationCount,
                        section: 'Operations',
                      ),
                      NavigationDestinationItem(
                        label: 'Financials',
                        icon: CupertinoIcons.chart_pie,
                        activeIcon: CupertinoIcons.chart_pie_fill,
                        accentColor: const Color(0xFF8B5CF6),
                        valueLabel: activeCurrency,
                        section: 'Operations',
                      ),
                      NavigationDestinationItem(
                        label: 'Sync Status',
                        icon: CupertinoIcons.arrow_2_circlepath_circle,
                        activeIcon:
                            CupertinoIcons.arrow_2_circlepath_circle_fill,
                        accentColor: const Color(0xFF14B8A6),
                        badgeCount: _outboxCount,
                        section: 'System',
                      ),
                      NavigationDestinationItem(
                        label: 'Settings',
                        icon: CupertinoIcons.slider_horizontal_3,
                        activeIcon: CupertinoIcons.gear_alt_fill,
                        accentColor: const Color(0xFF64748B),
                        valueLabel: activeCurrency,
                        section: 'System',
                      ),
                    ],
                    collapsedFooter: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (session != null) ...[
                          AppIconButton(
                            icon: CupertinoIcons.square_arrow_right,
                            size: 32,
                            iconSize: 15,
                            isCircle: false,
                            tooltip:
                                'Sign Out (${session.user.displayName} · ${session.role.name})',
                            onPressed: authVm.logout,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                        ],
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.successLight,
                          ),
                        ),
                      ],
                    ),
                    footer: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (session != null) ...[
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      session.user.displayName,
                                      style: AppTypography.caption1.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimaryLight,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      'Role: ${session.role.name}',
                                      style: AppTypography.caption2.copyWith(
                                        color: AppColors.textSecondaryLight,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              AppIconButton(
                                icon: CupertinoIcons.square_arrow_right,
                                size: 26,
                                iconSize: 13,
                                tooltip: 'Sign Out',
                                onPressed: authVm.logout,
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xs),
                        ],
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.successLight,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Expanded(
                              child: Text(
                                'Offline Storage Active',
                                style: AppTypography.caption1.copyWith(
                                  color: AppColors.textSecondaryLight,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Active Screen Body with state-preserving smooth transitions
                  Expanded(
                    child: AnimatedIndexedStack(
                      index: _selectedDestination,
                      children: [
                        DesktopDashboardScreen(dependencies: _dependencies),
                        DesktopClientsScreen(
                          dependencies: _dependencies,
                          repository: _dependencies.clientRepository,
                        ),
                        DesktopInvoicesScreen(dependencies: _dependencies),
                        DesktopPaymentsScreen(dependencies: _dependencies),
                        DesktopAllocationsScreen(dependencies: _dependencies),
                        DesktopFinancialsScreen(dependencies: _dependencies),
                        DesktopSyncStatusScreen(dependencies: _dependencies),
                        DesktopSettingsScreen(dependencies: _dependencies),
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
  }
}
