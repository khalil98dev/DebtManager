import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/cupertino.dart';

/// Desktop-density Payments management and details screen.
class DesktopPaymentsScreen extends StatefulWidget {
  const DesktopPaymentsScreen({super.key, required this.dependencies});

  final AppDependencies dependencies;

  @override
  State<DesktopPaymentsScreen> createState() => _DesktopPaymentsScreenState();
}

class _DesktopPaymentsScreenState extends State<DesktopPaymentsScreen> {
  late final PaymentListViewModel _listViewModel;
  PaymentDetailViewModel? _detailViewModel;
  Payment? _selectedPayment;

  @override
  void initState() {
    super.initState();
    _listViewModel = PaymentListViewModel(
      paymentRepository: widget.dependencies.paymentRepository,
      clientRepository: widget.dependencies.clientRepository,
    );
    _listViewModel.loadPayments();
    widget.dependencies.dataRevision.addListener(_onDataChanged);
  }

  @override
  void dispose() {
    widget.dependencies.dataRevision.removeListener(_onDataChanged);
    _listViewModel.dispose();
    _detailViewModel?.dispose();
    super.dispose();
  }

  void _onDataChanged() {
    if (mounted) {
      _refresh();
    }
  }

  void _onPaymentSelected(Payment payment) {
    setState(() {
      _selectedPayment = payment;
      _detailViewModel?.dispose();
      _detailViewModel = PaymentDetailViewModel(
        paymentId: payment.id,
        paymentRepository: widget.dependencies.paymentRepository,
        clientRepository: widget.dependencies.clientRepository,
        paymentAllocationRepository:
            widget.dependencies.paymentAllocationRepository,
      );
      _detailViewModel!.loadDetails();
    });
  }

