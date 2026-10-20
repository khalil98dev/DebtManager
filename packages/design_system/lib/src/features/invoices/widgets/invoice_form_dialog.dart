import 'package:application/application.dart';
import 'package:domain/domain.dart';
import 'package:flutter/cupertino.dart';

import '../../../components/buttons/app_button.dart';
import '../../../components/buttons/app_icon_button.dart';
import '../../../components/feedback/app_blurred_dialog.dart';
import '../../../components/inputs/app_money_field.dart';
import '../../../components/inputs/app_text_field.dart';
import '../../../components/surfaces/app_badge.dart';
import '../../../components/surfaces/app_modern_icon.dart';
import '../../../components/surfaces/app_money_display.dart';
import '../../../tokens/app_colors.dart';
import '../../../tokens/app_durations.dart';
import '../../../tokens/app_gradients.dart';
import '../../../tokens/app_radii.dart';
import '../../../tokens/app_spacing.dart';
import '../../../tokens/app_typography.dart';
import '../../clients/widgets/client_form_dialog.dart';
import '../../clients/widgets/client_select_dialog.dart';
import '../view_models/invoice_form_state.dart';
import '../view_models/invoice_form_view_model.dart';

/// Modal dialog for creating and editing draft invoices with frosted glass blur backdrop.
class InvoiceFormDialog extends StatefulWidget {
  const InvoiceFormDialog({
    super.key,
    required this.clientRepository,
    required this.createInvoice,
    required this.updateInvoiceDraft,
    this.issueInvoice,
    this.createClient,
    this.updateClient,
    this.initialInvoice,
    this.preselectedClientId,
  });

  final ClientRepository clientRepository;
  final CreateInvoice createInvoice;
  final UpdateInvoiceDraft updateInvoiceDraft;
  final IssueInvoice? issueInvoice;
  final CreateClient? createClient;
  final UpdateClient? updateClient;
  final Invoice? initialInvoice;
  final ClientId? preselectedClientId;

  static Future<Invoice?> show(
    BuildContext context, {
    required ClientRepository clientRepository,
    required CreateInvoice createInvoice,
    required UpdateInvoiceDraft updateInvoiceDraft,
    IssueInvoice? issueInvoice,
    CreateClient? createClient,
    UpdateClient? updateClient,
    Invoice? initialInvoice,
    ClientId? preselectedClientId,
  }) {
    return showAppBlurredDialog<Invoice>(
      context: context,
      barrierDismissible: true,
      builder: (context) => InvoiceFormDialog(
        clientRepository: clientRepository,
        createInvoice: createInvoice,
        updateInvoiceDraft: updateInvoiceDraft,
        issueInvoice: issueInvoice,
        createClient: createClient,
        updateClient: updateClient,
        initialInvoice: initialInvoice,
        preselectedClientId: preselectedClientId,
      ),
    );
  }

  @override
  State<InvoiceFormDialog> createState() => _InvoiceFormDialogState();
}

class _InvoiceFormDialogState extends State<InvoiceFormDialog> {
  late final InvoiceFormViewModel _viewModel;
  late final TextEditingController _numberController;
  late final TextEditingController _notesController;
  bool _isIssuingDirectly = false;

  @override
  void initState() {
    super.initState();
    _viewModel = InvoiceFormViewModel(
      clientRepository: widget.clientRepository,
      createInvoice: widget.createInvoice,
      updateInvoiceDraft: widget.updateInvoiceDraft,
      issueInvoice: widget.issueInvoice,
      initialInvoice: widget.initialInvoice,
      preselectedClientId: widget.preselectedClientId,
    );

    _numberController = TextEditingController(text: _viewModel.state.number);
    _notesController = TextEditingController(text: _viewModel.state.notes);

    _viewModel.initialize();
  }

