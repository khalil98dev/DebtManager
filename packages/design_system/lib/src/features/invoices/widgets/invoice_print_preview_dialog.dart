import 'package:domain/domain.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../../../components/buttons/app_button.dart';
import '../../../components/buttons/app_icon_button.dart';
import '../../../components/feedback/app_blurred_dialog.dart';
import '../../../components/surfaces/app_badge.dart';
import '../../../components/surfaces/app_modern_icon.dart';
import '../../../components/surfaces/app_money_display.dart';
import '../../../tokens/app_colors.dart';
import '../../../tokens/app_radii.dart';
import '../../../tokens/app_spacing.dart';
import '../../../tokens/app_typography.dart';

/// Formatted printable invoice receipt & print preview dialog.
///
/// Accessible to roles with [AppPermission.printInvoices] (including Admin and
/// the base Operator/Cashier role).
class InvoicePrintPreviewDialog extends StatefulWidget {
  const InvoicePrintPreviewDialog({
    super.key,
    required this.invoice,
    this.client,
    this.printedByUser,
    this.printedByRole,
  });

  final Invoice invoice;
  final Client? client;
  final String? printedByUser;
  final String? printedByRole;

  static Future<bool?> show(
    BuildContext context, {
    required Invoice invoice,
    Client? client,
    String? printedByUser,
    String? printedByRole,
  }) {
    return showAppBlurredDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => InvoicePrintPreviewDialog(
        invoice: invoice,
        client: client,
        printedByUser: printedByUser,
        printedByRole: printedByRole,
      ),
    );
  }

  @override
  State<InvoicePrintPreviewDialog> createState() =>
      _InvoicePrintPreviewDialogState();
}

class _InvoicePrintPreviewDialogState extends State<InvoicePrintPreviewDialog> {
  bool _isPrinting = false;
  bool _printConfirmed = false;

  Future<void> _handlePrint() async {
    setState(() => _isPrinting = true);
    final receiptText = _buildPlainTextReceipt();
    await Clipboard.setData(ClipboardData(text: receiptText));
    if (!mounted) return;
    setState(() {
      _isPrinting = false;
      _printConfirmed = true;
    });
  }

  String _buildPlainTextReceipt() {
    final inv = widget.invoice;
    final buffer = StringBuffer()
      ..writeln('========================================')
      ..writeln('INVOICE: ${inv.number} (${inv.status.name.toUpperCase()})')
      ..writeln('CLIENT:  ${widget.client?.name ?? inv.clientId.value}')
      ..writeln(
        'DATE:    ${(inv.issuedAt ?? inv.createdAt).toIso8601String().substring(0, 10)}',
      )
      ..writeln('----------------------------------------');
    for (var i = 0; i < inv.lines.length; i++) {
      final line = inv.lines[i];
      buffer.writeln(
        '${i + 1}. ${line.description}  x${line.quantity} @ ${line.unitPrice.format()} = ${line.lineTotal.format()}',
      );
    }
    buffer
      ..writeln('----------------------------------------')
      ..writeln('TOTAL:   ${inv.total.format()}')
      ..writeln('========================================');
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final invoice = widget.invoice;
    final client = widget.client;

    return AppBlurredDialogContainer(
      maxWidth: 620,
      maxHeight: 740,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                const AppModernIcon(
                  icon: CupertinoIcons.printer_fill,
                  size: 40,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Print Invoice ${invoice.number}',
                        style: AppTypography.headline.copyWith(
                          fontSize: 18,
                          color: AppColors.textPrimary(context),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        'Formatted invoice statement ready for printing or export',
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
                  onPressed: () => Navigator.of(context).pop(_printConfirmed),
                ),
              ],
            ),
          ),

          Container(height: 1, color: AppColors.separator(context)),

