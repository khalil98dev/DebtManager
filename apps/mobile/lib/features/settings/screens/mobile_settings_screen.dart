import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/cupertino.dart';

import '../../allocations/screens/mobile_allocations_screen.dart';
import '../../financial/screens/mobile_financial_screen.dart';
import '../../sync_status/screens/mobile_sync_status_screen.dart';

/// Mobile Settings and Preferences screen with theme switching, currency preferences,
/// module navigation links, and offline database diagnostics.
class MobileSettingsScreen extends StatefulWidget {
  const MobileSettingsScreen({super.key, required this.dependencies});

  final AppDependencies dependencies;

  @override
  State<MobileSettingsScreen> createState() => _MobileSettingsScreenState();
}

class _MobileSettingsScreenState extends State<MobileSettingsScreen> {
  late final SettingsViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = SettingsViewModel(
      clientRepository: widget.dependencies.clientRepository,
      invoiceRepository: widget.dependencies.invoiceRepository,
      paymentRepository: widget.dependencies.paymentRepository,
      syncOutboxRepository: widget.dependencies.syncOutboxRepository,
      themeModeNotifier: widget.dependencies.themeMode,
      currencyNotifier: widget.dependencies.primaryCurrency,
    );
    _viewModel.loadStats();
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
        child: ListenableBuilder(
          listenable: _viewModel,
          builder: (context, _) {
            final state = _viewModel.state;

            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                CupertinoSliverNavigationBar(
                  largeTitle: const Text('Settings'),
                  backgroundColor: AppColors.canvas(
                    context,
                  ).withValues(alpha: 0.76),
                  border: Border(
                    bottom: BorderSide(
                      color: AppColors.separator(context),
                      width: 0.5,
                    ),
                  ),
                ),
                CupertinoSliverRefreshControl(onRefresh: _viewModel.refresh),
                SliverPadding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Theme Preferences Card
                      AppStaggeredItem(
                        index: 0,
                        child: AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Appearance', style: AppTypography.headline),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                'Select light, dark, or follow device system theme.',
                                style: AppTypography.footnote.copyWith(
                                  color: AppColors.textSecondary(context),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              SizedBox(
                                width: double.infinity,
                                child: AppSegmentedFilter<ThemeMode>(
                                  value: state.themeMode,
                                  segments: const {
                                    ThemeMode.system: 'System',
                                    ThemeMode.light: 'Light',
                                    ThemeMode.dark: 'Dark',
                                  },
                                  onChanged: _viewModel.setThemeMode,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: AppSpacing.md),

                      // Currency Preference Card
                      AppStaggeredItem(
                        index: 1,
                        child: AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Primary Currency',
                                style: AppTypography.headline,
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                'Active currency used for balance calculations and totals.',
                                style: AppTypography.footnote.copyWith(
                                  color: AppColors.textSecondary(context),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              SizedBox(
                                width: double.infinity,
                                child: AppSegmentedFilter<String>(
                                  value: state.primaryCurrency.code,
                                  segments: const {
                                    'DZD': 'DZD (DA)',
                                    'EUR': 'EUR (€)',
                                    'USD': 'USD (\$)',
                                  },
                                  onChanged: (code) {
                                    final cur = code == 'DZD'
                                        ? Currency.dzd
                                        : code == 'EUR'
                                        ? Currency.eur
                                        : Currency.usd;
                                    _viewModel.setPrimaryCurrency(cur);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: AppSpacing.md),

                      // Financial & Diagnostic Tools
                      AppStaggeredItem(
                        index: 2,
                        child: AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Management Tools',
                                style: AppTypography.headline,
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Container(
                                height: 1,
                                color: AppColors.separator(context),
                              ),
                              _buildDisclosureRow(
                                context,
                                icon: CupertinoIcons.chart_pie_fill,
                                title: 'Financial Overview',
                                subtitle:
                                    'Portfolio debts, unallocated credits, client balances',
                                onTap: () {
                                  Navigator.of(context).push(
                                    AppPageRoute.mobile(
                                      builder: (_) => MobileFinancialScreen(
                                        dependencies: widget.dependencies,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              Container(
                                height: 1,
                                color: AppColors.separator(context),
                              ),
                              _buildDisclosureRow(
                                context,
                                icon: CupertinoIcons.arrow_right_arrow_left,
                                title: 'Payment Allocations',
                                subtitle:
                                    'Audit and execute invoice payment distributions',
                                onTap: () {
                                  Navigator.of(context).push(
                                    AppPageRoute.mobile(
                                      builder: (_) => MobileAllocationsScreen(
                                        dependencies: widget.dependencies,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              Container(
                                height: 1,
                                color: AppColors.separator(context),
                              ),
                              _buildDisclosureRow(
                                context,
                                icon: CupertinoIcons.arrow_2_circlepath,
                                title: 'Offline Sync Diagnostics',
                                subtitle:
                                    'Local outbox queue and replication readiness',
                                onTap: () {
                                  Navigator.of(context).push(
                                    AppPageRoute.mobile(
                                      builder: (_) => MobileSyncStatusScreen(
                                        dependencies: widget.dependencies,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: AppSpacing.md),

                      // Local Storage Diagnostics
                      AppStaggeredItem(
                        index: 3,
                        child: AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Offline Storage Stats',
                                      style: AppTypography.headline,
                                    ),
                                  ),
                                  const AppBadge(
                                    label: 'SQLITE LOCAL',
                                    variant: AppBadgeVariant.neutral,
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Container(
                                height: 1,
                                color: AppColors.separator(context),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              _buildStatRow(
                                'Total Clients',
                                '${state.databaseStats.clientCount}',
                              ),
                              _buildStatRow(
                                'Total Invoices',
                                '${state.databaseStats.invoiceCount}',
                              ),
                              _buildStatRow(
                                'Total Payments',
                                '${state.databaseStats.paymentCount}',
                              ),
                              _buildStatRow(
                                'Outbox Mutations',
                                '${state.databaseStats.outboxCount}',
                              ),
                              _buildStatRow('Database Schema', 'Version 3'),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: AppSpacing.md),

                      // JWT Session & Role-Based Access Control (RBAC) Management
                      RbacManagementPanel(
                        authViewModel: widget.dependencies.authViewModel,
                      ),

                      const SizedBox(height: AppSpacing.xl),
                    ]),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildDisclosureRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      onPressed: onTap,
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primaryAccent(context)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary(context),
                  ),
                ),
                Text(
                  subtitle,
                  style: AppTypography.caption1.copyWith(
                    color: AppColors.textSecondary(context),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            CupertinoIcons.chevron_forward,
            size: 16,
            color: AppColors.textTertiary(context),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: AppTypography.body)),
          Text(
            value,
            style: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
