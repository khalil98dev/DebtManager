import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/cupertino.dart';

/// Mobile Financial Overview screen with portfolio metric summaries,
/// client position list, search, and segmented filters.
class MobileFinancialScreen extends StatefulWidget {
  const MobileFinancialScreen({super.key, required this.dependencies});

  final AppDependencies dependencies;

  @override
  State<MobileFinancialScreen> createState() => _MobileFinancialScreenState();
}

class _MobileFinancialScreenState extends State<MobileFinancialScreen> {
  late final FinancialOverviewViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = FinancialOverviewViewModel(
      clientRepository: widget.dependencies.clientRepository,
      getClientFinancialPosition:
          widget.dependencies.getClientFinancialPosition,
    );
    _viewModel.loadOverview();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppAtmosphericBackground(
      accentColor: const Color(0xFF6366F1),
      child: CupertinoPageScaffold(
        backgroundColor: CupertinoColors.transparent,
        navigationBar: CupertinoNavigationBar(
          middle: const Text('Financial Overview'),
          backgroundColor: AppColors.canvas(context).withValues(alpha: 0.76),
          border: Border(
            bottom: BorderSide(color: AppColors.separator(context), width: 0.5),
          ),
        ),
        child: SafeArea(
        child: !widget.dependencies.hasPermission(AppPermission.viewDashboard)
            ? AppAccessDeniedState(
                requiredPermission: AppPermission.viewDashboard,
                currentRoleName:
                    widget.dependencies.authViewModel.state.currentRole?.name,
                title: 'Financial Overview Restricted',
              )
            : ListenableBuilder(
          listenable: _viewModel,
          builder: (context, _) {
            final state = _viewModel.state;

            if (state.isLoading) {
              return const Center(
                child: CupertinoActivityIndicator(radius: 14),
              );
            }

            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                CupertinoSliverRefreshControl(onRefresh: _viewModel.refresh),

                // Portfolio KPI Metrics
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: AppMetricCard(
                                title: 'Total Debt',
                                money:
                                    state.totalOutstandingDebt ??
                                    Money.zero(state.currency),
                                badgeLabel: 'Owed',
                                badgeVariant: AppBadgeVariant.destructive,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: AppMetricCard(
                                title: 'Client Credit',
                                money:
                                    state.totalUnallocatedCredit ??
                                    Money.zero(state.currency),
                                badgeLabel: 'Advance',
                                badgeVariant: AppBadgeVariant.success,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          children: [
                            Expanded(
                              child: AppMetricCard(
                                title: 'Total Invoiced',
                                money:
                                    state.totalBilled ??
                                    Money.zero(state.currency),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: AppMetricCard(
                                title: 'Net Position',
                                money:
                                    state.netPosition ??
                                    Money.zero(state.currency),
                                badgeLabel:
                                    (state.netPosition?.isPositive ?? false)
                                    ? 'Net Debt'
                                    : 'Settled',
                                badgeVariant:
                                    (state.netPosition?.isPositive ?? false)
                                    ? AppBadgeVariant.destructive
                                    : AppBadgeVariant.neutral,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppSearchField(
                          placeholder: 'Search client portfolio...',
                          onChanged: _viewModel.search,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        SizedBox(
                          width: double.infinity,
                          child: AppSegmentedFilter<FinancialClientFilter>(
                            value: state.filter,
                            segments: const {
                              FinancialClientFilter.all: 'All',
                              FinancialClientFilter.debtors: 'Debtors',
                              FinancialClientFilter.creditors: 'Creditors',
                              FinancialClientFilter.balanced: 'Settled',
                            },
                            onChanged: _viewModel.setFilter,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Client Financial Breakdown
                if (state.filteredRows.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: AppEmptyState(
                        icon: CupertinoIcons.chart_pie,
                        title: 'No Matching Clients',
                        description:
                            'No clients match the selected filter criteria.',
                        actionLabel: 'Reset Filter',
                        onAction: () =>
                            _viewModel.setFilter(FinancialClientFilter.all),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final row = state.filteredRows[index];

                        return AppStaggeredItem(
                          index: index,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                            child: AppCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        row.client.name,
                                        style: AppTypography.headline.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      AppBadge(
                                        label: row.position.hasOutstandingDebt
                                            ? 'OWES DEBT'
                                            : row.position.hasUnallocatedCredit
                                            ? 'IN CREDIT'
                                            : 'SETTLED',
                                        variant: row.position.hasOutstandingDebt
                                            ? AppBadgeVariant.destructive
                                            : row.position.hasUnallocatedCredit
                                            ? AppBadgeVariant.success
                                            : AppBadgeVariant.neutral,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Container(
                                    height: 1,
                                    color: AppColors.separator(context),
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Total Invoiced',
                                        style: AppTypography.footnote,
                                      ),
                                      AppMoneyDisplay(
                                        money: row.position.totalInvoiced,
                                        style: AppTypography.footnote,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: AppSpacing.xxs),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Allocated Payments',
                                        style: AppTypography.footnote,
                                      ),
                                      AppMoneyDisplay(
                                        money:
                                            row.position.totalAllocatedPayments,
                                        style: AppTypography.footnote,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: AppSpacing.xxs),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Outstanding Debt',
                                        style: AppTypography.subheadline
                                            .copyWith(
                                              fontWeight: FontWeight.w600,
                                              color:
                                                  row.position.hasOutstandingDebt
                                                  ? AppColors.destructive(
                                                      context,
                                                    )
                                                  : AppColors.textPrimary(
                                                      context,
                                                    ),
                                            ),
                                      ),
                                      AppMoneyDisplay(
                                        money: row.position.outstandingDebt,
                                        style: AppTypography.subheadline
                                            .copyWith(
                                              fontWeight: FontWeight.bold,
                                              color:
                                                  row.position.hasOutstandingDebt
                                                  ? AppColors.destructive(
                                                      context,
                                                    )
                                                  : AppColors.textPrimary(
                                                      context,
                                                    ),
                                            ),
                                      ),
                                    ],
                                  ),
                                  if (row.position.hasUnallocatedCredit) ...[
                                    const SizedBox(height: AppSpacing.xxs),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Unallocated Credit',
                                          style: AppTypography.footnote.copyWith(
                                            color: AppColors.success(context),
                                          ),
                                        ),
                                        AppMoneyDisplay(
                                          money: row.position.unallocatedCredit,
                                          style: AppTypography.footnote.copyWith(
                                            color: AppColors.success(context),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      }, childCount: state.filteredRows.length),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    ),
  );
}
}
