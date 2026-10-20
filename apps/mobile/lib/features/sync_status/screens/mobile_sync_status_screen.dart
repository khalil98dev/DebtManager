import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/cupertino.dart';

/// Mobile Offline Synchronization diagnostics screen showing local outbox state
/// and pending changes queue.
class MobileSyncStatusScreen extends StatefulWidget {
  const MobileSyncStatusScreen({super.key, required this.dependencies});

  final AppDependencies dependencies;

  @override
  State<MobileSyncStatusScreen> createState() => _MobileSyncStatusScreenState();
}

class _MobileSyncStatusScreenState extends State<MobileSyncStatusScreen> {
  late final SyncStatusViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = SyncStatusViewModel(
      syncOutboxRepository: widget.dependencies.syncOutboxRepository,
    );
    _viewModel.loadStatus();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppAtmosphericBackground(
      accentColor: const Color(0xFF10B981),
      child: CupertinoPageScaffold(
        backgroundColor: CupertinoColors.transparent,
        navigationBar: CupertinoNavigationBar(
          middle: const Text('Offline Sync Status'),
          backgroundColor: AppColors.canvas(context).withValues(alpha: 0.76),
          border: Border(
            bottom: BorderSide(color: AppColors.separator(context), width: 0.5),
          ),
        ),
        child: SafeArea(
        child: !widget.dependencies.hasPermission(AppPermission.viewSyncStatus)
            ? AppAccessDeniedState(
                requiredPermission: AppPermission.viewSyncStatus,
                currentRoleName:
                    widget.dependencies.authViewModel.state.currentRole?.name,
                title: 'Sync Diagnostics Restricted',
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
                SliverPadding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Offline Status Card
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.successLight,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Text(
                                  'Offline Storage Mode',
                                  style: AppTypography.headline.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Spacer(),
                                const AppBadge(
                                  label: 'ACTIVE',
                                  variant: AppBadgeVariant.success,
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'The application operates completely offline with local SQLite database transactions. All entities are stored locally on this device.',
                              style: AppTypography.footnote.copyWith(
                                color: AppColors.textSecondary(context),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: AppSpacing.md),

                      // Queue Metrics
                      Row(
                        children: [
                          Expanded(
                            child: AppMetricCard(
                              title: 'Pending Queue',
                              value: '${state.pendingCount}',
                              badgeLabel: state.pendingCount == 0
                                  ? 'Clean'
                                  : 'Pending',
                              badgeVariant: state.pendingCount == 0
                                  ? AppBadgeVariant.success
                                  : AppBadgeVariant.warning,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: AppMetricCard(
                              title: 'Storage Engine',
                              value: 'Drift SQLite',
                              badgeLabel: 'Local',
                              badgeVariant: AppBadgeVariant.neutral,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Pending Outbox Mutations (${state.pendingOperations.length})',
                        style: AppTypography.headline.copyWith(fontSize: 16),
                      ),
                      const SizedBox(height: AppSpacing.xs),

                      if (state.pendingOperations.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.xl,
                          ),
                          child: Center(
                            child: Text(
                              'Outbox queue is empty. All local changes are cleanly persisted.',
                              style: AppTypography.subheadline.copyWith(
                                color: AppColors.textSecondary(context),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      else
                        for (final op in state.pendingOperations)
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.xs,
                            ),
                            child: AppCard(
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${op.operationType.name.toUpperCase()} • ${op.entityType.name.toUpperCase()}',
                                          style: AppTypography.subheadline
                                              .copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                        const SizedBox(height: AppSpacing.xxs),
                                        Text(
                                          'Entity ID: ${op.entityId}',
                                          style: AppTypography.caption1
                                              .copyWith(
                                                color: AppColors.textSecondary(
                                                  context,
                                                ),
                                              ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    op.createdAt.toIso8601String().substring(
                                      11,
                                      19,
                                    ),
                                    style: AppTypography.caption2.copyWith(
                                      color: AppColors.textTertiary(context),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                    ]),
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