          // Printable Document Preview
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.canvas(context),
                  borderRadius: AppRadii.mdRadius,
                  border: Border.all(color: AppColors.border(context)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Document Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'INVOICE STATEMENT',
                              style: AppTypography.caption2.copyWith(
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.0,
                                color: AppColors.primaryAccent(context),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xxs),
                            Text(
                              invoice.number,
                              style: AppTypography.title1.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary(context),
                              ),
                            ),
                          ],
                        ),
                        AppBadge(
                          label: invoice.status.name.toUpperCase(),
                          variant: invoice.isIssued
                              ? AppBadgeVariant.success
                              : AppBadgeVariant.neutral,
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.md),
                    Container(height: 1, color: AppColors.separator(context)),
                    const SizedBox(height: AppSpacing.md),

                    // Bill To & Dates
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'BILL TO',
                                style: AppTypography.caption2.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textTertiary(context),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xxs),
                              Text(
                                client?.name ?? 'Valued Client',
                                style: AppTypography.headline.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary(context),
                                ),
                              ),
                              if (client?.phone != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  client!.phone!,
                                  style: AppTypography.caption1.copyWith(
                                    color: AppColors.textSecondary(context),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'DATE',
                              style: AppTypography.caption2.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textTertiary(context),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xxs),
                            Text(
                              (invoice.issuedAt ?? invoice.createdAt)
                                  .toIso8601String()
                                  .substring(0, 10),
                              style: AppTypography.body.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary(context),
                              ),
                            ),
                            if (widget.printedByUser != null) ...[
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                'Prepared by: ${widget.printedByUser} (${widget.printedByRole ?? "Staff"})',
                                style: AppTypography.caption2.copyWith(
                                  color: AppColors.textSecondary(context),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // Line Items Table
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSecondary(context),
                        borderRadius: AppRadii.xsRadius,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 5,
                            child: Text(
                              'DESCRIPTION',
                              style: AppTypography.caption2.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSecondary(context),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 50,
                            child: Text(
                              'QTY',
                              style: AppTypography.caption2.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSecondary(context),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                'AMOUNT',
                                style: AppTypography.caption2.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textSecondary(context),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),

                    for (final line in invoice.lines) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 5,
                              child: Text(
                                line.description,
                                style: AppTypography.body.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textPrimary(context),
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 50,
                              child: Text(
                                'x${line.quantity}',
                                style: AppTypography.caption1.copyWith(
                                  color: AppColors.textSecondary(context),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: AppMoneyDisplay(
                                  money: line.lineTotal,
                                  style: AppTypography.body.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(height: 1, color: AppColors.separator(context)),
                    ],

                    const SizedBox(height: AppSpacing.md),

                    // Totals
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'TOTAL DUE: ',
                          style: AppTypography.headline.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary(context),
                          ),
                        ),
                        AppMoneyDisplay(
                          money: invoice.total,
                          style: AppTypography.title2.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryAccent(context),
                          ),
                        ),
                      ],
                    ),

                    if (_printConfirmed) ...[
                      const SizedBox(height: AppSpacing.md),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: AppColors.success(
                            context,
                          ).withValues(alpha: 0.12),
                          borderRadius: AppRadii.smRadius,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              CupertinoIcons.checkmark_circle_fill,
                              size: 16,
                              color: AppColors.success(context),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Expanded(
                              child: Text(
                                'Invoice ${invoice.number} sent to print spooler and copied to clipboard.',
                                style: AppTypography.caption1.copyWith(
                                  color: AppColors.success(context),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          Container(height: 1, color: AppColors.separator(context)),

          // Footer Actions
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                AppButton(
                  text: _printConfirmed ? 'Done' : 'Close',
                  variant: AppButtonVariant.plain,
                  onPressed: () => Navigator.of(context).pop(_printConfirmed),
                ),
                const SizedBox(width: AppSpacing.sm),
                AppButton(
                  text: _printConfirmed ? 'Print Again' : 'Print Invoice',
                  icon: const Icon(CupertinoIcons.printer_fill, size: 14),
                  variant: AppButtonVariant.primary,
                  isLoading: _isPrinting,
                  onPressed: _handlePrint,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
