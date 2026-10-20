import 'package:application/application.dart';
import 'package:data/data.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/cupertino.dart';

import 'features/clients/screens/mobile_clients_screen.dart';
import 'features/invoices/screens/mobile_invoices_screen.dart';
import 'features/payments/screens/mobile_payments_screen.dart';
import 'features/settings/screens/mobile_settings_screen.dart';

/// Helper to instantiate AppDependencies backed by SQLite or fake overrides.
AppDependencies createMobileAppDependenciesFromDb(
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

/// The root mobile application shell with JWT Authentication gate, Role-Based
/// Access Control (RBAC), and iOS Cupertino tab scaffold.
class MobileApp extends StatefulWidget {
  const MobileApp({
    super.key,
    this.dependencies,
    this.repository,
    this.requireAuth,
  });

  /// Injected application dependencies.
  final AppDependencies? dependencies;

  /// Injected client repository for backwards-compatible test fixtures.
  final ClientRepository? repository;

  /// Whether to enforce the JWT Login / First-Account Setup gate.
  /// Defaults to `true` when [repository] is null.
  final bool? requireAuth;

  @override
  State<MobileApp> createState() => _MobileAppState();
}

class _MobileAppState extends State<MobileApp> {
  late final AppDependencies _dependencies;
  late final bool _requireAuth;
  late final CupertinoTabController _tabController;

  int _clientCount = 0;
  int _invoiceCount = 0;
  int _paymentCount = 0;

  @override
  void initState() {
    super.initState();
    if (widget.dependencies != null) {
      _dependencies = widget.dependencies!;
    } else if (widget.repository != null) {
      final db = AppDatabase.inMemory();
      _dependencies = createMobileAppDependenciesFromDb(
        db,
        clientOverride: widget.repository,
      );
    } else {
      final db = AppDatabase.defaults();
      _dependencies = createMobileAppDependenciesFromDb(db);
    }

    _requireAuth = widget.requireAuth ?? (widget.repository == null);

    if (!_requireAuth && !_dependencies.authViewModel.isAuthenticated) {
      _dependencies.authViewModel.bootstrapTestAdminSession();
    } else if (_requireAuth && !_dependencies.authViewModel.isAuthenticated) {
      _dependencies.authViewModel.initialize();
    }

    _tabController = CupertinoTabController();
    _tabController.addListener(() {
      _dependencies.notifyDataChanged();
    });

    _dependencies.dataRevision.addListener(_loadTabMetrics);
    _dependencies.primaryCurrency.addListener(_onCurrencyChanged);
    _loadTabMetrics();
  }

  @override
  void dispose() {
    _dependencies.dataRevision.removeListener(_loadTabMetrics);
    _dependencies.primaryCurrency.removeListener(_onCurrencyChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onCurrencyChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadTabMetrics() async {
    try {
      final clients = await _dependencies.clientRepository.getAll();
      final invoices = await _dependencies.invoiceRepository.getAll();
      final payments = await _dependencies.paymentRepository.getAll();
      if (!mounted) return;
      setState(() {
        _clientCount = clients.length;
        _invoiceCount = invoices.length;
        _paymentCount = payments.length;
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
        title: 'Debt Manager Mobile',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.cupertinoLight,
        home: ListenableBuilder(
          listenable: _dependencies.authViewModel,
          builder: (context, _) {
            final authVm = _dependencies.authViewModel;
            if (_requireAuth && !authVm.isAuthenticated) {
              return AuthScreen(authViewModel: authVm);
            }

            return MobileTabScaffold(
              controller: _tabController,
              tabs: [
                MobileTabItem(
                  label: 'Clients',
                  icon: CupertinoIcons.person_2,
                  activeIcon: CupertinoIcons.person_2_fill,
                  accentColor: const Color(0xFF0EA5E9),
                  badgeCount: _clientCount > 0 ? _clientCount : null,
                  builder: (context) => MobileClientsScreen(
                    dependencies: _dependencies,
                    repository: _dependencies.clientRepository,
                  ),
                ),
                MobileTabItem(
                  label: 'Invoices',
                  icon: CupertinoIcons.doc_text,
                  activeIcon: CupertinoIcons.doc_text_fill,
                  accentColor: const Color(0xFF6366F1),
                  badgeCount: _invoiceCount > 0 ? _invoiceCount : null,
                  builder: (context) =>
                      MobileInvoicesScreen(dependencies: _dependencies),
                ),
                MobileTabItem(
                  label: 'Payments',
                  icon: CupertinoIcons.arrow_down_circle,
                  activeIcon: CupertinoIcons.arrow_down_circle_fill,
                  accentColor: const Color(0xFF10B981),
                  badgeCount: _paymentCount > 0 ? _paymentCount : null,
                  builder: (context) =>
                      MobilePaymentsScreen(dependencies: _dependencies),
                ),
                MobileTabItem(
                  label: 'Settings',
                  icon: CupertinoIcons.slider_horizontal_3,
                  activeIcon: CupertinoIcons.gear_alt_fill,
                  accentColor: const Color(0xFF64748B),
                  badgeText: _dependencies.primaryCurrency.value.code,
                  builder: (context) =>
                      MobileSettingsScreen(dependencies: _dependencies),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
