import 'dart:ui';
import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/cupertino.dart';

/// Mobile-optimized Payments screen with large navigation title, search,
/// pull-to-refresh, Cupertino action sheet, and recording workflow.
class MobilePaymentsScreen extends StatefulWidget {
  const MobilePaymentsScreen({super.key, required this.dependencies});

  final AppDependencies dependencies;

  @override
  State<MobilePaymentsScreen> createState() => _MobilePaymentsScreenState();
}

class _MobilePaymentsScreenState extends State<MobilePaymentsScreen> {
  late final PaymentListViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = PaymentListViewModel(
      paymentRepository: widget.dependencies.paymentRepository,
      clientRepository: widget.dependencies.clientRepository,
    );
    _viewModel.loadPayments();
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

  void _showPaymentDetail(BuildContext context, Payment payment) async {
    final client = _viewModel.state.clientsById[payment.clientId];
    final allocations = await widget.dependencies.paymentAllocationRepository
        .getByPaymentId(payment.id);

    var totalAllocated = Money.zero(payment.currency);
    for (final a in allocations) {
      if (a.currency == payment.currency) {
        totalAllocated += a.amount;
      }
    }
    final unallocatedCredit = payment.amount > totalAllocated
        ? payment.amount - totalAllocated
        : Money.zero(payment.currency);

    if (!context.mounted) return;

    showCupertinoModalPopup<void>(
      context: context,
      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
      builder: (modalContext) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              height: MediaQuery.of(modalContext).size.height * 0.68,
              decoration: BoxDecoration(
                color: AppColors.surface(modalContext).withValues(alpha: 0.94),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                border: Border(
                  top: BorderSide(
                    color: CupertinoColors.white.withValues(alpha: 0.2),
                    width: 1.0,
                  ),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  children: [
                    // Modal Handle & Header
                    Container(
                      margin: const EdgeInsets.only(top: 10, bottom: 12),
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: AppColors.separator(modalContext),
                        borderRadius: BorderRadius.circular(2.5),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  payment.amount.format(),
                                  style: AppTypography.title1.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  client?.name ?? 'Unknown Client',
                                  style: AppTypography.subheadline.copyWith(
                                    color: AppColors.textSecondary(
                                      modalContext,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          AppBadge(
                            label: unallocatedCredit.isZero
                                ? 'FULLY ALLOCATED'
                                : 'UNALLOCATED CREDIT',
                            variant: unallocatedCredit.isZero
                                ? AppBadgeVariant.neutral
                                : AppBadgeVariant.success,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      height: 1,
                      color: AppColors.separator(modalContext),
                    ),

                    // Payment Breakdown Card
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        children: [
                          AppCard(
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Received Date',
                                      style: AppTypography.body,
                                    ),
                                    Text(
                                      payment.receivedAt
                                          .toIso8601String()
                                          .substring(0, 10),
                                      style: AppTypography.body.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Allocated to Invoices',
                                      style: AppTypography.body,
                                    ),
                                    AppMoneyDisplay(money: totalAllocated),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Unallocated Available',
                                      style: AppTypography.body.copyWith(
                                        color: AppColors.success(modalContext),
                                      ),
                                    ),
                                    AppMoneyDisplay(
                                      money: unallocatedCredit,
                                      style: TextStyle(
                                        color: AppColors.success(modalContext),
                                      ),
                                    ),
                                  ],
                                ),
                                if (payment.notes != null &&
                                    payment.notes!.isNotEmpty) ...[
                                  const SizedBox(height: AppSpacing.xs),
                                  Container(
                                    height: 1,
                                    color: AppColors.separator(modalContext),
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      'Note: ${payment.notes!}',
                                      style: AppTypography.footnote.copyWith(
                                        color: AppColors.textSecondary(
                                          modalContext,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),

                          const SizedBox(height: AppSpacing.md),
                          Text(
                            'Allocations History (${allocations.length})',
                            style: AppTypography.headline.copyWith(
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),

                          if (allocations.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.md,
                              ),
                              child: Center(
                                child: Text(
                                  'No allocations executed for this payment yet.',
                                  style: AppTypography.subheadline.copyWith(
                                    color: AppColors.textTertiary(modalContext),
                                  ),
                                ),
                              ),
                            )
                          else
                            for (final a in allocations)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4.0,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Allocated at ${a.createdAt.toIso8601String().substring(0, 10)}',
                                        style: AppTypography.body,
                                      ),
                                    ),
                                    AppMoneyDisplay(
                                      money: a.amount,
                                      style: AppTypography.body.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                        ],
                      ),
                    ),

                    // Modal Actions
                    if (unallocatedCredit.isPositive &&
                        widget.dependencies.hasPermission(
                          AppPermission.manageAllocations,
                        ))
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: SizedBox(
                          width: double.infinity,
                          child: AppButton(
                            text: 'Allocate Payment Funds',
                            variant: AppButtonVariant.primary,
                            onPressed: () async {
                              Navigator.pop(modalContext);
                              final allocated = await AllocationDialog.show(
                                context,
                                clientRepository:
                                    widget.dependencies.clientRepository,
                                invoiceRepository:
                                    widget.dependencies.invoiceRepository,
                                paymentRepository:
                                    widget.dependencies.paymentRepository,
                                paymentAllocationRepository: widget
                                    .dependencies
                                    .paymentAllocationRepository,
                                allocatePayment:
                                    widget.dependencies.allocatePayment,
                                preselectedPaymentId: payment.id,
                              );
                              if (allocated != null) {
                                widget.dependencies.notifyDataChanged();
                                _viewModel.refresh();
                              }
                            },
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppAtmosphericBackground(
      accentColor: const Color(0xFF10B981),
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
                  largeTitle: const Text('Payments'),
                  backgroundColor: AppColors.canvas(
                    context,
                  ).withValues(alpha: 0.76),
                  border: Border(
                    bottom: BorderSide(
                      color: AppColors.separator(context),
                      width: 0.5,
                    ),
                  ),
                  trailing: widget.dependencies.hasPermission(
                        AppPermission.recordPayments,
                      )
                      ? CupertinoButton(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(
                            AppSpacing.minTouchTarget,
                            AppSpacing.minTouchTarget,
                          ),
                          child: const Icon(
                            CupertinoIcons.plus_circle_fill,
                            size: 26,
                          ),
                          onPressed: () async {
                            final payment = await PaymentFormDialog.show(
                              context,
                              clientRepository:
                                  widget.dependencies.clientRepository,
                              recordPayment: widget.dependencies.recordPayment,
                              createClient:
                                  widget.dependencies.hasPermission(
                                        AppPermission.manageClients,
                                      )
                                      ? widget.dependencies.createClient
                                      : null,
                              updateClient:
                                  widget.dependencies.hasPermission(
                                        AppPermission.manageClients,
                                      )
                                      ? widget.dependencies.updateClient
                                      : null,
                            );
                            if (payment != null) {
                              widget.dependencies.notifyDataChanged();
                              _viewModel.refresh();
                            }
                          },
                        )
                      : null,
                ),

              CupertinoSliverRefreshControl(onRefresh: _viewModel.refresh),

              // Search Box
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: AppSearchField(
                    placeholder: 'Search payments by client...',
                    onChanged: _viewModel.search,
                  ),
                ),
              ),

              // Content List or Empty State
              if (state.isLoading)
                const SliverFillRemaining(
                  child: Center(child: CupertinoActivityIndicator(radius: 14)),
                )
              else if (state.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: AppEmptyState(
                      icon: CupertinoIcons.arrow_down_circle,
                      title: 'No Payments Yet',
                      description:
                          'Record incoming payments to manage client balances.',
                      actionLabel: 'Record First Payment',
                      onAction: () async {
                        final payment = await PaymentFormDialog.show(
                          context,
                          clientRepository:
                              widget.dependencies.clientRepository,
                          recordPayment: widget.dependencies.recordPayment,
                          createClient: widget.dependencies.createClient,
                          updateClient: widget.dependencies.updateClient,
                        );
                        if (payment != null) {
                          widget.dependencies.notifyDataChanged();
                          _viewModel.refresh();
                        }
                      },
                    ),
                  ),
                )
              else if (state.isSearchEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: AppEmptyState(
                      icon: CupertinoIcons.search,
                      title: 'No Payments Found',
                      description: 'Try another search query.',
                      actionLabel: 'Clear Search',
                      onAction: () => _viewModel.search(''),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final payment = state.filteredPayments[index];
                      final client = state.clientsById[payment.clientId];

                      return AppStaggeredItem(
                        index: index,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: AppCard(
                            onTap: () => _showPaymentDetail(context, payment),
                            child: Row(
                              children: [
                                AppModernIcon(
                                  icon: CupertinoIcons.arrow_down_circle_fill,
                                  size: 38,
                                  iconSize: 18,
                                  showShadow: false,
                                  gradient: AppGradients.success(context),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        client?.name ?? 'Unknown Client',
                                        style: AppTypography.headline.copyWith(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: AppSpacing.xxs),
                                      Text(
                                        payment.receivedAt
                                            .toIso8601String()
                                            .substring(0, 10),
                                        style: AppTypography.caption1.copyWith(
                                          color: AppColors.textSecondary(
                                            context,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    AppMoneyDisplay(
                                      money: payment.amount,
                                      style: AppTypography.headline.copyWith(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: AppColors.success(context),
                                      ),
                                    ),
                                    if (payment.notes != null &&
                                        payment.notes!.isNotEmpty) ...[
                                      const SizedBox(height: AppSpacing.xxs),
                                      Text(
                                        payment.notes!,
                                        style: AppTypography.caption2.copyWith(
                                          color: AppColors.textTertiary(
                                            context,
                                          ),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }, childCount: state.filteredPayments.length),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
