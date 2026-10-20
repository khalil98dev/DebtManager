import 'package:application/application.dart';
import 'package:domain/domain.dart';
import 'package:flutter/cupertino.dart';

import '../../../components/buttons/app_button.dart';
import '../../../components/buttons/app_icon_button.dart';
import '../../../components/feedback/app_blurred_dialog.dart';
import '../../../components/inputs/app_money_field.dart';
import '../../../components/surfaces/app_badge.dart';
import '../../../components/surfaces/app_modern_icon.dart';
import '../../../tokens/app_colors.dart';
import '../../../tokens/app_gradients.dart';
import '../../../tokens/app_radii.dart';
import '../../../tokens/app_spacing.dart';
import '../../../tokens/app_typography.dart';
import '../../clients/widgets/client_select_dialog.dart';
import '../view_models/allocation_workflow_state.dart';
import '../view_models/allocation_workflow_view_model.dart';

/// Guided workflow modal dialog for allocating client payments to issued invoices.
class AllocationDialog extends StatefulWidget {
  const AllocationDialog({
    super.key,
    required this.clientRepository,
    required this.invoiceRepository,
    required this.paymentRepository,
    required this.paymentAllocationRepository,
    required this.allocatePayment,
    this.preselectedClientId,
    this.preselectedPaymentId,
    this.preselectedInvoiceId,
  });

  final ClientRepository clientRepository;
  final InvoiceRepository invoiceRepository;
  final PaymentRepository paymentRepository;
  final PaymentAllocationRepository paymentAllocationRepository;
  final AllocatePayment allocatePayment;
  final ClientId? preselectedClientId;
  final PaymentId? preselectedPaymentId;
  final InvoiceId? preselectedInvoiceId;

  static Future<PaymentAllocation?> show(
    BuildContext context, {
    required ClientRepository clientRepository,
    required InvoiceRepository invoiceRepository,
    required PaymentRepository paymentRepository,
    required PaymentAllocationRepository paymentAllocationRepository,
    required AllocatePayment allocatePayment,
    ClientId? preselectedClientId,
    PaymentId? preselectedPaymentId,
    InvoiceId? preselectedInvoiceId,
  }) {
    return showAppBlurredDialog<PaymentAllocation>(
      context: context,
      barrierDismissible: true,
      builder: (context) => AllocationDialog(
        clientRepository: clientRepository,
        invoiceRepository: invoiceRepository,
        paymentRepository: paymentRepository,
        paymentAllocationRepository: paymentAllocationRepository,
        allocatePayment: allocatePayment,
        preselectedClientId: preselectedClientId,
        preselectedPaymentId: preselectedPaymentId,
        preselectedInvoiceId: preselectedInvoiceId,
      ),
    );
  }

  @override
  State<AllocationDialog> createState() => _AllocationDialogState();
}

