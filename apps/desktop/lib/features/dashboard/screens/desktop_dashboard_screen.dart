import 'package:application/application.dart';
import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/cupertino.dart';

/// Desktop executive dashboard displaying aggregated metrics, recent activity,
/// and quick operational actions.
class DesktopDashboardScreen extends StatefulWidget {
  const DesktopDashboardScreen({super.key, this.dependencies});

  final AppDependencies? dependencies;

  @override
  State<DesktopDashboardScreen> createState() => _DesktopDashboardScreenState();
}

class _DesktopDashboardScreenState extends State<DesktopDashboardScreen> {
  late final DashboardViewModel _viewModel;
  late final AppDependencies _deps;

  @override
  void initState() {
    super.initState();
    _deps = widget.dependencies!;
    _viewModel = DashboardViewModel(
      getDashboardSummary: _deps.getDashboardSummary,
    );
    _viewModel.loadSummary();
    _deps.dataRevision.addListener(_onDataChanged);
  }

  @override
  void dispose() {
    _deps.dataRevision.removeListener(_onDataChanged);
    _viewModel.dispose();
    super.dispose();
  }

  void _onDataChanged() {
    if (mounted) {
      _refresh();
    }
  }

  Future<void> _refresh() async {
    await _viewModel.refresh();
  }

  @override
  Widget build(BuildContext context) {
    if (!_deps.hasPermission(AppPermission.viewDashboard)) {
      return AppAtmosphericBackground(
        child: AppAccessDeniedState(
          requiredPermission: AppPermission.viewDashboard,
          currentRoleName: _deps.authViewModel.state.currentRole?.name,
          title: 'Dashboard Restricted',
        ),
      );
    }

    return AppAtmosphericBackground(
      child: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          final state = _viewModel.state;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              AppPageHeader(
                title: 'Dashboard',
                subtitle:
                    'Executive portfolio health, financial totals, and recent activity',
                actions: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppButton(
                      text: 'Refresh',
                      icon: const Icon(
                        CupertinoIcons.arrow_clockwise,
                        size: 14,
                      ),
                      size: AppButtonSize.compact,
                      variant: AppButtonVariant.secondary,
                      isLoading: state.isLoading,
                      onPressed: _refresh,
                    ),
                  ],
                ),
              ),

