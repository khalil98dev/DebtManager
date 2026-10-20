import 'dart:ui';
import 'package:application/application.dart';
import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/cupertino.dart';

class MobileClientsScreen extends StatefulWidget {
  const MobileClientsScreen({
    super.key,
    this.repository,
    this.dependencies,
    this.onAddClient,
  });

  final ClientRepository? repository;
  final AppDependencies? dependencies;
  final VoidCallback? onAddClient;

  @override
  State<MobileClientsScreen> createState() => _MobileClientsScreenState();
}

class _MobileClientsScreenState extends State<MobileClientsScreen> {
  late final ClientListViewModel _viewModel;

  AppDependencies? _resolveDeps() {
    return widget.dependencies ?? AppScope.maybeOf(context);
  }

  @override
  void initState() {
    super.initState();
    final repo = widget.repository ?? widget.dependencies?.clientRepository;
    assert(
      repo != null,
      'Either repository or dependencies must be provided to MobileClientsScreen',
    );
    _viewModel = ClientListViewModel(repository: repo!);
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
    }
  }

  @override
  void dispose() {
    _subscribedDeps?.dataRevision.removeListener(_onDataChanged);
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _handleNewClient() async {
    if (widget.onAddClient != null) {
      widget.onAddClient!();
      return;
    }
    final deps = _resolveDeps();
    if (deps != null) {
      final created = await ClientFormDialog.show(
        context,
        createClient: deps.createClient,
        updateClient: deps.updateClient,
      );
      if (created != null && mounted) {
        deps.notifyDataChanged();
        await _viewModel.refresh();
      }
    } else {
      widget.onAddClient?.call();
    }
  }

  Future<void> _handleEditClient(Client client) async {
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
      await _viewModel.refresh();
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
      await _viewModel.refresh();
    }
  }

  void _showClientDetail(BuildContext context, Client client) {
    showCupertinoModalPopup<void>(
      context: context,
      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
      builder: (modalContext) {
        return CupertinoActionSheet(
          title: Text(
            client.name,
            style: AppTypography.headline.copyWith(
              color: AppColors.textPrimary(context),
            ),
          ),
          message: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: AppSpacing.xs),
              Text(
                client.phone ?? 'No phone number on record',
                style: AppTypography.subheadline.copyWith(
                  color: AppColors.textSecondary(context),
                ),
              ),
              if (client.notes != null && client.notes!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  client.notes!,
                  textAlign: TextAlign.center,
                  style: AppTypography.footnote.copyWith(
                    color: AppColors.textTertiary(context),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            if (_resolveDeps()?.hasPermission(AppPermission.manageInvoices) ??
                true)
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.pop(modalContext);
                  _handleNewInvoice(client);
                },
                child: const Text('New Invoice'),
              ),
            if (_resolveDeps()?.hasPermission(AppPermission.recordPayments) ??
                true)
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.pop(modalContext);
                  _handleRecordPayment(client);
                },
                child: const Text('Record Payment'),
              ),
            CupertinoActionSheetAction(
              onPressed: () => Navigator.pop(modalContext),
              child: const Text('View Financial History'),
            ),
            if (_resolveDeps()?.hasPermission(AppPermission.manageClients) ??
                true)
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.pop(modalContext);
                  _handleEditClient(client);
                },
                child: const Text('Edit Client'),
              ),
          ],
          cancelButton: CupertinoActionSheetAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(modalContext),
            child: const Text('Done'),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppAtmosphericBackground(
      child: CupertinoPageScaffold(
        backgroundColor: CupertinoColors.transparent,
        child: ListenableBuilder(
          listenable: _viewModel,
          builder: (context, _) {
            final state = _viewModel.state;

            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                // iOS Large Title Navigation Bar
                CupertinoSliverNavigationBar(
                  largeTitle: const Text('Clients'),
                  backgroundColor: AppColors.canvas(
                    context,
                  ).withValues(alpha: 0.76),
                  border: Border(
                    bottom: BorderSide(
                      color: AppColors.separator(context),
                      width: 0.5,
                    ),
                  ),
                  trailing:
                      (_resolveDeps()?.hasPermission(
                            AppPermission.manageClients,
                          ) ??
                          true)
                      ? CupertinoButton(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(
                            AppSpacing.minTouchTarget,
                            AppSpacing.minTouchTarget,
                          ),
                          onPressed: _handleNewClient,
                          child: const Icon(
                            CupertinoIcons.plus_circle_fill,
                            size: 26,
                          ),
                        )
                      : null,
                ),

                // Pull-To-Refresh Control
                CupertinoSliverRefreshControl(onRefresh: _viewModel.refresh),

                // Search Bar Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.sm,
                      AppSpacing.md,
                      AppSpacing.xs,
                    ),
                    child: AppSearchField(
                      placeholder: 'Search clients by name or phone...',
                      onChanged: _viewModel.search,
                      onClear: _viewModel.clearSearch,
                    ),
                  ),
                ),

                // Summary Info
                if (state.isLoaded && state.totalCount > 0)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.xxs,
                      ),
                      child: Text(
                        '${state.filteredCount} ${state.filteredCount == 1 ? 'client' : 'clients'}',
                        style: AppTypography.footnote.copyWith(
                          color: AppColors.textSecondary(context),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),

                // Content Area
                _buildContentSliver(context, state),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildContentSliver(BuildContext context, ClientListViewState state) {
    if (state.isLoading) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: List.generate(
              5,
              (index) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: AppCard(
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
                            AppSkeleton(width: 140, height: 16),
                            SizedBox(height: AppSpacing.xs),
                            AppSkeleton(width: 90, height: 12),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    if (state.hasError) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: AppErrorState(
          message: state.errorMessage ?? 'Failed to load clients.',
          onRetry: _viewModel.refresh,
        ),
      );
    }

    if (state.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: AppEmptyState(
          icon: CupertinoIcons.person_2,
          title: 'No Clients Yet',
          description:
              'Add your first client to record debts, issue invoices, and track payments.',
          actionLabel: 'Add Client',
          onAction: _handleNewClient,
        ),
      );
    }

    if (state.isSearchEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: AppEmptyState(
          icon: CupertinoIcons.search,
          title: 'No Clients Found',
          description: 'No clients match "${state.searchQuery}".',
          actionLabel: 'Clear Search',
          onAction: _viewModel.clearSearch,
        ),
      );
    }

    // Inset-Grouped Apple Style List with Frosted Surface & Staggered Entrance
    final isDark = CupertinoTheme.maybeBrightnessOf(context) == Brightness.dark;
    return SliverPadding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      sliver: SliverToBoxAdapter(
        child: ClipRRect(
          borderRadius: AppRadii.mdRadius,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface(
                context,
              ).withValues(alpha: isDark ? 0.86 : 0.90),
              borderRadius: AppRadii.mdRadius,
              border: Border.all(color: AppColors.border(context), width: 1.0),
              boxShadow: isDark
                  ? null
                  : [
                      BoxShadow(
                        color: CupertinoColors.black.withValues(alpha: 0.03),
                        blurRadius: 10.0,
                        offset: const Offset(0, 3),
                      ),
                    ],
            ),
            child: ListView.builder(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: state.filteredClients.length,
              itemBuilder: (context, index) {
                final client = state.filteredClients[index];
                return AppStaggeredItem(
                  index: index,
                  child: ClientListRow(
                    client: client,
                    onTap: () => _showClientDetail(context, client),
                    showDivider: index < state.filteredClients.length - 1,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
