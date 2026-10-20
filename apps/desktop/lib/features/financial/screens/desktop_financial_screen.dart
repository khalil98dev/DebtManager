import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/cupertino.dart';

/// Desktop Financials Screen providing portfolio metrics and client financial breakdowns.
class DesktopFinancialsScreen extends StatefulWidget {
  const DesktopFinancialsScreen({super.key, required this.dependencies});

  final AppDependencies dependencies;

  @override
  State<DesktopFinancialsScreen> createState() =>
      _DesktopFinancialsScreenState();
}

class _DesktopFinancialsScreenState extends State<DesktopFinancialsScreen> {
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
    widget.dependencies.dataRevision.addListener(_onDataChanged);
  }

  @override
  void dispose() {
    widget.dependencies.dataRevision.removeListener(_onDataChanged);
    _viewModel.dispose();
    super.dispose();
  }

  void _onDataChanged() {
    if (mounted) {
      _viewModel.refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.dependencies.hasPermission(AppPermission.viewDashboard)) {
      return AppAtmosphericBackground(
        accentColor: const Color(0xFF007AFF),
        child: AppAccessDeniedState(
          requiredPermission: AppPermission.viewDashboard,
          currentRoleName:
              widget.dependencies.authViewModel.state.currentRole?.name,
          title: 'Financial Overview Restricted',
        ),
      );
    }

    return AppAtmosphericBackground(
      accentColor: const Color(0xFF007AFF),
      child: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          final state = _viewModel.state;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              AppPageHeader(
                title: 'Financial Overview',
                subtitle:
                    'Portfolio debt positions, credit balances, and client summaries',
                actions: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 240,
                      child: AppSearchField(
                        placeholder: 'Search client...',
                        onChanged: _viewModel.search,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    AppSegmentedFilter<FinancialClientFilter>(
                      value: state.filter,
                      segments: const {
                        FinancialClientFilter.all: 'All',
                        FinancialClientFilter.debtors: 'Debtors',
                        FinancialClientFilter.creditors: 'Creditors',
                        FinancialClientFilter.balanced: 'Settled',
                      },
                      onChanged: (val) {
                        _viewModel.setFilter(val);
                      },
                    ),
                    const SizedBox(width: AppSpacing.md),
                    AppButton(
                      text: 'Refresh',
                      icon: const Icon(
                        CupertinoIcons.arrow_clockwise,
                        size: 14,
                      ),
                      size: AppButtonSize.compact,
                      variant: AppButtonVariant.secondary,
                      isLoading: state.isLoading,
                      onPressed: _viewModel.refresh,
                    ),
                  ],
                ),
              ),

              // Scrollable Content
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: [
                    // Metric Cards Row
                    AppStaggeredItem(
                      index: 0,
                      child: _buildPortfolioMetricCards(context, state),
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // Clients Table Card
                    AppStaggeredItem(
                      index: 1,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface(
                            context,
                          ).withValues(alpha: 0.88),
                          borderRadius: AppRadii.lgRadius,
                          border: Border.all(
                            color: AppColors.border(
                              context,
                            ).withValues(alpha: 0.65),
                            width: 0.8,
                          ),
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
                                  'Client Financial Breakdown',
                                  style: AppTypography.headline.copyWith(
                                    fontSize: 16,
                                    color: AppColors.textPrimary(context),
                                  ),
                                ),
                                Text(
                                  '${state.filteredRows.length} clients',
                                  style: AppTypography.caption1.copyWith(
                                    color: AppColors.textSecondary(context),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            height: 1,
                            color: AppColors.separator(context),
                          ),

                          if (state.isLoading)
                            const Padding(
                              padding: EdgeInsets.all(AppSpacing.xxl),
                              child: Center(
                                child: CupertinoActivityIndicator(radius: 14),
                              ),
                            )
                          else if (state.filteredRows.isEmpty)
                            Padding(
                              padding: const EdgeInsets.all(AppSpacing.xl),
                              child: Center(
                                child: Text(
                                  'No clients match the selected criteria.',
                                  style: AppTypography.caption1.copyWith(
                                    color: AppColors.textTertiary(context),
                                  ),
                                ),
                              ),
                            )
                          else ...[
                            // Table Header
                            Container(
                              color: AppColors.surfaceSecondary(context),
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: AppSpacing.xs,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      'CLIENT',
                                      style: AppTypography.caption2.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textSecondary(context),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      'INVOICED',
                                      style: AppTypography.caption2.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textSecondary(context),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      'ALLOCATED',
                                      style: AppTypography.caption2.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textSecondary(context),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      'OUTSTANDING DEBT',
                                      style: AppTypography.caption2.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textSecondary(context),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      'UNALLOCATED CREDIT',
                                      style: AppTypography.caption2.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textSecondary(context),
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 110,
                                    child: Align(
                                      alignment: Alignment.centerRight,
                                      child: Text(
                                        'STATUS',
                                        style: AppTypography.caption2.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textSecondary(
                                            context,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              height: 1,
                              color: AppColors.separator(context),
                            ),

                            // Table Rows
                            for (final row in state.filteredRows) ...[
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md,
                                  vertical: AppSpacing.sm,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        row.client.name,
                                        style: AppTypography.body.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: AppMoneyDisplay(
                                        money: row.position.totalInvoiced,
                                        style: AppTypography.body,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: AppMoneyDisplay(
                                        money:
                                            row.position.totalAllocatedPayments,
                                        style: AppTypography.body,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: AppMoneyDisplay(
                                        money: row.position.outstandingDebt,
                                        style: AppTypography.body.copyWith(
                                          color: row.position.hasOutstandingDebt
                                              ? AppColors.destructive(context)
                                              : null,
                                          fontWeight:
                                              row.position.hasOutstandingDebt
                                              ? FontWeight.w600
                                              : FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: AppMoneyDisplay(
                                        money: row.position.unallocatedCredit,
                                        style: AppTypography.body.copyWith(
                                          color:
                                              row.position.hasUnallocatedCredit
                                              ? AppColors.success(context)
                                              : null,
                                          fontWeight:
                                              row.position.hasUnallocatedCredit
                                              ? FontWeight.w600
                                              : FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 110,
                                      child: Align(
                                        alignment: Alignment.centerRight,
                                        child: AppBadge(
                                          label: row.position.hasOutstandingDebt
                                              ? 'OWES DEBT'
                                              : row
                                                    .position
                                                    .hasUnallocatedCredit
                                              ? 'IN CREDIT'
                                              : 'SETTLED',
                                          variant:
                                              row.position.hasOutstandingDebt
                                              ? AppBadgeVariant.destructive
                                              : row
                                                    .position
                                                    .hasUnallocatedCredit
                                              ? AppBadgeVariant.success
                                              : AppBadgeVariant.neutral,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                                  Container(
                                    height: 1,
                                    color: AppColors.separator(context),
                                  ),
                                ],
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
        },
      ),
    );
  }

  Widget _buildPortfolioMetricCards(
    BuildContext context,
    FinancialOverviewState state,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - (AppSpacing.md * 3)) / 4;

        return Row(
          children: [
            SizedBox(
              width: cardWidth,
              child: AppMetricCard(
                title: 'Total Outstanding Debt',
                money: state.totalOutstandingDebt ?? Money.zero(state.currency),
                badgeLabel: 'Owed',
                badgeVariant: AppBadgeVariant.destructive,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            SizedBox(
              width: cardWidth,
              child: AppMetricCard(
                title: 'Total Client Credit',
                money:
                    state.totalUnallocatedCredit ?? Money.zero(state.currency),
                badgeLabel: 'Advance',
                badgeVariant: AppBadgeVariant.success,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            SizedBox(
              width: cardWidth,
              child: AppMetricCard(
                title: 'Total Invoiced',
                money: state.totalBilled ?? Money.zero(state.currency),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            SizedBox(
              width: cardWidth,
              child: AppMetricCard(
                title: 'Net Portfolio Balance',
                money: state.netPosition ?? Money.zero(state.currency),
                badgeLabel: (state.netPosition?.isPositive ?? false)
                    ? 'Net Debt'
                    : 'Balanced',
                badgeVariant: (state.netPosition?.isPositive ?? false)
                    ? AppBadgeVariant.destructive
                    : AppBadgeVariant.neutral,
              ),
            ),
          ],
        );
      },
    );
  }
}