class _AllocationDialogState extends State<AllocationDialog> {
  late final AllocationWorkflowViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = AllocationWorkflowViewModel(
      clientRepository: widget.clientRepository,
      invoiceRepository: widget.invoiceRepository,
      paymentRepository: widget.paymentRepository,
      paymentAllocationRepository: widget.paymentAllocationRepository,
      allocatePayment: widget.allocatePayment,
      preselectedClientId: widget.preselectedClientId,
      preselectedPaymentId: widget.preselectedPaymentId,
      preselectedInvoiceId: widget.preselectedInvoiceId,
    );
    _viewModel.initialize();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppBlurredDialogContainer(
      maxWidth: 620,
      maxHeight: 780,
      child: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          final state = _viewModel.state;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: [
                    const AppModernIcon(
                      icon: CupertinoIcons.arrow_right_arrow_left,
                      size: 40,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Allocate Payment to Invoice',
                            style: AppTypography.headline.copyWith(
                              fontSize: 18,
                              color: AppColors.textPrimary(context),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            'Apply received unallocated funds against outstanding debt.',
                            style: AppTypography.caption1.copyWith(
                              color: AppColors.textSecondary(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                    AppIconButton(
                      icon: CupertinoIcons.xmark,
                      tooltip: 'Close',
                      size: 32,
                      iconSize: 16,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              Container(height: 1, color: AppColors.separator(context)),

              // Scrollable Body
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: [
                    // Client Selector
                    Text(
                      '1. Select Client',
                      style: AppTypography.caption1.copyWith(
                        color: AppColors.textSecondary(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSecondary(context),
                        borderRadius: AppRadii.smRadius,
                        border: Border.all(color: AppColors.border(context)),
                      ),
                      child: state.availableClients.isEmpty
                          ? Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'No clients with records',
                                style: AppTypography.caption1.copyWith(
                                  color: AppColors.textTertiary(context),
                                ),
                              ),
                            )
                          : MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: CupertinoButton(
                                padding: EdgeInsets.zero,
                                alignment: Alignment.centerLeft,
                                onPressed: () => _showClientPicker(context),
                                child: Row(
                                  children: [
                                    if (state.selectedClient != null) ...[
                                      Container(
                                        width: 24.0,
                                        height: 24.0,
                                        margin: const EdgeInsets.only(
                                          right: AppSpacing.xs,
                                        ),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: AppGradients.avatarFor(
                                            state.selectedClient!.name,
                                          ),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          _getInitials(
                                            state.selectedClient!.name,
                                          ),
                                          style: const TextStyle(
                                            fontSize: 10.0,
                                            fontWeight: FontWeight.w700,
                                            color: CupertinoColors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                    Expanded(
                                      child: Text(
                                        state.selectedClient?.name ??
                                            'Choose a client...',
                                        style: AppTypography.body.copyWith(
                                          color: state.selectedClient != null
                                              ? AppColors.textPrimary(context)
                                              : AppColors.textTertiary(context),
                                          fontWeight:
                                              state.selectedClient != null
                                              ? FontWeight.w600
                                              : FontWeight.normal,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Icon(
                                      CupertinoIcons.chevron_up_chevron_down,
                                      size: 14,
                                      color: AppColors.textTertiary(context),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                    ),

                    if (state.selectedClient != null) ...[
                      const SizedBox(height: AppSpacing.lg),

                      // Payment Candidates
                      Text(
                        '2. Select Unallocated Payment',
                        style: AppTypography.caption1.copyWith(
                          color: AppColors.textSecondary(context),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      if (state.candidatePayments.isEmpty)
                        _buildEmptySection(
                          context,
                          'No payments with unallocated funds available for this client.',
                        )
                      else
                        for (final cand in state.candidatePayments) ...[
                          _buildPaymentCard(
                            context,
                            cand,
                            state.selectedPayment,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                        ],

                      const SizedBox(height: AppSpacing.lg),

                      // Invoice Candidates
                      Text(
                        '3. Select Outstanding Invoice',
                        style: AppTypography.caption1.copyWith(
                          color: AppColors.textSecondary(context),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      if (state.candidateInvoices.isEmpty)
                        _buildEmptySection(
                          context,
                          'No issued invoices with remaining balance for this client.',
                        )
                      else
                        for (final cand in state.candidateInvoices) ...[
                          _buildInvoiceCard(
                            context,
                            cand,
                            state.selectedInvoice,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                        ],

                      // Allocation Amount Input
                      if (state.selectedPayment != null &&
                          state.selectedInvoice != null) ...[
                        const SizedBox(height: AppSpacing.lg),
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: AppColors.canvas(context),
                            borderRadius: AppRadii.mdRadius,
                            border: Border.all(
                              color: AppColors.primaryAccent(
                                context,
                              ).withValues(alpha: 0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Allocation Amount',
                                    style: AppTypography.caption1.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary(context),
                                    ),
                                  ),
                                  if (state.maxAllocatableAmount != null)
                                    CupertinoButton(
                                      padding: EdgeInsets.zero,
                                      minimumSize: const Size(24, 24),
                                      onPressed: _viewModel.allocateMaximum,
                                      child: Text(
                                        'Max: ${state.maxAllocatableAmount!.format()}',
                                        style: AppTypography.caption1.copyWith(
                                          color: AppColors.primaryAccent(
                                            context,
                                          ),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              AppMoneyField(
                                label: 'Allocation Amount',
                                currency:
                                    state.selectedPayment!.payment.currency,
                                initialValue: state.amountText,
                                errorText: state.amountError,
                                onMoneyChanged: (money) {
                                  _viewModel.onAmountChanged(
                                    money?.format(includeSymbol: false) ?? '',
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],

                    if (state.errorMessage != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: AppColors.destructive(
                            context,
                          ).withValues(alpha: 0.1),
                          borderRadius: AppRadii.smRadius,
                        ),
                        child: Text(
                          state.errorMessage!,
                          style: AppTypography.caption1.copyWith(
                            color: AppColors.destructive(context),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              Container(height: 1, color: AppColors.separator(context)),

              // Actions
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    AppButton(
                      text: 'Cancel',
                      variant: AppButtonVariant.plain,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    AppButton(
                      text: 'Execute Allocation',
                      variant: AppButtonVariant.primary,
                      isLoading: state.isSubmitting,
                      onPressed:
                          (state.selectedPayment != null &&
                              state.selectedInvoice != null &&
                              state.amount != null &&
                              state.amount!.isPositive)
                          ? () async {
                              final saved = await _viewModel.submit();
                              if (saved != null && context.mounted) {
                                Navigator.of(context).pop(saved);
                              }
                            }
                          : null,
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

  Widget _buildEmptySection(BuildContext context, String message) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondary(context),
        borderRadius: AppRadii.smRadius,
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Text(
        message,
        style: AppTypography.caption1.copyWith(
          color: AppColors.textTertiary(context),
        ),
      ),
    );
  }

  Widget _buildPaymentCard(
    BuildContext context,
    PaymentCandidate candidate,
    PaymentCandidate? selected,
  ) {
    final isSelected = selected?.payment.id == candidate.payment.id;
    return GestureDetector(
      onTap: () => _viewModel.onPaymentSelected(candidate),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryAccent(context).withValues(alpha: 0.08)
              : AppColors.surfaceSecondary(context),
          borderRadius: AppRadii.smRadius,
          border: Border.all(
            color: isSelected
                ? AppColors.primaryAccent(context)
                : AppColors.border(context),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Payment on ${candidate.payment.receivedAt.toIso8601String().substring(0, 10)}',
                  style: AppTypography.body.copyWith(
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                    color: AppColors.textPrimary(context),
                  ),
                ),
                Text(
                  'Total: ${candidate.payment.amount.format()}',
                  style: AppTypography.caption1.copyWith(
                    color: AppColors.textSecondary(context),
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                AppBadge(
                  label: 'Unallocated: ${candidate.remainingCapacity.format()}',
                  variant: AppBadgeVariant.success,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoiceCard(
    BuildContext context,
    InvoiceCandidate candidate,
    InvoiceCandidate? selected,
  ) {
    final isSelected = selected?.invoice.id == candidate.invoice.id;
    return GestureDetector(
      onTap: () => _viewModel.onInvoiceSelected(candidate),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryAccent(context).withValues(alpha: 0.08)
              : AppColors.surfaceSecondary(context),
          borderRadius: AppRadii.smRadius,
          border: Border.all(
            color: isSelected
                ? AppColors.primaryAccent(context)
                : AppColors.border(context),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  candidate.invoice.number,
                  style: AppTypography.body.copyWith(
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                    color: AppColors.textPrimary(context),
                  ),
                ),
                Text(
                  'Total: ${candidate.invoice.total.format()}',
                  style: AppTypography.caption1.copyWith(
                    color: AppColors.textSecondary(context),
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                AppBadge(
                  label: 'Remaining: ${candidate.remainingBalance.format()}',
                  variant: AppBadgeVariant.warning,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return '?';
    if (parts.length == 1) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  Future<void> _showClientPicker(BuildContext context) async {
    final selected = await ClientSelectDialog.show(
      context: context,
      clients: _viewModel.state.availableClients,
      selectedClient: _viewModel.state.selectedClient,
      title: 'Select Client',
      subtitle: 'Choose a client to view unsettled records',
    );
    if (selected != null && mounted) {
      _viewModel.onClientSelected(selected);
    }
  }
}
