import 'package:application/application.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart' show ThemeMode, ValueNotifier;
import 'package:synco/synco.dart';

import '../features/auth/view_models/auth_view_model.dart';

/// Central dependency container providing repository contracts, CQRS use cases,
/// and JWT + Role-Based Access Control (RBAC) state.
///
/// Keeps presentation and ViewModels completely detached from SQLite/Drift infrastructure.
class AppDependencies {
  AppDependencies({
    required this.clientRepository,
    required this.invoiceRepository,
    required this.paymentRepository,
    required this.paymentAllocationRepository,
    required this.syncOutboxRepository,
    required this.unitOfWork,
    UserRepository? userRepository,
    RoleRepository? roleRepository,
    this.jwtService = const JwtService(),
    AuthViewModel? authViewModel,
    CreateClient? createClient,
    UpdateClient? updateClient,
    CreateInvoice? createInvoice,
    UpdateInvoiceDraft? updateInvoiceDraft,
    IssueInvoice? issueInvoice,
    RecordPayment? recordPayment,
    AllocatePayment? allocatePayment,
    GetClientFinancialPosition? getClientFinancialPosition,
    GetDashboardSummary? getDashboardSummary,
  }) : userRepository = userRepository ?? InMemoryUserRepository(),
       roleRepository = roleRepository ?? InMemoryRoleRepository(),
       createClient = createClient ?? CreateClient(clientRepository),
       updateClient = updateClient ?? UpdateClient(clientRepository),
       createInvoice =
           createInvoice ??
           CreateInvoice(
             invoiceRepository: invoiceRepository,
             clientRepository: clientRepository,
           ),
       updateInvoiceDraft =
           updateInvoiceDraft ??
           UpdateInvoiceDraft(
             clientRepository: clientRepository,
             invoiceRepository: invoiceRepository,
           ),
       issueInvoice = issueInvoice ?? IssueInvoice(invoiceRepository),
       recordPayment =
           recordPayment ??
           RecordPayment(
             paymentRepository: paymentRepository,
             clientRepository: clientRepository,
           ),
       allocatePayment = allocatePayment ?? AllocatePayment(unitOfWork),
       getClientFinancialPosition =
           getClientFinancialPosition ??
           GetClientFinancialPosition(
             clientRepository: clientRepository,
             invoiceRepository: invoiceRepository,
             paymentRepository: paymentRepository,
             paymentAllocationRepository: paymentAllocationRepository,
           ),
       getDashboardSummary =
           getDashboardSummary ??
           GetDashboardSummary(
             clientRepository: clientRepository,
             invoiceRepository: invoiceRepository,
             paymentRepository: paymentRepository,
             paymentAllocationRepository: paymentAllocationRepository,
           ) {
    this.authViewModel =
        authViewModel ??
        AuthViewModel(
          userRepository: this.userRepository,
          roleRepository: this.roleRepository,
          jwtService: jwtService,
        );
  }

  final ClientRepository clientRepository;
  final InvoiceRepository invoiceRepository;
  final PaymentRepository paymentRepository;
  final PaymentAllocationRepository paymentAllocationRepository;
  final SyncOutboxRepository syncOutboxRepository;
  final UnitOfWork unitOfWork;
  final UserRepository userRepository;
  final RoleRepository roleRepository;
  final JwtService jwtService;
  late final AuthViewModel authViewModel;

  final CreateClient createClient;
  final UpdateClient updateClient;
  final CreateInvoice createInvoice;
  final UpdateInvoiceDraft updateInvoiceDraft;
  final IssueInvoice issueInvoice;
  final RecordPayment recordPayment;
  final AllocatePayment allocatePayment;
  final GetClientFinancialPosition getClientFinancialPosition;
  final GetDashboardSummary getDashboardSummary;

  /// Reactive revision notifier firing whenever database records change.
  final ValueNotifier<int> dataRevision = ValueNotifier<int>(0);

  /// Reactive theme mode notifier enabling live Light/Dark/System switching.
  final ValueNotifier<ThemeMode> themeMode = ValueNotifier<ThemeMode>(
    ThemeMode.system,
  );

  /// Reactive primary currency notifier across screens.
  final ValueNotifier<Currency> primaryCurrency = ValueNotifier<Currency>(
    Currency.dzd,
  );

  /// Broadcasts a data change event across all active screens and ViewModels.
  void notifyDataChanged() {
    dataRevision.value++;
  }

  /// Checks whether the current JWT session and role grant [permission].
  ///
  /// When a user session is active, strictly enforces the JWT & Role permissions.
  /// When no session is active (e.g., standalone screen tests that bypass the root
  /// auth gate), returns `true` for backwards-compatible widget testing.
  bool hasPermission(AppPermission permission) {
    if (!authViewModel.isAuthenticated) {
      return true;
    }
    return authViewModel.hasPermission(permission);
  }
}
