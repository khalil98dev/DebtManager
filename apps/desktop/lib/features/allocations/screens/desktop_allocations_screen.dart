import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/cupertino.dart';

/// Desktop Payment Allocations screen showing recorded allocation history and workflow launcher.
class DesktopAllocationsScreen extends StatefulWidget {
  const DesktopAllocationsScreen({super.key, required this.dependencies});

  final AppDependencies dependencies;

  @override
  State<DesktopAllocationsScreen> createState() =>
      _DesktopAllocationsScreenState();
}

class _DesktopAllocationsScreenState extends State<DesktopAllocationsScreen> {
  List<PaymentAllocation> _allocations = [];
  Map<ClientId, Client> _clientsById = {};
  Map<InvoiceId, Invoice> _invoicesById = {};
  Map<PaymentId, Payment> _paymentsById = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    widget.dependencies.dataRevision.addListener(_onDataChanged);
  }

  @override
  void dispose() {
    widget.dependencies.dataRevision.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    if (mounted) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final allocs = await widget.dependencies.paymentAllocationRepository
        .getAll();
    final clients = await widget.dependencies.clientRepository.getAll();
    final invoices = await widget.dependencies.invoiceRepository.getAll();
    final payments = await widget.dependencies.paymentRepository.getAll();

    if (mounted) {
      setState(() {
        _allocations = List.from(allocs)
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        _clientsById = {for (final c in clients) c.id: c};
        _invoicesById = {for (final i in invoices) i.id: i};
        _paymentsById = {for (final p in payments) p.id: p};
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.dependencies.hasPermission(AppPermission.manageAllocations)) {
      return AppAtmosphericBackground(
        accentColor: const Color(0xFF5856D6),
        child: AppAccessDeniedState(
          requiredPermission: AppPermission.manageAllocations,
          currentRoleName:
              widget.dependencies.authViewModel.state.currentRole?.name,
          title: 'Payment Allocations Restricted',
        ),
      );
    }

    return AppAtmosphericBackground(
      accentColor: const Color(0xFF5856D6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          AppPageHeader(
            title: 'Payment Allocations',
            subtitle:
                'Apply customer payments to issued invoices to extinguish debt',
            badgeCount: !_isLoading ? _allocations.length : null,
            actions: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppButton(
                  text: 'Refresh',
                  icon: const Icon(CupertinoIcons.arrow_clockwise, size: 14),
                  size: AppButtonSize.compact,
                  variant: AppButtonVariant.secondary,
                  isLoading: _isLoading,
                  onPressed: _loadData,
                ),
                const SizedBox(width: AppSpacing.sm),
                AppButton(
                  text: 'New Allocation',
                  icon: const Icon(
                    CupertinoIcons.arrow_right_arrow_left,
                    size: 14,
                  ),
                  size: AppButtonSize.compact,
                  variant: AppButtonVariant.primary,
                  onPressed: () async {
                    final allocation = await AllocationDialog.show(
                      context,
                      clientRepository: widget.dependencies.clientRepository,
                      invoiceRepository: widget.dependencies.invoiceRepository,
                      paymentRepository: widget.dependencies.paymentRepository,
                      paymentAllocationRepository:
                          widget.dependencies.paymentAllocationRepository,
                      allocatePayment: widget.dependencies.allocatePayment,
                    );
                    if (allocation != null) {
                      widget.dependencies.notifyDataChanged();
                      _loadData();
                    }
                  },
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CupertinoActivityIndicator(radius: 14))
                : _allocations.isEmpty
                ? Center(
                    child: AppEmptyState(
                      icon: CupertinoIcons.arrow_right_arrow_left,
                      title: 'No Payment Allocations',
                      description:
                          'Allocate available customer payment funds directly against issued invoices.',
                      actionText: 'Execute First Allocation',
                      onAction: () async {
                        final allocation = await AllocationDialog.show(
                          context,
                          clientRepository:
                              widget.dependencies.clientRepository,
                          invoiceRepository:
                              widget.dependencies.invoiceRepository,
                          paymentRepository:
                              widget.dependencies.paymentRepository,
                          paymentAllocationRepository:
                              widget.dependencies.paymentAllocationRepository,
                          allocatePayment: widget.dependencies.allocatePayment,
                        );
                        if (allocation != null) {
                          widget.dependencies.notifyDataChanged();
                          _loadData();
                        }
                      },
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface(context),
                          borderRadius: AppRadii.lgRadius,
                          border: Border.all(color: AppColors.border(context)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
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
                                      'INVOICE #',
                                      style: AppTypography.caption2.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textSecondary(context),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      'ALLOCATED DATE',
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
                                        'ALLOCATED AMOUNT',
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

                            // Allocations Rows
                            for (int i = 0; i < _allocations.length; i++) ...[
                              AppStaggeredItem(
                                index: i,
                                child: _buildAllocationRow(
                                  context,
                                  _allocations[i],
                                ),
                              ),
                              Container(
                                height: 1,
                                color: AppColors.separator(context),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllocationRow(BuildContext context, PaymentAllocation alloc) {
    final payment = _paymentsById[alloc.paymentId];
    final invoice = _invoicesById[alloc.invoiceId];
    final client = invoice != null
        ? _clientsById[invoice.clientId]
        : (payment != null ? _clientsById[payment.clientId] : null);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  client?.name ??
                      'Client ID: ${alloc.paymentId.value.substring(0, 8)}...',
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary(context),
                  ),
                ),
                Text(
                  payment != null
                      ? 'Payment: ${payment.amount.format()} (${payment.receivedAt.toIso8601String().substring(0, 10)})'
                      : 'Payment Ref: ${alloc.paymentId.value.substring(0, 8)}...',
                  style: AppTypography.caption2.copyWith(
                    color: AppColors.textTertiary(context),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              invoice?.number ?? alloc.invoiceId.value.substring(0, 8),
              style: AppTypography.body,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              alloc.createdAt.toIso8601String().substring(0, 10),
              style: AppTypography.caption1.copyWith(
                color: AppColors.textSecondary(context),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: AppMoneyDisplay(
                money: alloc.amount,
                style: AppTypography.body.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary(context),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
