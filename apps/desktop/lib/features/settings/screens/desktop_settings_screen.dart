import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/cupertino.dart';

/// Desktop Settings and Local SQLite Database Diagnostics Screen.
class DesktopSettingsScreen extends StatefulWidget {
  const DesktopSettingsScreen({super.key, required this.dependencies});

  final AppDependencies dependencies;

  @override
  State<DesktopSettingsScreen> createState() => _DesktopSettingsScreenState();
}

class _DesktopSettingsScreenState extends State<DesktopSettingsScreen> {
  late final SettingsViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = SettingsViewModel(
      clientRepository: widget.dependencies.clientRepository,
      invoiceRepository: widget.dependencies.invoiceRepository,
      paymentRepository: widget.dependencies.paymentRepository,
      paymentAllocationRepository:
          widget.dependencies.paymentAllocationRepository,
      outboxRepository: widget.dependencies.syncOutboxRepository,
      themeModeNotifier: widget.dependencies.themeMode,
      currencyNotifier: widget.dependencies.primaryCurrency,
    );
    _viewModel.loadDiagnostics();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppAtmosphericBackground(
      accentColor: const Color(0xFF5856D6),
      child: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          final state = _viewModel.state;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              const AppPageHeader(
                title: 'Settings',
                subtitle:
                    'Application theme, default currency, and local database telemetry',
              ),

              // Content
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: [
                    // Theme Preferences Card
                    AppStaggeredItem(
                      index: 0,
                      child: _buildSettingsCard(
                        context,
                        title: 'Appearance',
                        subtitle:
                            'Select application color scheme and contrast mode',
                        child: Row(
                          children: [
                            Text(
                              'Theme Mode',
                              style: AppTypography.body.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            AppSegmentedFilter<ThemeMode>(
                              value: state.themeMode,
                              segments: const {
                                ThemeMode.system: 'System',
                                ThemeMode.light: 'Light',
                                ThemeMode.dark: 'Dark',
                              },
                              onChanged: (mode) {
                                _viewModel.setThemeMode(mode);
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // Currency Preference Card
                    AppStaggeredItem(
                      index: 1,
                      child: _buildSettingsCard(
                        context,
                        title: 'Currency & Subunits',
                        subtitle:
                            'Primary denomination used for calculations and formatting',
                        child: Row(
                          children: [
                            Text(
                              'Default Currency',
                              style: AppTypography.body.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            AppSegmentedFilter<String>(
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
                                    ? Currency.fromCode('EUR', symbol: '€')
                                    : Currency.fromCode('USD', symbol: '\$');
                                _viewModel.setPrimaryCurrency(cur);
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // Database Telemetry Card
                    AppStaggeredItem(
                      index: 2,
                      child: _buildSettingsCard(
                        context,
                        title: 'Local Database Diagnostics',
                        subtitle:
                            'Persistent storage metrics and SQLite schema integrity',
                        action: AppButton(
                          text: 'Refresh Telemetry',
                          icon: const Icon(
                            CupertinoIcons.arrow_clockwise,
                            size: 14,
                          ),
                          size: AppButtonSize.compact,
                          variant: AppButtonVariant.secondary,
                          isLoading: state.isLoading,
                          onPressed: _viewModel.refresh,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildDiagnosticRow(
                              context,
                              'Storage Engine',
                              state.databaseStats.storageEngine,
                            ),
                            _buildDiagnosticRow(
                              context,
                              'SQLite Schema Version',
                              'v${state.databaseStats.schemaVersion}',
                            ),
                            _buildDiagnosticRow(
                              context,
                              'Persisted Clients',
                              '${state.databaseStats.clientCount} records',
                            ),
                            _buildDiagnosticRow(
                              context,
                              'Persisted Invoices',
                              '${state.databaseStats.invoiceCount} records',
                            ),
                            _buildDiagnosticRow(
                              context,
                              'Recorded Payments',
                              '${state.databaseStats.paymentCount} transactions',
                            ),
                            _buildDiagnosticRow(
                              context,
                              'Payment Allocations',
                              '${state.databaseStats.allocationCount} links',
                            ),
                            _buildDiagnosticRow(
                              context,
                              'Local Sync Outbox Events',
                              '${state.databaseStats.outboxCount} changes queued',
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // JWT Session & Role-Based Access Control (RBAC) Management
                    RbacManagementPanel(
                      authViewModel: widget.dependencies.authViewModel,
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

  Widget _buildSettingsCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    Widget? action,
    required Widget child,
  }) {
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.headline.copyWith(
                        fontSize: 16,
                        color: AppColors.textPrimary(context),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      subtitle,
                      style: AppTypography.caption1.copyWith(
                        color: AppColors.textSecondary(context),
                      ),
                    ),
                  ],
                ),
                ?action,
              ],
            ),
          ),
          Container(height: 1, color: AppColors.separator(context)),
          Padding(padding: const EdgeInsets.all(AppSpacing.md), child: child),
        ],
      ),
    );
  }

  Widget _buildDiagnosticRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.body.copyWith(
              color: AppColors.textSecondary(context),
            ),
          ),
          Text(
            value,
            style: AppTypography.body.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary(context),
            ),
          ),
        ],
      ),
    );
  }
}