  @override
  void dispose() {
    _numberController.dispose();
    _notesController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppBlurredDialogContainer(
      maxWidth: 720,
      maxHeight: 820,
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
                    AppModernIcon(
                      icon: state.isEditing
                          ? CupertinoIcons.pencil
                          : CupertinoIcons.doc_text_fill,
                      size: 40,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            state.isEditing
                                ? 'Edit Invoice Draft'
                                : 'New Invoice Draft',
                            style: AppTypography.headline.copyWith(
                              fontSize: 18,
                              color: AppColors.textPrimary(context),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            'Draft invoices can be modified until formally issued.',
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
                    // Client Selector & Invoice Number
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
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
                                child: state.status == InvoiceFormStatus.loading
                                    ? const Align(
                                        alignment: Alignment.centerLeft,
                                        child: Row(
                                          children: [
                                            CupertinoActivityIndicator(
                                              radius: 7,
                                            ),
                                            SizedBox(width: AppSpacing.xs),
                                            Text(
                                              'Loading clients...',
                                              style: TextStyle(fontSize: 12),
                                            ),
                                          ],
                                        ),
                                      )
                                    : MouseRegion(
                                        cursor: state.isEditing
                                            ? SystemMouseCursors.basic
                                            : SystemMouseCursors.click,
                                        child: CupertinoButton(
                                          padding: EdgeInsets.zero,
                                          alignment: Alignment.centerLeft,
                                          onPressed: state.isEditing
                                              ? null
                                              : () =>
                                                    _showClientPicker(context),
                                          child: Row(
                                            children: [
                                              if (state.selectedClient !=
                                                  null) ...[
                                                Container(
                                                  width: 24.0,
                                                  height: 24.0,
                                                  margin: const EdgeInsets.only(
                                                    right: AppSpacing.xs,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    gradient:
                                                        AppGradients.avatarFor(
                                                          state
                                                              .selectedClient!
                                                              .name,
                                                        ),
                                                  ),
                                                  alignment: Alignment.center,
                                                  child: Text(
                                                    _getInitials(
                                                      state
                                                          .selectedClient!
                                                          .name,
                                                    ),
                                                    style: const TextStyle(
                                                      fontSize: 10.0,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color:
                                                          CupertinoColors.white,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                              Expanded(
                                                child: Text(
                                                  state.selectedClient?.name ??
                                                      (state
                                                              .availableClients
                                                              .isEmpty
                                                          ? 'No clients found (tap to add / select)'
                                                          : 'Select a client...'),
                                                  style: AppTypography.body.copyWith(
                                                    color:
                                                        state.selectedClient !=
                                                            null
                                                        ? AppColors.textPrimary(
                                                            context,
                                                          )
                                                        : AppColors.textTertiary(
                                                            context,
                                                          ),
                                                    fontWeight:
                                                        state.selectedClient !=
                                                            null
                                                        ? FontWeight.w600
                                                        : FontWeight.normal,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              if (!state.isEditing)
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
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          flex: 2,
                          child: AppTextField(
                            controller: _numberController,
                            label: 'Invoice #',
                            errorText: state.numberError,
                            onChanged: _viewModel.onNumberChanged,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // Clean Line Items Section Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Line Items',
                              style: AppTypography.headline.copyWith(
                                color: AppColors.textPrimary(context),
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            AppBadge(
                              label: '${state.lines.length}',
                              variant: AppBadgeVariant.neutral,
                            ),
                          ],
                        ),
                        AppButton(
                          text: 'Add Line Item',
                          icon: const Icon(CupertinoIcons.plus, size: 14),
                          size: AppButtonSize.compact,
                          variant: AppButtonVariant.secondary,
                          onPressed: _viewModel.addLine,
                        ),
                      ],
                    ),
                    if (state.linesError != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        state.linesError!,
                        style: AppTypography.caption2.copyWith(
                          color: AppColors.destructive(context),
                        ),
                      ),
                    ],

                    const SizedBox(height: AppSpacing.sm),

                    // Clean and clean line items list with smooth transitions
                    AnimatedSize(
                      duration: AppDurations.standard,
                      curve: AppDurations.smoothEaseOut,
                      child: Column(
                        children: [
                          for (int i = 0; i < state.lines.length; i++) ...[
                            _buildCleanLineItemRow(
                              context,
                              state.lines[i],
                              lineIndex: i + 1,
                            ),
                            if (i < state.lines.length - 1)
                              const SizedBox(height: AppSpacing.sm),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // Clean financial totals summary card
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.canvas(context),
                        borderRadius: AppRadii.mdRadius,
                        border: Border.all(
                          color: AppColors.border(context),
                          width: 1.0,
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Subtotal',
                                style: AppTypography.caption1.copyWith(
                                  color: AppColors.textSecondary(context),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              AppMoneyDisplay(
                                money: state.grossTotal,
                                style: AppTypography.caption1.copyWith(
                                  color: AppColors.textPrimary(context),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          if (state.discountTotal.isPositive) ...[
                            const SizedBox(height: AppSpacing.xs),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Discounts',
                                  style: AppTypography.caption1.copyWith(
                                    color: AppColors.destructive(context),
                                  ),
                                ),
                                AppMoneyDisplay(
                                  money: state.discountTotal,
                                  style: AppTypography.caption1.copyWith(
                                    color: AppColors.destructive(context),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.xs,
                            ),
                            child: Container(
                              height: 1,
                              color: AppColors.separator(context),
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Invoice Total',
                                style: AppTypography.headline.copyWith(
                                  color: AppColors.textPrimary(context),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              AppMoneyDisplay(
                                money: state.netTotal,
                                style: AppTypography.headline.copyWith(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryAccent(context),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.md),

                    AppTextField(
                      controller: _notesController,
                      label: 'Notes / Payment Terms (Optional)',
                      placeholder:
                          'Payment due in 30 days via bank transfer...',
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
                      text: state.isEditing ? 'Update Draft' : 'Save as Draft',
                      variant: widget.issueInvoice != null
                          ? AppButtonVariant.secondary
                          : AppButtonVariant.primary,
                      isLoading: state.isSubmitting && !_isIssuingDirectly,
                      onPressed: state.isSubmitting
                          ? null
                          : () async {
                              final saved = await _viewModel.submit(
                                issueDirectly: false,
                              );
                              if (saved != null && context.mounted) {
                                Navigator.of(context).pop(saved);
                              }
                            },
                    ),
                    if (widget.issueInvoice != null) ...[
                      const SizedBox(width: AppSpacing.sm),
                      AppButton(
                        text: state.isEditing
                            ? 'Save & Issue Now'
                            : 'Create & Issue',
                        icon: const Icon(
                          CupertinoIcons.checkmark_seal_fill,
                          size: 14,
                        ),
                        variant: AppButtonVariant.primary,
                        isLoading: state.isSubmitting && _isIssuingDirectly,
                        onPressed: state.isSubmitting
                            ? null
                            : () async {
                                setState(() => _isIssuingDirectly = true);
                                try {
                                  final saved = await _viewModel.submit(
                                    issueDirectly: true,
                                  );
                                  if (saved != null && context.mounted) {
                                    Navigator.of(context).pop(saved);
                                  }
                                } finally {
                                  if (mounted) {
                                    setState(() => _isIssuingDirectly = false);
                                  }
                                }
                              },
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Clean, modern, and de-boxed invoice line item card.
  Widget _buildCleanLineItemRow(
    BuildContext context,
    InvoiceLineFormItem item, {
    required int lineIndex,
  }) {
    final currency = _viewModel.state.currency;
    final lineTotal = item.lineTotal(currency);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondary(context).withValues(alpha: 0.75),
        borderRadius: AppRadii.mdRadius,
        border: Border.all(color: AppColors.border(context), width: 1.0),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Line Item Header (Index chip, Line total preview, and Delete action)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 3.0,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryAccent(
                          context,
                        ).withValues(alpha: 0.12),
                        borderRadius: AppRadii.pillRadius,
                      ),
                      child: Text(
                        '#$lineIndex',
                        style: AppTypography.caption2.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryAccent(context),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Flexible(
                      child: Text(
                        'Line Item',
                        style: AppTypography.caption1.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary(context),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 4.0,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.canvas(context),
                      borderRadius: AppRadii.xsRadius,
                      border: Border.all(color: AppColors.border(context)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Total: ',
                          style: AppTypography.caption2.copyWith(
                            color: AppColors.textTertiary(context),
                          ),
                        ),
                        AppMoneyDisplay(
                          money: lineTotal,
                          style: AppTypography.caption1.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  AppIconButton(
                    icon: CupertinoIcons.trash,
                    size: 28,
                    iconSize: 14,
                    color: AppColors.destructive(context),
                    tooltip: 'Delete line',
                    onPressed: _viewModel.state.lines.length > 1
                        ? () => _viewModel.removeLine(item.id)
                        : null,
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.sm),

          // Inputs row: perfectly aligned Description, Qty, and Unit Price
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Description
              Expanded(
                flex: 5,
                child: AppTextField(
                  label: 'Description',
                  placeholder: 'Item or service rendered',
                  initialValue: item.description,
                  onChanged: (val) =>
                      _viewModel.updateLineDescription(item.id, val),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // Qty
              SizedBox(
                width: 80,
                child: AppTextField(
                  label: 'Qty',
                  initialValue: '${item.quantity}',
                  keyboardType: TextInputType.number,
                  onChanged: (val) {
                    final qty = int.tryParse(val.trim());
                    if (qty != null && qty > 0) {
                      _viewModel.updateLineQuantity(item.id, qty);
                    }
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // Unit Price
              Expanded(
                flex: 3,
                child: AppMoneyField(
                  label: 'Unit Price',
                  currency: currency,
                  initialValue: item.unitPriceText,
                  onMoneyChanged: (money) => _viewModel.updateLineUnitPrice(
                    item.id,
                    money?.format(includeSymbol: false) ?? '',
                  ),
                ),
              ),
            ],
          ),
        ],
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
      subtitle: 'Choose a client to bill for this invoice',
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
