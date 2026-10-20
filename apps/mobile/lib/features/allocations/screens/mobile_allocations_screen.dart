import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/cupertino.dart';

/// Mobile Payment Allocations list screen allowing inspection and execution of allocations.
class MobileAllocationsScreen extends StatefulWidget {
  const MobileAllocationsScreen({super.key, required this.dependencies});

  final AppDependencies dependencies;

  @override
  State<MobileAllocationsScreen> createState() =>
      _MobileAllocationsScreenState();
}

class _MobileAllocationsScreenState extends State<MobileAllocationsScreen> {
  List<PaymentAllocation> _allocations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllocations();
  }

  Future<void> _loadAllocations() async {
    setState(() => _isLoading = true);
    try {
      final list = await widget.dependencies.paymentAllocationRepository
          .getAll();
      final sorted = List<PaymentAllocation>.from(list)
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      setState(() {
        _allocations = sorted;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.dependencies.hasPermission(AppPermission.manageAllocations)) {
      return AppAtmosphericBackground(
        accentColor: const Color(0xFF06B6D4),
        child: CupertinoPageScaffold(
          backgroundColor: CupertinoColors.transparent,
          navigationBar: CupertinoNavigationBar(
            middle: const Text('Payment Allocations'),
            backgroundColor: AppColors.canvas(context).withValues(alpha: 0.76),
          ),
          child: SafeArea(
            child: AppAccessDeniedState(
              requiredPermission: AppPermission.manageAllocations,
              currentRoleName:
                  widget.dependencies.authViewModel.state.currentRole?.name,
              title: 'Payment Allocations Restricted',
            ),
          ),
        ),
      );
    }

    return AppAtmosphericBackground(
      accentColor: const Color(0xFF06B6D4),
      child: CupertinoPageScaffold(
        backgroundColor: CupertinoColors.transparent,
        navigationBar: CupertinoNavigationBar(
          middle: const Text('Payment Allocations'),
          backgroundColor: AppColors.canvas(context).withValues(alpha: 0.76),
          border: Border(
            bottom: BorderSide(color: AppColors.separator(context), width: 0.5),
          ),
          trailing: CupertinoButton(
            padding: EdgeInsets.zero,
            minimumSize: const Size(
              AppSpacing.minTouchTarget,
              AppSpacing.minTouchTarget,
            ),
            child: const Icon(CupertinoIcons.plus_circle_fill, size: 26),
            onPressed: () async {
              final allocated = await AllocationDialog.show(
                context,
                clientRepository: widget.dependencies.clientRepository,
                invoiceRepository: widget.dependencies.invoiceRepository,
                paymentRepository: widget.dependencies.paymentRepository,
                paymentAllocationRepository:
                    widget.dependencies.paymentAllocationRepository,
                allocatePayment: widget.dependencies.allocatePayment,
              );
              if (allocated != null) _loadAllocations();
            },
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CupertinoActivityIndicator(radius: 14))
              : _allocations.isEmpty
              ? Center(
                  child: AppEmptyState(
                    icon: CupertinoIcons.arrow_right_arrow_left,
                    title: 'No Allocations Yet',
                    description:
                        'Allocate available client payments against issued invoices.',
                    actionLabel: 'Execute First Allocation',
                    onAction: () async {
                      final allocated = await AllocationDialog.show(
                        context,
                        clientRepository: widget.dependencies.clientRepository,
                        invoiceRepository:
                            widget.dependencies.invoiceRepository,
                        paymentRepository:
                            widget.dependencies.paymentRepository,
                        paymentAllocationRepository:
                            widget.dependencies.paymentAllocationRepository,
                        allocatePayment: widget.dependencies.allocatePayment,
                      );
                      if (allocated != null) _loadAllocations();
                    },
                  ),
                )
              : CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  slivers: [
                    CupertinoSliverRefreshControl(onRefresh: _loadAllocations),
                    SliverPadding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final a = _allocations[index];

                          return AppStaggeredItem(
                            index: index,
                            child: Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppSpacing.sm,
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
                                            'Allocation ID: ${a.id.value.substring(0, 8)}...',
                                            style: AppTypography.subheadline
                                                .copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                          const SizedBox(height: AppSpacing.xxs),
                                          Text(
                                            'To Invoice: ${a.invoiceId.value.substring(0, 8)}... • From Payment: ${a.paymentId.value.substring(0, 8)}...',
                                            style: AppTypography.caption1
                                                .copyWith(
                                                  color:
                                                      AppColors.textSecondary(
                                                        context,
                                                      ),
                                                ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: AppSpacing.xxs),
                                          Text(
                                            a.createdAt
                                                .toIso8601String()
                                                .substring(0, 16),
                                            style: AppTypography.caption2
                                                .copyWith(
                                                  color: AppColors.textTertiary(
                                                    context,
                                                  ),
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    AppMoneyDisplay(
                                      money: a.amount,
                                      style: AppTypography.headline.copyWith(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: AppColors.primaryAccent(context),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }, childCount: _allocations.length),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
