import 'package:application/application.dart';
import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

/// Desktop-density Clients Overview screen.
///
/// Features:
/// - macOS toolbar with dynamic search field and quick "Add Client" CTA.
/// - Two-column split-view: dense client list on left, detailed client overview on right.
/// - Live Composite view for the selected client: real-time financial position,
///   invoices list, payments list, and integrated actions (New Invoice, Record Payment,
///   Allocate Funds, Edit Profile).
/// - Keyboard shortcuts support (Ctrl+F / Cmd+F to focus search).
/// - Atmospheric background and gradient accents.
class DesktopClientsScreen extends StatefulWidget {
  const DesktopClientsScreen({
    super.key,
    this.repository,
    this.dependencies,
    this.onAddClient,
  });

  final ClientRepository? repository;
  final AppDependencies? dependencies;
  final VoidCallback? onAddClient;

  @override
  State<DesktopClientsScreen> createState() => _DesktopClientsScreenState();
}

class _DesktopClientsScreenState extends State<DesktopClientsScreen> {
  late final ClientListViewModel _viewModel;
  late final FocusNode _searchFocusNode;
  Client? _selectedClient;

  ClientFinancialPosition? _financialPosition;
  List<Invoice> _clientInvoices = [];
  List<Payment> _clientPayments = [];
  bool _isLoadingComposite = false;

  AppDependencies? _resolveDeps() {
    return widget.dependencies ?? AppScope.maybeOf(context);
  }

  @override
  void initState() {
    super.initState();
    final repo = widget.repository ?? widget.dependencies?.clientRepository;
    assert(
      repo != null,
      'Either repository or dependencies must be provided to DesktopClientsScreen',
    );
    _viewModel = ClientListViewModel(repository: repo!);
    _searchFocusNode = FocusNode();
    _viewModel.loadClients();
  }