  Future<void> _refresh() async {
    await _listViewModel.loadPayments();
    if (_selectedPayment != null && _detailViewModel != null) {
      await _detailViewModel!.refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppAtmosphericBackground(
      child: ListenableBuilder(
        listenable: _listViewModel,
        builder: (context, _) {
          final listState = _listViewModel.state;

          if (_selectedPayment == null &&
              listState.filteredPayments.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted &&
                  _selectedPayment == null &&
                  listState.filteredPayments.isNotEmpty) {
                _onPaymentSelected(listState.filteredPayments.first);
              }
            });
          } else if (_selectedPayment != null &&
              !listState.filteredPayments.any(
                (p) => p.id == _selectedPayment!.id,
              )) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                if (listState.filteredPayments.isNotEmpty) {
                  _onPaymentSelected(listState.filteredPayments.first);
                } else {
                  setState(() => _selectedPayment = null);
                }
              }
            });
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Toolbar
              AppPageHeader(
                title: 'Payments',
                subtitle:
                    'Record received funds, unallocated customer credit, and allocations',
                badgeCount: listState.isLoaded ? listState.totalCount : null,
                actions: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 280,
                      child: AppSearchField(
                        placeholder: 'Search client or reference notes...',
                        onChanged: _listViewModel.search,
                      ),
                    ),
                    if (widget.dependencies.hasPermission(
                      AppPermission.recordPayments,
                    )) ...[
                      const SizedBox(width: AppSpacing.md),
                      AppButton(
                        text: 'Record Payment',
                        icon: const Icon(CupertinoIcons.plus, size: 14),
                        size: AppButtonSize.compact,
                        onPressed: () async {
                          final payment = await PaymentFormDialog.show(
                            context,
                            clientRepository:
                                widget.dependencies.clientRepository,
                            recordPayment: widget.dependencies.recordPayment,
                            createClient: widget.dependencies.hasPermission(
                                  AppPermission.manageClients,
                                )
                                ? widget.dependencies.createClient
                                : null,
                            updateClient: widget.dependencies.hasPermission(
                                  AppPermission.manageClients,
                                )
                                ? widget.dependencies.updateClient
                                : null,
                          );
                          if (payment != null) {
                            widget.dependencies.notifyDataChanged();
                            await _refresh();
                            _onPaymentSelected(payment);
                          }
                        },
                      ),
                    ],
                  ],
                ),
              ),

              // Split View
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // List
                    SizedBox(
                      width: 380,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface(
                            context,
                          ).withValues(alpha: 0.72),
                          border: Border(
                            right: BorderSide(
                              color: AppColors.separator(context),
                              width: 1.0,
                            ),
                          ),
                        ),
                        child: _buildPaymentsList(context, listState),
                      ),
                    ),

                    // Detail with smooth cross-fade
                    Expanded(
                      child: AnimatedContentSwitcher(
                        transitionType: ContentTransitionType.fade,
                        child: Container(
                          key: ValueKey(
                            'payment_detail_${_selectedPayment?.id.value ?? "none"}',
                          ),
                          child: _buildPaymentDetailPanel(context),
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

  Widget _buildPaymentsList(BuildContext context, PaymentListViewState state) {
    if (state.isLoading) {
      return const Center(child: CupertinoActivityIndicator(radius: 12));
    }

    if (state.isEmpty) {
      return Center(
        child: AppEmptyState(
          icon: CupertinoIcons.arrow_down_circle,
          title: 'No Payments Recorded',
          description: 'Record incoming payments to manage client balances.',
          actionLabel: 'Record First Payment',
          onAction: () async {
            final payment = await PaymentFormDialog.show(
              context,
              clientRepository: widget.dependencies.clientRepository,
              recordPayment: widget.dependencies.recordPayment,
              createClient: widget.dependencies.createClient,
              updateClient: widget.dependencies.updateClient,
            );
            if (payment != null) {
              widget.dependencies.notifyDataChanged();
              await _refresh();
              _onPaymentSelected(payment);
            }
          },
        ),
      );
    }

    if (state.isSearchEmpty) {
      return Center(
        child: AppEmptyState(
          icon: CupertinoIcons.search,
          title: 'No Matching Payments',
          description: 'Try another search term or clear your search query.',
          actionLabel: 'Clear Search',
          onAction: () => _listViewModel.search(''),
        ),
      );
    }

    return ListView.separated(
      itemCount: state.filteredPayments.length,
      separatorBuilder: (_, _) =>
          Container(height: 1, color: AppColors.separator(context)),
      itemBuilder: (context, index) {
        final payment = state.filteredPayments[index];
        final client = state.clientsById[payment.clientId];
        final isSelected = _selectedPayment?.id == payment.id;

        return AppStaggeredItem(
          index: index,
          child: AnimatedSelectionContainer(
            isSelected: isSelected,
            onTap: () => _onPaymentSelected(payment),
            padding: const EdgeInsets.all(AppSpacing.md),
            borderRadius: BorderRadius.zero,
            selectedBackgroundColor: AppColors.primaryAccent(
              context,
            ).withValues(alpha: 0.08),
            unselectedBackgroundColor: CupertinoColors.transparent,
            selectedBorderColor: CupertinoColors.transparent,
            unselectedBorderColor: CupertinoColors.transparent,
            showLeadingIndicator: true,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        client?.name ?? 'Unknown Client',
                        style: AppTypography.body.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? AppColors.primaryAccent(context)
                              : AppColors.textPrimary(context),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        'Received: ${payment.receivedAt.toIso8601String().substring(0, 10)}',
                        style: AppTypography.caption1.copyWith(
                          color: AppColors.textSecondary(context),
                        ),
                      ),
                      if (payment.notes != null)
                        Text(
                          payment.notes!,
                          style: AppTypography.caption2.copyWith(
                            color: AppColors.textTertiary(context),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                AppMoneyDisplay(
                  money: payment.amount,
                  style: AppTypography.headline.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.success(context),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPaymentDetailPanel(BuildContext context) {
    if (_selectedPayment == null || _detailViewModel == null) {
      return Center(
        child: AppEmptyState(
          icon: CupertinoIcons.arrow_down_circle,
          title: 'Select a Payment',
          description:
              'Choose a payment from the list to view allocation history.',
        ),
      );
    }

    return ListenableBuilder(
      listenable: _detailViewModel!,
      builder: (context, _) {
        final detailState = _detailViewModel!.state;
        final payment = detailState.payment ?? _selectedPayment!;
        final client = detailState.client;

        return ListView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          children: [
            // Payment Detail Header Card
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.surface(context),
                borderRadius: AppRadii.lgRadius,
                border: Border.all(color: AppColors.border(context)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              AppMoneyDisplay(
                                money: payment.amount,
                                style: AppTypography.largeTitle.copyWith(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.success(context),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              AppBadge(
                                label: 'RECEIVED',
                                variant: AppBadgeVariant.success,
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            'Client: ${client?.name ?? "..."}',
                            style: AppTypography.headline.copyWith(
                              fontSize: 15,
                              color: AppColors.textSecondary(context),
                            ),
                          ),
                        ],
                      ),
                      // Action button
                      if (widget.dependencies.hasPermission(
                        AppPermission.manageAllocations,
                      ))
                        AppButton(
                          text: 'Allocate Funds',
                          icon: const Icon(
                            CupertinoIcons.arrow_right_arrow_left,
                            size: 14,
                          ),
                          size: AppButtonSize.compact,
                          variant: AppButtonVariant.primary,
                          onPressed: () async {
                            final allocation = await AllocationDialog.show(
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
                              preselectedClientId: payment.clientId,
                              preselectedPaymentId: payment.id,
                            );
                            if (allocation != null) {
                              widget.dependencies.notifyDataChanged();
                              await _refresh();
                            }
                          },
                        ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.md),
                  Container(height: 1, color: AppColors.separator(context)),
                  const SizedBox(height: AppSpacing.md),

                  // Metadata row
                  Row(
                    children: [
                      _buildMetaField(
                        context,
                        'Received Date',
                        payment.receivedAt.toIso8601String().substring(0, 10),
                      ),
                      const SizedBox(width: AppSpacing.xl),
                      _buildMetaField(
                        context,
                        'Unallocated Capacity',
                        detailState.unallocatedCredit.format(),
                      ),
                      const SizedBox(width: AppSpacing.xl),
                      _buildMetaField(
                        context,
                        'Total Allocated',
                        detailState.totalAllocated.format(),
                      ),
                      const SizedBox(width: AppSpacing.xl),
                      if (payment.notes != null)
                        Expanded(
                          child: _buildMetaField(
                            context,
                            'Notes / Memo',
                            payment.notes!,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Allocations History Card
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
                    child: Text(
                      'Allocations to Invoices',
                      style: AppTypography.headline.copyWith(
                        fontSize: 16,
                        color: AppColors.textPrimary(context),
                      ),
                    ),
                  ),
                  Container(height: 1, color: AppColors.separator(context)),

                  if (detailState.allocations.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Center(
                        child: Text(
                          'No allocations applied from this payment yet.',
                          style: AppTypography.caption1.copyWith(
                            color: AppColors.textTertiary(context),
                          ),
                        ),
                      ),
                    )
                  else
                    for (final alloc in detailState.allocations) ...[
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Applied to Invoice ${alloc.invoiceId.value.substring(0, 8)}...',
                                  style: AppTypography.body.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  'Allocated on ${alloc.createdAt.toIso8601String().substring(0, 10)}',
                                  style: AppTypography.caption2.copyWith(
                                    color: AppColors.textSecondary(context),
                                  ),
                                ),
                              ],
                            ),
                            AppMoneyDisplay(
                              money: alloc.amount,
                              style: AppTypography.body.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(height: 1, color: AppColors.separator(context)),
                    ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMetaField(BuildContext context, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTypography.caption2.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textTertiary(context),
          ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          value,
          style: AppTypography.caption1.copyWith(
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary(context),
          ),
        ),
      ],
    );
  }
}