              // Scrollable Content
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: [
                    // Quick Action Bar
                    AppStaggeredItem(
                      index: 0,
                      child: _buildQuickActionBar(context),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    if (state.isLoading && state.summary == null) ...[
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(AppSpacing.xxl),
                          child: CupertinoActivityIndicator(radius: 14),
                        ),
                      ),
                    ] else if (state.summary != null) ...[
                      // Metrics Cards Row
                      AppStaggeredItem(
                        index: 1,
                        child: _buildMetricsRow(context, state.summary!),
                      ),

                      const SizedBox(height: AppSpacing.xl),

                      // Recent Invoices & Recent Payments 2-column layout
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: AppStaggeredItem(
                              index: 2,
                              child: _buildRecentInvoicesCard(
                                context,
                                state.summary!,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.lg),
                          Expanded(
                            child: AppStaggeredItem(
                              index: 3,
                              child: _buildRecentPaymentsCard(
                                context,
                                state.summary!,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ] else if (state.errorMessage != null) ...[
                      AppErrorState(
                        title: 'Failed to load dashboard',
                        description: state.errorMessage!,
                        onRetry: _refresh,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildQuickActionBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface(context).withValues(alpha: 0.88),
        borderRadius: AppRadii.lgRadius,
        border: Border.all(
          color: AppColors.border(context).withValues(alpha: 0.65),
          width: 0.8,
        ),
      ),
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.xs,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: Text(
              'Quick Actions',
              style: AppTypography.subheadline.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary(context),
              ),
            ),
          ),
          if (_deps.hasPermission(AppPermission.manageClients))
            AppButton(
              text: 'New Client',
              icon: const Icon(CupertinoIcons.person_badge_plus, size: 14),
              size: AppButtonSize.compact,
              variant: AppButtonVariant.secondary,
              onPressed: () async {
                final result = await ClientFormDialog.show(
                  context,
                  createClient: _deps.createClient,
                  updateClient: _deps.updateClient,
                );
                if (result != null) {
                  _deps.notifyDataChanged();
                  _refresh();
                }
              },
            ),
          if (_deps.hasPermission(AppPermission.manageInvoices))
            AppButton(
              text: 'New Invoice',
              icon: const Icon(CupertinoIcons.doc_text, size: 14),
              size: AppButtonSize.compact,
              variant: AppButtonVariant.secondary,
              onPressed: () async {
                final result = await InvoiceFormDialog.show(
                  context,
                  clientRepository: _deps.clientRepository,
                  createInvoice: _deps.createInvoice,
                  updateInvoiceDraft: _deps.updateInvoiceDraft,
                  issueInvoice: _deps.hasPermission(AppPermission.issueInvoices)
                      ? _deps.issueInvoice
                      : null,
                  createClient: _deps.hasPermission(AppPermission.manageClients)
                      ? _deps.createClient
                      : null,
                  updateClient: _deps.hasPermission(AppPermission.manageClients)
                      ? _deps.updateClient
                      : null,
                );
                if (result != null) {
                  _deps.notifyDataChanged();
                  _refresh();
                }
              },
            ),
          if (_deps.hasPermission(AppPermission.recordPayments))
            AppButton(
              text: 'Record Payment',
              icon: const Icon(CupertinoIcons.arrow_down_circle, size: 14),
              size: AppButtonSize.compact,
              variant: AppButtonVariant.secondary,
              onPressed: () async {
                final result = await PaymentFormDialog.show(
                  context,
                  clientRepository: _deps.clientRepository,
                  recordPayment: _deps.recordPayment,
                  createClient: _deps.hasPermission(AppPermission.manageClients)
                      ? _deps.createClient
                      : null,
                  updateClient: _deps.hasPermission(AppPermission.manageClients)
                      ? _deps.updateClient
                      : null,
                );
                if (result != null) {
                  _deps.notifyDataChanged();
                  _refresh();
                }
              },
            ),
          if (_deps.hasPermission(AppPermission.manageAllocations))
            AppButton(
              text: 'Allocate Funds',
              icon: const Icon(CupertinoIcons.arrow_right_arrow_left, size: 14),
              size: AppButtonSize.compact,
              variant: AppButtonVariant.primary,
              onPressed: () async {
                final result = await AllocationDialog.show(
                  context,
                  clientRepository: _deps.clientRepository,
                  invoiceRepository: _deps.invoiceRepository,
                  paymentRepository: _deps.paymentRepository,
                  paymentAllocationRepository:
                      _deps.paymentAllocationRepository,
                  allocatePayment: _deps.allocatePayment,
                );
                if (result != null) {
                  _deps.notifyDataChanged();
                  _refresh();
                }
              },
            ),
        ],
      ),
    );
  }

  Widget _buildMetricsRow(BuildContext context, DashboardSummary summary) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - (AppSpacing.md * 3)) / 4;

        return Row(
          children: [
            SizedBox(
              width: cardWidth,
              child: AppMetricCard(
                title: 'Outstanding Debt',
                money: summary.totalOutstandingDebt,
                subtitle: 'Unpaid issued invoice balance',
                badgeLabel: 'Receivable',
                badgeVariant: AppBadgeVariant.destructive,
                icon: CupertinoIcons.exclamationmark_triangle_fill,
                gradient: AppGradients.destructive(context),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            SizedBox(
              width: cardWidth,
              child: AppMetricCard(
                title: 'Unallocated Credit',
                money: summary.totalUnallocatedCredit,
                subtitle: 'Available customer advance funds',
                badgeLabel: 'Available',
                badgeVariant: AppBadgeVariant.success,
                icon: CupertinoIcons.checkmark_seal_fill,
                gradient: AppGradients.success(context),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            SizedBox(
              width: cardWidth,
              child: AppMetricCard(
                title: 'Total Invoiced',
                money: summary.totalBilled,
                subtitle:
                    '${summary.totalIssuedInvoices} issued, ${summary.totalDraftInvoices} drafts',
                icon: CupertinoIcons.doc_text_fill,
                gradient: AppGradients.primary(context),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            SizedBox(
              width: cardWidth,
              child: AppMetricCard(
                title: 'Portfolio Net Position',
                money: summary.netPosition,
                subtitle: summary.netPosition.isNegative
                    ? 'Net credit owed to clients'
                    : 'Net outstanding receivables',
                badgeLabel: summary.netPosition.isPositive
                    ? 'Net Due'
                    : 'Settled',
                badgeVariant: summary.netPosition.isPositive
                    ? AppBadgeVariant.destructive
                    : AppBadgeVariant.neutral,
                icon: CupertinoIcons.chart_bar_fill,
                gradient: AppGradients.indigoViolet,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRecentInvoicesCard(
    BuildContext context,
    DashboardSummary summary,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: AppRadii.lgRadius,
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Invoices',
                  style: AppTypography.headline.copyWith(
                    fontSize: 16,
                    color: AppColors.textPrimary(context),
                  ),
                ),
                Text(
                  '${summary.recentInvoices.length} entries',
                  style: AppTypography.caption1.copyWith(
                    color: AppColors.textSecondary(context),
                  ),
                ),
              ],
            ),
          ),
          Container(height: 1, color: AppColors.separator(context)),
          if (summary.recentInvoices.isEmpty)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Center(
                child: Text(
                  'No invoices issued or created yet',
                  style: AppTypography.caption1.copyWith(
                    color: AppColors.textTertiary(context),
                  ),
                ),
              ),
            )
          else
            for (final inv in summary.recentInvoices.take(6)) ...[
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          inv.number,
                          style: AppTypography.body.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary(context),
                          ),
                        ),
                        Text(
                          inv.createdAt.toIso8601String().substring(0, 10),
                          style: AppTypography.caption2.copyWith(
                            color: AppColors.textSecondary(context),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        AppMoneyDisplay(
                          money: inv.total,
                          style: AppTypography.body.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        AppBadge(
                          label: inv.status.name.toUpperCase(),
                          variant: inv.isIssued
                              ? AppBadgeVariant.success
                              : AppBadgeVariant.neutral,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(height: 1, color: AppColors.separator(context)),
            ],
        ],
      ),
    );
  }

  Widget _buildRecentPaymentsCard(
    BuildContext context,
    DashboardSummary summary,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: AppRadii.lgRadius,
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Payments',
                  style: AppTypography.headline.copyWith(
                    fontSize: 16,
                    color: AppColors.textPrimary(context),
                  ),
                ),
                Text(
                  '${summary.recentPayments.length} entries',
                  style: AppTypography.caption1.copyWith(
                    color: AppColors.textSecondary(context),
                  ),
                ),
              ],
            ),
          ),
          Container(height: 1, color: AppColors.separator(context)),
          if (summary.recentPayments.isEmpty)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Center(
                child: Text(
                  'No received payments recorded yet',
                  style: AppTypography.caption1.copyWith(
                    color: AppColors.textTertiary(context),
                  ),
                ),
              ),
            )
          else
            for (final p in summary.recentPayments.take(6)) ...[
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.receivedAt.toIso8601String().substring(0, 10),
                          style: AppTypography.body.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary(context),
                          ),
                        ),
                        if (p.notes != null)
                          Text(
                            p.notes!,
                            style: AppTypography.caption2.copyWith(
                              color: AppColors.textSecondary(context),
                            ),
                          ),
                      ],
                    ),
                    AppMoneyDisplay(
                      money: p.amount,
                      style: AppTypography.body.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.success(context),
                      ),
                    ),
                  ],
                ),
              ),
              Container(height: 1, color: AppColors.separator(context)),
            ],
        ],
      ),
    );
  }
}