  AppDependencies? _subscribedDeps;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final deps = _resolveDeps();
    if (deps != _subscribedDeps) {
      _subscribedDeps?.dataRevision.removeListener(_onDataChanged);
      _subscribedDeps = deps;
      _subscribedDeps?.dataRevision.addListener(_onDataChanged);
    }
  }

  void _onDataChanged() {
    if (mounted) {
      _viewModel.refresh();
      if (_selectedClient != null) {
        _loadClientComposite(_selectedClient!);
      }
    }
  }

  @override
  void dispose() {
    _subscribedDeps?.dataRevision.removeListener(_onDataChanged);
    _viewModel.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onClientSelected(Client client) {
    setState(() {
      _selectedClient = client;
    });
    _loadClientComposite(client);
  }

  Future<void> _loadClientComposite(Client client) async {
    final deps = _resolveDeps();
    if (deps == null) return;

    setState(() => _isLoadingComposite = true);
    try {
      final posResult = await deps.getClientFinancialPosition.execute(
        GetClientFinancialPositionQuery(clientId: client.id),
      );
      final invoices = await deps.invoiceRepository.getByClientId(client.id);
      final payments = await deps.paymentRepository.getByClientId(client.id);

      if (mounted && _selectedClient?.id == client.id) {
        setState(() {
          _financialPosition = posResult.dataOrNull;
          _clientInvoices = invoices;
          _clientPayments = payments;
          _isLoadingComposite = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingComposite = false);
      }
    }
  }

  Future<void> _handleNewClient() async {
    if (widget.onAddClient != null) {
      widget.onAddClient!();
      return;
    }

    final deps = _resolveDeps();
    if (deps == null) return;

    final created = await ClientFormDialog.show(
      context,
      createClient: deps.createClient,
      updateClient: deps.updateClient,
    );

    if (created != null && mounted) {
      deps.notifyDataChanged();
      await _viewModel.refresh();
      _onClientSelected(created);
    }
  }

  Future<void> _handleEditProfile(Client client) async {
    final deps = _resolveDeps();
    if (deps == null) return;

    final updated = await ClientFormDialog.show(
      context,
      createClient: deps.createClient,
      updateClient: deps.updateClient,
      initialClient: client,
    );

    if (updated != null && mounted) {
      deps.notifyDataChanged();
      await _viewModel.refresh();
      _onClientSelected(updated);
    }
  }

  Future<void> _handleNewInvoice(Client client) async {
    final deps = _resolveDeps();
    if (deps == null) return;

    final created = await InvoiceFormDialog.show(
      context,
      clientRepository: deps.clientRepository,
      createInvoice: deps.createInvoice,
      updateInvoiceDraft: deps.updateInvoiceDraft,
      issueInvoice: deps.issueInvoice,
      createClient: deps.createClient,
      updateClient: deps.updateClient,
      preselectedClientId: client.id,
    );

    if (created != null && mounted) {
      deps.notifyDataChanged();
      await _loadClientComposite(client);
    }
  }

  Future<void> _handleRecordPayment(Client client) async {
    final deps = _resolveDeps();
    if (deps == null) return;

    final recorded = await PaymentFormDialog.show(
      context,
      clientRepository: deps.clientRepository,
      recordPayment: deps.recordPayment,
      createClient: deps.createClient,
      updateClient: deps.updateClient,
      preselectedClientId: client.id,
    );

    if (recorded != null && mounted) {
      deps.notifyDataChanged();
      await _loadClientComposite(client);
    }
  }

  Future<void> _handleAllocateFunds(Client client) async {
    final deps = _resolveDeps();
    if (deps == null) return;

    final allocated = await AllocationDialog.show(
      context,
      clientRepository: deps.clientRepository,
      invoiceRepository: deps.invoiceRepository,
      paymentRepository: deps.paymentRepository,
      paymentAllocationRepository: deps.paymentAllocationRepository,
      allocatePayment: deps.allocatePayment,
      preselectedClientId: client.id,
    );

    if (allocated != null && mounted) {
      deps.notifyDataChanged();
      await _loadClientComposite(client);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyF, control: true): () {
          _searchFocusNode.requestFocus();
        },
        const SingleActivator(LogicalKeyboardKey.keyF, meta: true): () {
          _searchFocusNode.requestFocus();
        },
      },
      child: Focus(
        autofocus: true,
        child: ListenableBuilder(
          listenable: _viewModel,
          builder: (context, _) {
            final state = _viewModel.state;

            // Auto-select first client on desktop if none selected
            if (_selectedClient == null && state.filteredClients.isNotEmpty) {
              final first = state.filteredClients.first;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && _selectedClient == null) {
                  _onClientSelected(first);
                }
              });
            } else if (_selectedClient != null &&
                !state.filteredClients.any(
                  (c) => c.id == _selectedClient!.id,
                )) {
              final fallback = state.filteredClients.firstOrNull;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  if (fallback != null) {
                    _onClientSelected(fallback);
                  } else {
                    setState(() => _selectedClient = null);
                  }
                }
              });
            }

            return AppAtmosphericBackground(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Desktop Toolbar & Header
                  AppPageHeader(
                    title: 'Clients',
                    subtitle:
                        'Manage client profiles, contact records, and debts',
                    badgeCount: state.isLoaded ? state.totalCount : null,
                    actions: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 280,
                          child: AppSearchField(
                            focusNode: _searchFocusNode,
                            placeholder: 'Search name or phone... (Ctrl+F)',
                            onChanged: _viewModel.search,
                            onClear: _viewModel.clearSearch,
                          ),
                        ),
                        if (_resolveDeps()?.hasPermission(
                              AppPermission.manageClients,
                            ) ??
                            true) ...[
                          const SizedBox(width: AppSpacing.sm),
                          AppButton(
                            text: 'New Client',
                            icon: const Icon(CupertinoIcons.plus),
                            onPressed: _handleNewClient,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const AppDivider(),

                  // Main Content Body
                  Expanded(child: _buildBody(context, state)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, ClientListViewState state) {
    if (state.isLoading) {
      return _buildLoadingSkeleton(context);
    }

    if (state.hasError) {
      return AppErrorState(
        message: state.errorMessage ?? 'An unexpected error occurred.',
        onRetry: _viewModel.refresh,
      );
    }

    if (state.isEmpty) {
      return AppEmptyState(
        icon: CupertinoIcons.person_2,
        title: 'No Clients Found',
        description:
            'You have not added any clients yet. Start by creating a client profile to track debts and invoices.',
        actionLabel: 'Create First Client',
        onAction: _handleNewClient,
      );
    }

    if (state.isSearchEmpty) {
      return AppEmptyState(
        icon: CupertinoIcons.search,
        title: 'No Matching Clients',
        description: 'No clients match "${state.searchQuery}".',
        actionLabel: 'Clear Search',
        onAction: _viewModel.clearSearch,
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Left Column: Client List
        SizedBox(
          width: 380,
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(
                  color: AppColors.separator(context),
                  width: 1.0,
                ),
              ),
            ),
            child: ListView.builder(
              itemCount: state.filteredClients.length,
              itemBuilder: (context, index) {
                final client = state.filteredClients[index];
                final isSelected = _selectedClient?.id == client.id;
                return AppStaggeredItem(
                  index: index,
                  child: ClientListRow(
                    client: client,
                    isSelected: isSelected,
                    onTap: () => _onClientSelected(client),
                    showDivider: index < state.filteredClients.length - 1,
                  ),
                );
              },
            ),
          ),
        ),

        // Right Column: Client Composite Detail Panel with smooth cross-fade
        Expanded(
          child: AnimatedContentSwitcher(
            transitionType: ContentTransitionType.fade,
            child: _selectedClient != null
                ? Container(
                    key: ValueKey('client_detail_${_selectedClient!.id.value}'),
                    child: _buildClientDetailPanel(context, _selectedClient!),
                  )
                : Center(
                    key: const ValueKey('no_client_selected'),
                    child: Text(
                      'Select a client to view details',
                      style: AppTypography.subheadline.copyWith(
                        color: AppColors.textTertiary(context),
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingSkeleton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: List.generate(
          5,
          (index) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: AppCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  const AppSkeleton(
                    width: 38,
                    height: 38,
                    borderRadius: BorderRadius.all(Radius.circular(19)),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        AppSkeleton(width: 160, height: 16),
                        SizedBox(height: AppSpacing.xs),
                        AppSkeleton(width: 100, height: 12),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildClientDetailPanel(BuildContext context, Client client) {
    final avatarGradient = AppGradients.avatarFor(client.name);
    final isDark = CupertinoTheme.maybeBrightnessOf(context) == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card with Gradient Avatar
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.surface(context),
              borderRadius: AppRadii.lgRadius,
              border: Border.all(
                color: AppColors.border(context).withValues(alpha: 0.6),
                width: 0.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: CupertinoColors.black.withValues(
                    alpha: isDark ? 0.2 : 0.03,
                  ),
                  blurRadius: 8.0,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: avatarGradient,
                    boxShadow: [
                      BoxShadow(
                        color: avatarGradient.colors.first.withValues(
                          alpha: 0.35,
                        ),
                        blurRadius: 8.0,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    client.name.substring(0, 1).toUpperCase(),
                    style: AppTypography.title1.copyWith(
                      color: CupertinoColors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        client.name,
                        style: AppTypography.title2.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary(context),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Row(
                        children: [
                          Icon(
                            CupertinoIcons.phone_fill,
                            size: 13,
                            color: AppColors.textTertiary(context),
                          ),
                          const SizedBox(width: AppSpacing.xxs),
                          Flexible(
                            child: Text(
                              client.phone ?? 'No phone number on record',
                              style: AppTypography.subheadline.copyWith(
                                color: AppColors.textSecondary(context),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Client since ${_formatDate(client.createdAt)}',
                        style: AppTypography.footnote.copyWith(
                          color: AppColors.textTertiary(context),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_resolveDeps()?.hasPermission(
                      AppPermission.manageClients,
                    ) ??
                    true)
                  AppButton(
                    text: 'Edit Profile',
                    size: AppButtonSize.compact,
                    variant: AppButtonVariant.secondary,
                    icon: const Icon(CupertinoIcons.pencil, size: 13),
                    onPressed: () => _handleEditProfile(client),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Financial Summary Section (Live Composite metrics)
          Row(
            children: [
              Text(
                'Financial Summary',
                style: AppTypography.headline.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary(context),
                ),
              ),
              if (_isLoadingComposite) ...[
                const SizedBox(width: AppSpacing.sm),
                const CupertinoActivityIndicator(radius: 7),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  context,
                  title: 'Outstanding Debt',
                  value: _financialPosition != null
                      ? _financialPosition!.outstandingDebt.format()
                      : '0.00 DZD',
                  subtitle: _financialPosition?.hasOutstandingDebt == true
                      ? 'Unpaid invoices due'
                      : 'No overdue balance',
                  variant: _financialPosition?.hasOutstandingDebt == true
                      ? AppBadgeVariant.destructive
                      : AppBadgeVariant.neutral,
                  tintColor: _financialPosition?.hasOutstandingDebt == true
                      ? AppColors.destructive(context)
                      : null,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _buildMetricCard(
                  context,
                  title: 'Unallocated Credit',
                  value: _financialPosition != null
                      ? _financialPosition!.unallocatedCredit.format()
                      : '0.00 DZD',
                  subtitle: _financialPosition?.hasUnallocatedCredit == true
                      ? 'Available to allocate'
                      : 'Available deposit',
                  variant: _financialPosition?.hasUnallocatedCredit == true
                      ? AppBadgeVariant.success
                      : AppBadgeVariant.neutral,
                  tintColor: _financialPosition?.hasUnallocatedCredit == true
                      ? AppColors.success(context)
                      : null,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _buildMetricCard(
                  context,
                  title: 'Total Invoiced',
                  value: _financialPosition != null
                      ? _financialPosition!.totalInvoiced.format()
                      : '0.00 DZD',
                  subtitle: 'Lifetime billed',
                  variant: AppBadgeVariant.neutral,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Actions & Operations
          Text(
            'Actions & Operations',
            style: AppTypography.headline.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary(context),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surface(context),
              borderRadius: AppRadii.mdRadius,
              border: Border.all(
                color: AppColors.border(context).withValues(alpha: 0.6),
                width: 0.8,
              ),
            ),
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                if (_resolveDeps()?.hasPermission(
                      AppPermission.manageInvoices,
                    ) ??
                    true)
                  AppButton(
                    text: 'New Invoice',
                    icon: const Icon(CupertinoIcons.doc_text_fill, size: 14),
                    variant: AppButtonVariant.primary,
                    size: AppButtonSize.compact,
                    onPressed: () => _handleNewInvoice(client),
                  ),
                if (_resolveDeps()?.hasPermission(
                      AppPermission.recordPayments,
                    ) ??
                    true)
                  AppButton(
                    text: 'Record Payment',
                    icon: const Icon(
                      CupertinoIcons.arrow_down_circle_fill,
                      size: 14,
                    ),
                    variant: AppButtonVariant.secondary,
                    size: AppButtonSize.compact,
                    onPressed: () => _handleRecordPayment(client),
                  ),
                if (_resolveDeps()?.hasPermission(
                      AppPermission.manageAllocations,
                    ) ??
                    true)
                  AppButton(
                    text: 'Allocate Funds',
                    icon: const Icon(
                      CupertinoIcons.arrow_right_arrow_left,
                      size: 14,
                    ),
                    variant: AppButtonVariant.tinted,
                    size: AppButtonSize.compact,
                    onPressed: () => _handleAllocateFunds(client),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Recent Invoices for this Client
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    'Billed Invoices',
                    style: AppTypography.headline.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary(context),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  AppBadge(
                    label: '${_clientInvoices.length}',
                    variant: AppBadgeVariant.neutral,
                  ),
                ],
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => _handleNewInvoice(client),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(CupertinoIcons.plus, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'Add Invoice',
                      style: AppTypography.footnote.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryAccent(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          _buildClientInvoicesList(context, client),

          const SizedBox(height: AppSpacing.xl),

          // Recent Payments for this Client
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    'Payments & Receipts',
                    style: AppTypography.headline.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary(context),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  AppBadge(
                    label: '${_clientPayments.length}',
                    variant: AppBadgeVariant.neutral,
                  ),
                ],
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => _handleRecordPayment(client),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(CupertinoIcons.plus, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'Add Payment',
                      style: AppTypography.footnote.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryAccent(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          _buildClientPaymentsList(context, client),

          // Notes Section
          if (client.notes != null && client.notes!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Client Notes',
              style: AppTypography.headline.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary(context),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surfaceSecondary(
                  context,
                ).withValues(alpha: 0.5),
                borderRadius: AppRadii.mdRadius,
                border: Border.all(
                  color: AppColors.border(context).withValues(alpha: 0.5),
                  width: 0.8,
                ),
              ),
              child: Text(
                client.notes!,
                style: AppTypography.body.copyWith(
                  color: AppColors.textSecondary(context),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildClientInvoicesList(BuildContext context, Client client) {
    if (_clientInvoices.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: AppRadii.mdRadius,
          border: Border.all(
            color: AppColors.border(context).withValues(alpha: 0.5),
            width: 0.8,
          ),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(
                CupertinoIcons.doc_text,
                size: 28,
                color: AppColors.textTertiary(context),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'No invoices created for this client yet.',
                style: AppTypography.footnote.copyWith(
                  color: AppColors.textTertiary(context),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: _clientInvoices.map((inv) {
        final isIssued = inv.status == InvoiceStatus.issued;
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: AppColors.surface(context),
              borderRadius: AppRadii.smRadius,
              border: Border.all(
                color: AppColors.border(context).withValues(alpha: 0.5),
                width: 0.8,
              ),
            ),
            child: Row(
              children: [
                AppModernIcon(
                  icon: isIssued
                      ? CupertinoIcons.doc_checkmark_fill
                      : CupertinoIcons.doc_text,
                  size: 32,
                  iconSize: 16,
                  gradient: isIssued ? AppGradients.primary(context) : null,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        inv.number,
                        style: AppTypography.subheadline.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary(context),
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        _formatDate(inv.createdAt),
                        style: AppTypography.caption2.copyWith(
                          color: AppColors.textTertiary(context),
                        ),
                      ),
                    ],
                  ),
                ),
                AppBadge(
                  label: isIssued ? 'Issued' : 'Draft',
                  variant: isIssued
                      ? AppBadgeVariant.accent
                      : AppBadgeVariant.neutral,
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  inv.total.format(),
                  style: AppTypography.subheadline.copyWith(
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    color: AppColors.textPrimary(context),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildClientPaymentsList(BuildContext context, Client client) {
    if (_clientPayments.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: AppRadii.mdRadius,
          border: Border.all(
            color: AppColors.border(context).withValues(alpha: 0.5),
            width: 0.8,
          ),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(
                CupertinoIcons.arrow_down_circle,
                size: 28,
                color: AppColors.textTertiary(context),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'No payments recorded for this client yet.',
                style: AppTypography.footnote.copyWith(
                  color: AppColors.textTertiary(context),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: _clientPayments.map((pmt) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: AppColors.surface(context),
              borderRadius: AppRadii.smRadius,
              border: Border.all(
                color: AppColors.border(context).withValues(alpha: 0.5),
                width: 0.8,
              ),
            ),
            child: Row(
              children: [
                AppModernIcon(
                  icon: CupertinoIcons.arrow_down_left,
                  size: 32,
                  iconSize: 16,
                  gradient: AppGradients.success(context),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pmt.notes ?? 'Payment',
                        style: AppTypography.subheadline.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary(context),
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        _formatDate(pmt.receivedAt),
                        style: AppTypography.caption2.copyWith(
                          color: AppColors.textTertiary(context),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '+${pmt.amount.format()}',
                  style: AppTypography.subheadline.copyWith(
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    color: AppColors.success(context),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required String title,
    required String value,
    required String subtitle,
    required AppBadgeVariant variant,
    Color? tintColor,
  }) {
    final gradient = AppGradients.metricSurface(context, tintColor: tintColor);
    final isDark = CupertinoTheme.maybeBrightnessOf(context) == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: AppRadii.mdRadius,
        border: Border.all(
          color: tintColor != null
              ? tintColor.withValues(alpha: isDark ? 0.35 : 0.22)
              : AppColors.border(context).withValues(alpha: 0.6),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: (tintColor ?? CupertinoColors.black).withValues(
              alpha: isDark ? 0.12 : 0.03,
            ),
            blurRadius: 6.0,
            offset: const Offset(0, 1.5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.footnote.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary(context),
                  ),
                ),
              ),
              AppBadge(
                label: variant == AppBadgeVariant.destructive
                    ? 'Due'
                    : variant == AppBadgeVariant.success
                    ? 'Credit'
                    : 'Settled',
                variant: variant,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: AppTypography.title2.copyWith(
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
              color: AppColors.textPrimary(context),
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            subtitle,
            style: AppTypography.caption1.copyWith(
              color: AppColors.textTertiary(context),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
