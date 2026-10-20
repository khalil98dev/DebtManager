import 'package:application/application.dart';
import 'package:domain/domain.dart';
import 'package:flutter/cupertino.dart';

import '../../../components/buttons/app_button.dart';
import '../../../components/buttons/app_icon_button.dart';
import '../../../components/feedback/app_blurred_dialog.dart';
import '../../../components/inputs/app_money_field.dart';
import '../../../components/inputs/app_text_field.dart';
import '../../../components/surfaces/app_modern_icon.dart';
import '../../../tokens/app_colors.dart';
import '../../../tokens/app_gradients.dart';
import '../../../tokens/app_radii.dart';
import '../../../tokens/app_spacing.dart';
import '../../../tokens/app_typography.dart';
import '../../clients/widgets/client_form_dialog.dart';
import '../../clients/widgets/client_select_dialog.dart';
import '../view_models/payment_form_state.dart';
import '../view_models/payment_form_view_model.dart';

/// Modal dialog for recording received payments from clients with frosted glass backdrop blur.
class PaymentFormDialog extends StatefulWidget {
  const PaymentFormDialog({
    super.key,
    required this.clientRepository,
    required this.recordPayment,
    this.createClient,
    this.updateClient,
    this.preselectedClientId,
  });

  final ClientRepository clientRepository;
  final RecordPayment recordPayment;
  final CreateClient? createClient;
  final UpdateClient? updateClient;
  final ClientId? preselectedClientId;

  static Future<Payment?> show(
    BuildContext context, {
    required ClientRepository clientRepository,
    required RecordPayment recordPayment,
    CreateClient? createClient,
    UpdateClient? updateClient,
    ClientId? preselectedClientId,
  }) {
    return showAppBlurredDialog<Payment>(
      context: context,
      barrierDismissible: true,
      builder: (context) => PaymentFormDialog(
        clientRepository: clientRepository,
        recordPayment: recordPayment,
        createClient: createClient,
        updateClient: updateClient,
        preselectedClientId: preselectedClientId,
      ),
    );
  }

  @override
  State<PaymentFormDialog> createState() => _PaymentFormDialogState();
}

class _PaymentFormDialogState extends State<PaymentFormDialog> {
  late final PaymentFormViewModel _viewModel;
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _viewModel = PaymentFormViewModel(
      clientRepository: widget.clientRepository,
      recordPayment: widget.recordPayment,
      preselectedClientId: widget.preselectedClientId,
    );
    _notesController = TextEditingController();
    _viewModel.initialize();
  }

  @override
  void dispose() {
    _notesController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppBlurredDialogContainer(
      maxWidth: 500,
      child: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          final state = _viewModel.state;

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: [
                    const AppModernIcon(
                      icon: CupertinoIcons.arrow_down_circle_fill,
                      size: 40,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Record Received Payment',
                            style: AppTypography.headline.copyWith(
                              fontSize: 18,
                              color: AppColors.textPrimary(context),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            'Received payments can be allocated to issued invoices.',
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

              // Form Fields
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Client Selector
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Client',
                          style: AppTypography.caption1.copyWith(
                            color: AppColors.textSecondary(context),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Container(
                          height: 42,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceSecondary(context),
                            borderRadius: AppRadii.smRadius,
                            border: Border.all(
                              color: state.clientError != null
                                  ? AppColors.destructive(context)
                                  : AppColors.border(context),
                            ),
                          ),
                          child: state.status == PaymentFormStatus.loading
                              ? const Align(
                                  alignment: Alignment.centerLeft,
                                  child: Row(
                                    children: [
                                      CupertinoActivityIndicator(radius: 7),
                                      SizedBox(width: AppSpacing.xs),
                                      Text(
                                        'Loading clients...',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ],
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
                                                (state.availableClients.isEmpty
                                                    ? 'No clients found (tap to add / select)'
                                                    : 'Select a client...'),
                                            style: AppTypography.body.copyWith(
                                              color:
                                                  state.selectedClient != null
                                                  ? AppColors.textPrimary(
                                                      context,
                                                    )
                                                  : AppColors.textTertiary(
                                                      context,
                                                    ),
                                              fontWeight:
                                                  state.selectedClient != null
                                                  ? FontWeight.w600
                                                  : FontWeight.normal,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Icon(
                                          CupertinoIcons
                                              .chevron_up_chevron_down,
                                          size: 14,
                                          color: AppColors.textTertiary(
                                            context,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                        ),
                        if (state.clientError != null) ...[
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            state.clientError!,
                            style: AppTypography.caption2.copyWith(
                              color: AppColors.destructive(context),
                            ),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // Amount Field
                    AppMoneyField(
                      label: 'Received Amount',
                      currency: state.currency,
                      errorText: state.amountError,
                      onMoneyChanged: (money) {
                        _viewModel.onAmountChanged(
                          money?.format(includeSymbol: false) ?? '',
                        );
                      },
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // Notes Field
                    AppTextField(
                      controller: _notesController,
                      label: 'Reference / Payment Method Notes',
                      placeholder:
                          'Check #123, Cash receipt, Bank wire transfer...',
                      maxLines: 2,
                      onChanged: _viewModel.onNotesChanged,
                    ),

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
                      text: 'Record Payment',
                      variant: AppButtonVariant.primary,
                      isLoading: state.isSubmitting,
                      onPressed: () async {
                        final saved = await _viewModel.submit();
                        if (saved != null && context.mounted) {
                          Navigator.of(context).pop(saved);
                        }
                      },
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

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return '?';
    if (parts.length == 1) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  Future<void> _showClientPicker(BuildContext context) async {
    await _viewModel.refreshClients();
    if (!context.mounted) return;
    final selected = await ClientSelectDialog.show(
      context: context,
      clients: _viewModel.state.availableClients,
      selectedClient: _viewModel.state.selectedClient,
      title: 'Select Client',
      subtitle: 'Choose a client for this incoming payment',
      onCreateClient:
          (widget.createClient != null && widget.updateClient != null)
          ? () => ClientFormDialog.show(
              context,
              createClient: widget.createClient!,
              updateClient: widget.updateClient!,
            )
          : null,
    );
    if (selected != null && mounted) {
      _viewModel.onClientSelected(selected);
    }
  }
}
