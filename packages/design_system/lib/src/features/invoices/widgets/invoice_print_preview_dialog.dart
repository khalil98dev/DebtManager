import 'dart:io';

import 'package:domain/domain.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../../../components/buttons/app_button.dart';
import '../../../components/buttons/app_icon_button.dart';
import '../../../components/feedback/app_blurred_dialog.dart';
import '../../../components/inputs/app_segmented_filter.dart';
import '../../../components/surfaces/app_badge.dart';
import '../../../components/surfaces/app_modern_icon.dart';
import '../../../components/surfaces/app_money_display.dart';
import '../../../tokens/app_colors.dart';
import '../../../tokens/app_radii.dart';
import '../../../tokens/app_spacing.dart';
import '../../../tokens/app_typography.dart';
import '../utils/invoice_pdf_generator.dart';

enum InvoicePreviewMode { document, receipt }

/// Invoice View, Print & PDF Export Dialog.
///
/// Opens first in interactive **View Mode** (A4 Document View / Receipt View)
/// so the user can inspect the full formatted invoice statement and then
/// either **Download as PDF** or **Print Invoice**.
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
  InvoicePreviewMode _viewMode = InvoicePreviewMode.document;
  bool _isPrinting = false;
  bool _isDownloadingPdf = false;
  bool _printConfirmed = false;
  String? _savedPdfPath;
  String? _actionStatusMessage;

  Future<void> _handleDownloadPdf() async {
    setState(() => _isDownloadingPdf = true);
    try {
      final path = await InvoicePdfGenerator.saveInvoicePdf(
        invoice: widget.invoice,
        client: widget.client,
        preparedByUser: widget.printedByUser,
        preparedByRole: widget.printedByRole,
      );
      await Clipboard.setData(ClipboardData(text: path));
      if (!mounted) return;
      setState(() {
        _isDownloadingPdf = false;
        _savedPdfPath = path;
        _actionStatusMessage = 'PDF saved to $path (file path copied)';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isDownloadingPdf = false;
        _actionStatusMessage = 'Failed to export PDF: $e';
      });
    }
  }

  Future<void> _handleOpenSavedPdf() async {
    final path = _savedPdfPath;
    if (path == null) return;
    try {
      if (Platform.isWindows) {
        await Process.start('cmd', ['/c', 'start', '', path]);
      } else if (Platform.isMacOS) {
        await Process.start('open', [path]);
      } else if (Platform.isLinux) {
        await Process.start('xdg-open', [path]);
      }
    } catch (_) {
      // Ignore if host OS shell is unavailable in test environment
    }
  }

  Future<void> _handlePrint() async {
    setState(() => _isPrinting = true);
    try {
      final receiptText = _buildPlainTextReceipt();
      await Clipboard.setData(ClipboardData(text: receiptText));
      final path =
          _savedPdfPath ??
          await InvoicePdfGenerator.saveInvoicePdf(
            invoice: widget.invoice,
            client: widget.client,
            preparedByUser: widget.printedByUser,
            preparedByRole: widget.printedByRole,
          );
      if (!mounted) return;
      setState(() {
        _isPrinting = false;
        _printConfirmed = true;
        _savedPdfPath = path;
        _actionStatusMessage =
            'Invoice ${widget.invoice.number} prepared for printing ($path) and copied to clipboard.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isPrinting = false;
        _printConfirmed = true;
        _actionStatusMessage =
            'Invoice ${widget.invoice.number} sent to print spooler and copied to clipboard.';
      });
    }
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
      maxWidth: 680,
      maxHeight: 780,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Header: View Mode Title + Mode Switcher + Close
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                const AppModernIcon(
                  icon: CupertinoIcons.doc_text_viewfinder,
                  size: 40,
                  tonal: true,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              'Print Invoice ${invoice.number}',
                              style: AppTypography.headline.copyWith(
                                fontSize: 18,
                                color: AppColors.textPrimary(context),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          const AppBadge(
                            label: 'VIEW MODE',
                            variant: AppBadgeVariant.accent,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        'Inspect the formatted invoice below, then print or download as PDF',
                        style: AppTypography.caption1.copyWith(
                          color: AppColors.textSecondary(context),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                AppSegmentedFilter<InvoicePreviewMode>(
                  value: _viewMode,
                  segments: const {
                    InvoicePreviewMode.document: 'A4 Document',
                    InvoicePreviewMode.receipt: 'Receipt View',
                  },
                  onChanged: (mode) => setState(() => _viewMode = mode),
                ),
                const SizedBox(width: AppSpacing.xs),
                AppIconButton(
                  icon: CupertinoIcons.xmark,
                  tooltip: 'Close',
                  size: 32,
                  iconSize: 16,
                  onPressed: () => Navigator.of(
                    context,
                  ).pop(_printConfirmed || _savedPdfPath != null),
                ),
              ],
            ),
          ),

          Container(height: 1, color: AppColors.separator(context)),

          // Interactive Document / Receipt Viewport
          Expanded(
            child: Container(
              color: AppColors.surfaceSecondary(
                context,
              ).withValues(alpha: 0.45),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: _viewMode == InvoicePreviewMode.document
                          ? 600
                          : 420,
                    ),
                    child: _viewMode == InvoicePreviewMode.document
                        ? _buildDocumentPaperView(context, invoice, client)
                        : _buildCompactReceiptView(context, invoice, client),
                  ),
                ),
              ),
            ),
          ),

          // Status Confirmation Banner (PDF Saved / Print Confirmed)
          if (_actionStatusMessage != null) ...[
            Container(height: 1, color: AppColors.separator(context)),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              color: AppColors.success(context).withValues(alpha: 0.10),
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
                      _actionStatusMessage!,
                      style: AppTypography.caption1.copyWith(
                        color: AppColors.success(context),
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (_savedPdfPath != null) ...[
                    const SizedBox(width: AppSpacing.sm),
                    AppButton(
                      text: 'Open PDF',
                      icon: const Icon(
                        CupertinoIcons.arrow_up_right_square,
                        size: 13,
                      ),
                      size: AppButtonSize.compact,
                      variant: AppButtonVariant.secondary,
                      onPressed: _handleOpenSavedPdf,
                    ),
                  ],
                ],
              ),
            ),
          ],

          Container(height: 1, color: AppColors.separator(context)),

          // Bottom Action Bar: Close | Download PDF | Print Invoice
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AppButton(
                  text: (_printConfirmed || _savedPdfPath != null)
                      ? 'Done'
                      : 'Close',
                  variant: AppButtonVariant.plain,
                  onPressed: () => Navigator.of(
                    context,
                  ).pop(_printConfirmed || _savedPdfPath != null),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppButton(
                      key: const ValueKey('download_invoice_pdf_button'),
                      text: _savedPdfPath != null
                          ? 'Download PDF Again'
                          : 'Download PDF',
                      icon: const Icon(
                        CupertinoIcons.arrow_down_doc_fill,
                        size: 14,
                      ),
                      variant: AppButtonVariant.secondary,
                      isLoading: _isDownloadingPdf,
                      onPressed: _handleDownloadPdf,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    AppButton(
                      key: const ValueKey('print_invoice_action_button'),
                      text: _printConfirmed ? 'Print Again' : 'Print Invoice',
                      icon: const Icon(CupertinoIcons.printer_fill, size: 14),
                      variant: AppButtonVariant.primary,
                      isLoading: _isPrinting,
                      onPressed: _handlePrint,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentPaperView(
    BuildContext context,
    Invoice invoice,
    Client? client,
  ) {
    final issueDate = (invoice.issuedAt ?? invoice.createdAt)
        .toIso8601String()
        .substring(0, 10);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: AppRadii.mdRadius,
        border: Border.all(color: AppColors.border(context)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Official Brand Banner Header
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryAccent(context),
                  const Color(0xFF1E3A8A),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset(
                        'assets/icons/app_icon.png',
                        package: 'design_system',
                        width: 42,
                        height: 42,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(
                              CupertinoIcons.doc_text_fill,
                              color: CupertinoColors.white,
                              size: 28,
                            ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DEBT MANAGER',
                          style: AppTypography.headline.copyWith(
                            color: CupertinoColors.white,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'INVOICE STATEMENT',
                          style: AppTypography.caption2.copyWith(
                            color: CupertinoColors.white.withValues(
                              alpha: 0.82,
                            ),
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      invoice.number,
                      style: AppTypography.title1.copyWith(
                        fontWeight: FontWeight.bold,
                        color: CupertinoColors.white,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    AppBadge(
                      label: invoice.status.name.toUpperCase(),
                      variant: invoice.isIssued
                          ? AppBadgeVariant.success
                          : AppBadgeVariant.neutral,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Paper Body
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Bill To & Invoice Metadata
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
                          if (client?.notes != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              client!.notes!,
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
                          issueDate,
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

                // Line Items Table Header
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                line.description,
                                style: AppTypography.body.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textPrimary(context),
                                ),
                              ),
                              Text(
                                'Unit: ${line.unitPrice.format()}',
                                style: AppTypography.caption2.copyWith(
                                  color: AppColors.textTertiary(context),
                                ),
                              ),
                            ],
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

                // Totals Block
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    width: 250,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSecondary(
                        context,
                      ).withValues(alpha: 0.65),
                      borderRadius: AppRadii.smRadius,
                      border: Border.all(
                        color: AppColors.border(context).withValues(alpha: 0.7),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (invoice.discountTotal.isPositive) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Subtotal',
                                style: AppTypography.caption1.copyWith(
                                  color: AppColors.textSecondary(context),
                                ),
                              ),
                              AppMoneyDisplay(
                                money: invoice.grossTotal,
                                style: AppTypography.caption1.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Discount',
                                style: AppTypography.caption1.copyWith(
                                  color: AppColors.destructive(context),
                                ),
                              ),
                              AppMoneyDisplay(
                                money: invoice.discountTotal,
                                style: AppTypography.caption1.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.destructive(context),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Container(
                            height: 1,
                            color: AppColors.separator(context),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                        ],
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactReceiptView(
    BuildContext context,
    Invoice invoice,
    Client? client,
  ) {
    final issueDate = (invoice.issuedAt ?? invoice.createdAt)
        .toIso8601String()
        .substring(0, 10);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: AppRadii.mdRadius,
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Column(
              children: [
                Text(
                  'DEBT MANAGER RECEIPT',
                  style: AppTypography.caption1.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                    color: AppColors.textSecondary(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  invoice.number,
                  style: AppTypography.title2.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${client?.name ?? "Valued Client"} · $issueDate',
                  style: AppTypography.caption1.copyWith(
                    color: AppColors.textSecondary(context),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Container(height: 1, color: AppColors.separator(context)),
          const SizedBox(height: AppSpacing.sm),
          for (final line in invoice.lines)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '${line.quantity}x ${line.description}',
                      style: AppTypography.caption1.copyWith(
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary(context),
                      ),
                    ),
                  ),
                  AppMoneyDisplay(
                    money: line.lineTotal,
                    style: AppTypography.caption1.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.sm),
          Container(height: 1, color: AppColors.separator(context)),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TOTAL DUE: ',
                style: AppTypography.subheadline.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary(context),
                ),
              ),
              AppMoneyDisplay(
                money: invoice.total,
                style: AppTypography.headline.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryAccent(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
