import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/cupertino.dart';

/// Desktop Sync Status Diagnostics screen inspecting local SQLite outbox state.
class DesktopSyncStatusScreen extends StatefulWidget {
  const DesktopSyncStatusScreen({super.key, required this.dependencies});

  final AppDependencies dependencies;

  @override
  State<DesktopSyncStatusScreen> createState() =>
      _DesktopSyncStatusScreenState();
}

class _DesktopSyncStatusScreenState extends State<DesktopSyncStatusScreen> {
  late final SyncStatusViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = SyncStatusViewModel(
      outboxRepository: widget.dependencies.syncOutboxRepository,
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
    if (!widget.dependencies.hasPermission(AppPermission.viewSyncStatus)) {
      return AppAtmosphericBackground(
        accentColor: const Color(0xFF34C759),
        child: AppAccessDeniedState(
          requiredPermission: AppPermission.viewSyncStatus,
          currentRoleName:
              widget.dependencies.authViewModel.state.currentRole?.name,
          title: 'Sync Diagnostics Restricted',
        ),
      );
    }

    return AppAtmosphericBackground(
      accentColor: const Color(0xFF34C759),
      child: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          final state = _viewModel.state;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              AppPageHeader(
                title: 'Sync Status & Outbox',
                subtitle:
                    'Local SQLite change tracking and deterministic outbox diagnostics',
                actions: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppButton(
                      text: 'Refresh Diagnostics',
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

              // Content
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: [
                    // Offline-First Scope Clarification Banner
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.primaryAccent(
                          context,
                        ).withValues(alpha: 0.08),
                        borderRadius: AppRadii.lgRadius,
                        border: Border.all(
                          color: AppColors.primaryAccent(
                            context,
                          ).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            CupertinoIcons.info_circle_fill,
                            color: AppColors.primaryAccent(context),
                            size: 22,
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Offline-First Local Foundation (Phase 1)',
                                  style: AppTypography.subheadline.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryAccent(context),
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xxs),
                                Text(
                                  'Desktop and mobile operate as independent offline-first installations with private SQLite databases. '
                                  'Business operations record changes into this local outbox with strictly monotonic sequences, '
                                  'establishing guaranteed FIFO order for future backend synchronization without any network dependencies.',
                                  style: AppTypography.body.copyWith(
                                    color: AppColors.textPrimary(context),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // Diagnostic Metric Cards
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final cardWidth =
                            (constraints.maxWidth - (AppSpacing.md * 3)) / 4;

                        return Row(
                          children: [
                            SizedBox(
                              width: cardWidth,
                              child: _buildMetricTile(
                                context,
                                'Pending Outbox',
                                '${state.pendingCount}',
                                'Awaiting sync dispatch',
                                AppColors.warning(context),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            SizedBox(
                              width: cardWidth,
                              child: _buildMetricTile(
                                context,
                                'Local Sequence #',
                                '${state.latestSequence}',
                                'Strict monotonic counter',
                                AppColors.primaryAccent(context),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            SizedBox(
                              width: cardWidth,
                              child: _buildMetricTile(
                                context,
                                'Acknowledged',
                                '${state.acknowledgedCount}',
                                'Synchronized events',
                                AppColors.success(context),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            SizedBox(
                              width: cardWidth,
                              child: _buildMetricTile(
                                context,
                                'Failed / Conflicts',
                                '${state.failedCount}',
                                'Requiring resolution',
                                state.failedCount > 0
                                    ? AppColors.destructive(context)
                                    : AppColors.textSecondary(context),
                              ),
                            ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // Outbox Operations Table Card
                    Container(
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
                                  'Pending SQLite Outbox Operations',
                                  style: AppTypography.headline.copyWith(
                                    fontSize: 16,
                                    color: AppColors.textPrimary(context),
                                  ),
                                ),
                                Text(
                                  '${state.pendingOperations.length} queued',
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

                          if (state.pendingOperations.isEmpty)
                            Padding(
                              padding: const EdgeInsets.all(AppSpacing.xxl),
                              child: Center(
                                child: Text(
                                  'All local transactions are up to date. Outbox is clear.',
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
                                  SizedBox(
                                    width: 60,
                                    child: Text(
                                      'SEQ #',
                                      style: AppTypography.caption2.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textSecondary(context),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      'ENTITY TYPE',
                                      style: AppTypography.caption2.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textSecondary(context),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      'OPERATION',
                                      style: AppTypography.caption2.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textSecondary(context),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      'ENTITY ID',
                                      style: AppTypography.caption2.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textSecondary(context),
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 80,
                                    child: Text(
                                      'VERSION',
                                      style: AppTypography.caption2.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textSecondary(context),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Align(
                                      alignment: Alignment.centerRight,
                                      child: Text(
                                        'TIMESTAMP',
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
                            for (final op in state.pendingOperations) ...[
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md,
                                  vertical: AppSpacing.sm,
                                ),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 60,
                                      child: Text(
                                        '#${op.localSequence}',
                                        style: AppTypography.body.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        op.entityType.name.toUpperCase(),
                                        style: AppTypography.body,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: AppBadge(
                                        label: op.operationType.name
                                            .toUpperCase(),
                                        variant: AppBadgeVariant.accent,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        op.entityId,
                                        style: AppTypography.caption1.copyWith(
                                          color: AppColors.textSecondary(
                                            context,
                                          ),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    SizedBox(
                                      width: 80,
                                      child: Text('v${op.entityVersion}'),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Align(
                                        alignment: Alignment.centerRight,
                                        child: Text(
                                          op.createdAt
                                              .toIso8601String()
                                              .substring(11, 19),
                                          style: AppTypography.caption1
                                              .copyWith(
                                                color: AppColors.textTertiary(
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
                            ],
                          ],
                        ],
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

  Widget _buildMetricTile(
    BuildContext context,
    String title,
    String value,
    String subtitle,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: AppRadii.lgRadius,
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.caption1.copyWith(
              color: AppColors.textSecondary(context),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: AppTypography.largeTitle.copyWith(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            subtitle,
            style: AppTypography.caption2.copyWith(
              color: AppColors.textTertiary(context),
            ),
          ),
        ],
      ),
    );
  }
}
