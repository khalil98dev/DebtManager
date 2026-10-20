import 'dart:ui';
import 'package:application/application.dart';
import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/cupertino.dart';

/// Mobile-optimized Invoices screen with large navigation title, search,
/// status filtering, pull-to-refresh, and Cupertino action sheets.
class MobileInvoicesScreen extends StatefulWidget {
  const MobileInvoicesScreen({super.key, required this.dependencies});

  final AppDependencies dependencies;

  @override
  State<MobileInvoicesScreen> createState() => _MobileInvoicesScreenState();
}

class _MobileInvoicesScreenState extends State<MobileInvoicesScreen> {
  late final InvoiceListViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = InvoiceListViewModel(
      invoiceRepository: widget.dependencies.invoiceRepository,
      clientRepository: widget.dependencies.clientRepository,
    );
    _viewModel.loadInvoices();
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

  void _showInvoiceDetail(BuildContext context, Invoice invoice) {
    final client = _viewModel.state.clientsById[invoice.clientId];

    showCupertinoModalPopup<void>(
      context: context,
      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
      builder: (modalContext) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              height: MediaQuery.of(modalContext).size.height * 0.78,
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
                          AppModernIcon(
                            icon: invoice.isIssued
                                ? CupertinoIcons.checkmark_seal_fill
                                : CupertinoIcons.doc_text,
                            size: 38,
                            iconSize: 18,
                            gradient: invoice.isIssued
                                ? AppGradients.success(modalContext)
                                : AppGradients.primary(modalContext),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Invoice ${invoice.number}',
                                  style: AppTypography.title2.copyWith(
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
                            label: invoice.status.name.toUpperCase(),
                            variant: invoice.isIssued
                                ? AppBadgeVariant.success
                                : AppBadgeVariant.warning,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      height: 1,
                      color: AppColors.separator(modalContext),
                    ),

                    // Scrollable Invoice Summary & Lines
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        children: [
                          // Financial Totals
                          AppCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Gross Total',
                                      style: AppTypography.body,
                                    ),
                                    AppMoneyDisplay(money: invoice.grossTotal),
                                  ],
                                ),
                                if (invoice.discountTotal.isPositive) ...[
                                  const SizedBox(height: AppSpacing.xs),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Discount',
                                        style: AppTypography.body.copyWith(
                                          color: AppColors.destructive(
                                            modalContext,
                                          ),
                                        ),
                                      ),
                                      AppMoneyDisplay(
                                        money: invoice.discountTotal,
                                        style: TextStyle(
                                          color: AppColors.destructive(
                                            modalContext,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                const SizedBox(height: AppSpacing.xs),
                                Container(
                                  height: 1,
                                  color: AppColors.separator(modalContext),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Total Payable',
                                      style: AppTypography.headline.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    AppMoneyDisplay(
                                      money: invoice.total,
                                      style: AppTypography.headline.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primaryAccent(
                                          modalContext,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: AppSpacing.md),
                          AppExpandableSection(
                            title: 'Line Items',
                            subtitle:
                                '${invoice.lines.length} ${invoice.lines.length == 1 ? "item" : "items"} recorded',
                            initiallyExpanded: true,
                            trailing: AppBadge(
                              label: '${invoice.lines.length}',
                              variant: AppBadgeVariant.neutral,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                AppSpacing.md,
                                AppSpacing.xs,
                                AppSpacing.md,
                                AppSpacing.md,
                              ),
                              child: Column(
                                children: [
                                  for (int i = 0; i < invoice.lines.length; i++)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppSpacing.md,
                                        vertical: AppSpacing.sm,
                                      ),
                                      margin: const EdgeInsets.only(
                                        bottom: AppSpacing.xs,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceSecondary(
                                          modalContext,
                                        ),
                                        borderRadius: AppRadii.smRadius,
                                        border: Border.all(
                                          color: AppColors.border(modalContext),
                                          width: 0.8,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 26,
                                            height: 26,
                                            decoration: BoxDecoration(
                                              color: AppColors.canvas(
                                                modalContext,
                                              ),
                                              borderRadius: AppRadii.xsRadius,
                                              border: Border.all(
                                                color: AppColors.border(
                                                  modalContext,
                                                ),
                                              ),
                                            ),
                                            alignment: Alignment.center,
                                            child: Text(
                                              '#${i + 1}',
                                              style: AppTypography.caption2
                                                  .copyWith(
                                                    fontWeight: FontWeight.bold,
                                                    color:
                                                        AppColors.textSecondary(
                                                          modalContext,
                                                        ),
                                                  ),
                                            ),
                                          ),
                                          const SizedBox(width: AppSpacing.sm),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  invoice.lines[i].description,
                                                  style: AppTypography.body
                                                      .copyWith(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  '${invoice.lines[i].quantity} × ${invoice.lines[i].unitPrice.format()}',
                                                  style: AppTypography.caption1
                                                      .copyWith(
                                                        color:
                                                            AppColors.textSecondary(
                                                              modalContext,
                                                            ),
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          AppMoneyDisplay(
                                            money: invoice.lines[i].lineTotal,
                                            style: AppTypography.body.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Modal Actions
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.dependencies.hasPermission(
                            AppPermission.printInvoices,
                          )) ...[
                            SizedBox(
                              width: double.infinity,
                              child: AppButton(
                                text: 'Print Invoice',
                                icon: const Icon(
                                  CupertinoIcons.printer_fill,
                                  size: 14,
                                ),
                                variant: AppButtonVariant.secondary,
                                onPressed: () {
                                  Navigator.pop(modalContext);
                                  final session = widget
                                      .dependencies
                                      .authViewModel
                                      .currentSession;
                                  InvoicePrintPreviewDialog.show(
                                    context,
                                    invoice: invoice,
                                    client: client,
                                    printedByUser: session?.user.displayName,
                                    printedByRole: session?.role.name,
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                          ],
                          Row(
                            children: [
                              if (invoice.isDraft) ...[
                                if (widget.dependencies.hasPermission(
                                  AppPermission.manageInvoices,
                                )) ...[
                                  Expanded(
                                    child: AppButton(
                                      text: 'Edit Draft',
                                      variant: AppButtonVariant.secondary,
                                      onPressed: () async {
                                        Navigator.pop(modalContext);
                                        final updated =
                                            await InvoiceFormDialog.show(
                                              context,
                                              clientRepository: widget
                                                  .dependencies
                                                  .clientRepository,
                                              createInvoice: widget
                                                  .dependencies
                                                  .createInvoice,
                                              updateInvoiceDraft: widget
                                                  .dependencies
                                                  .updateInvoiceDraft,
                                              issueInvoice:
                                                  widget.dependencies
                                                          .hasPermission(
                                                            AppPermission
                                                                .issueInvoices,
                                                          )
                                                      ? widget
                                                            .dependencies
                                                            .issueInvoice
                                                      : null,
                                              createClient:
                                                  widget.dependencies
                                                          .hasPermission(
                                                            AppPermission
                                                                .manageClients,
                                                          )
                                                      ? widget
                                                            .dependencies
                                                            .createClient
                                                      : null,
                                              updateClient:
                                                  widget.dependencies
                                                          .hasPermission(
                                                            AppPermission
                                                                .manageClients,
                                                          )
                                                      ? widget
                                                            .dependencies
                                                            .updateClient
                                                      : null,
                                              initialInvoice: invoice,
                                            );
                                        if (updated != null) {
                                          widget.dependencies
                                              .notifyDataChanged();
                                          _viewModel.refresh();
                                        }
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                ],
                                if (widget.dependencies.hasPermission(
                                  AppPermission.issueInvoices,
                                ))
                                  Expanded(
                                    child: AppButton(
                                      text: 'Issue Invoice',
                                      variant: AppButtonVariant.primary,
                                      onPressed: () async {
                                        Navigator.pop(modalContext);
                                        final confirmed =
                                            await AppConfirmationDialog.show(
                                              context,
                                              title:
                                                  'Issue Invoice ${invoice.number}?',
                                              message:
                                                  'This will finalize the invoice and register outstanding debt for ${client?.name}.',
                                              confirmLabel: 'Issue',
                                            );
                                        if (confirmed == true) {
                                          await widget.dependencies.issueInvoice
                                              .execute(
                                                IssueInvoiceCommand(
                                                  invoiceId: invoice.id,
                                                ),
                                              );
                                          widget.dependencies
                                              .notifyDataChanged();
                                          _viewModel.refresh();
                                        }
                                      },
                                    ),
                                  ),
                              ] else if (widget.dependencies.hasPermission(
                                AppPermission.manageAllocations,
                              )) ...[
                                Expanded(
                                  child: AppButton(
                                    text: 'Allocate Payment',
                                    variant: AppButtonVariant.primary,
                                    onPressed: () async {
                                      Navigator.pop(modalContext);
                                      final allocated =
                                          await AllocationDialog.show(
                                            context,
                                            clientRepository: widget
                                                .dependencies
                                                .clientRepository,
                                            invoiceRepository: widget
                                                .dependencies
                                                .invoiceRepository,
                                            paymentRepository: widget
                                                .dependencies
                                                .paymentRepository,
                                            paymentAllocationRepository: widget
                                                .dependencies
                                                .paymentAllocationRepository,
                                            allocatePayment: widget
                                                .dependencies
                                                .allocatePayment,
                                            preselectedInvoiceId: invoice.id,
                                          );
                                      if (allocated != null) {
                                        _viewModel.refresh();
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
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
      accentColor: const Color(0xFF007AFF),
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
                  largeTitle: const Text('Invoices'),
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
                        AppPermission.manageInvoices,
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
                            final created = await InvoiceFormDialog.show(
                              context,
                              clientRepository:
                                  widget.dependencies.clientRepository,
                              createInvoice: widget.dependencies.createInvoice,
                              updateInvoiceDraft:
                                  widget.dependencies.updateInvoiceDraft,
                              issueInvoice:
                                  widget.dependencies.hasPermission(
                                        AppPermission.issueInvoices,
                                      )
                                      ? widget.dependencies.issueInvoice
                                      : null,
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
                            if (created != null) {
                              widget.dependencies.notifyDataChanged();
                              _viewModel.refresh();
                            }
                          },
                        )
                      : null,
                ),

              CupertinoSliverRefreshControl(onRefresh: _viewModel.refresh),

              // Filter & Search Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  child: Column(
                    children: [
                      AppSearchField(
                        placeholder: 'Search invoice # or client...',
                        onChanged: _viewModel.search,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      SizedBox(
                        width: double.infinity,
                        child: AppSegmentedFilter<String>(
                          value: state.statusFilter?.name ?? 'all',
                          segments: const {
                            'all': 'All',
                            'draft': 'Drafts',
                            'issued': 'Issued',
                          },
                          onChanged: (val) {
                            if (val == 'all') {
                              _viewModel.filterByStatus(null);
                            } else if (val == 'draft') {
                              _viewModel.filterByStatus(InvoiceStatus.draft);
                            } else if (val == 'issued') {
                              _viewModel.filterByStatus(InvoiceStatus.issued);
                            }
                          },
                        ),
                      ),
                    ],
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
                      icon: CupertinoIcons.doc_text,
                      title: 'No Invoices Yet',
                      description:
                          'Create invoice drafts to start managing receivables.',
                      actionLabel: 'Create First Invoice',
                      onAction: () async {
                        final created = await InvoiceFormDialog.show(
                          context,
                          clientRepository:
                              widget.dependencies.clientRepository,
                          createInvoice: widget.dependencies.createInvoice,
                          updateInvoiceDraft:
                              widget.dependencies.updateInvoiceDraft,
                          issueInvoice: widget.dependencies.issueInvoice,
                          createClient: widget.dependencies.createClient,
                          updateClient: widget.dependencies.updateClient,
                        );
                        if (created != null) {
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
                      title: 'No Invoices Found',
                      description: 'Try adjusting your search query or filter.',
                      actionLabel: 'Clear Search',
                      onAction: () {
                        _viewModel.search('');
                        _viewModel.filterByStatus(null);
                      },
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
                      final invoice = state.filteredInvoices[index];
                      final client = state.clientsById[invoice.clientId];

                      return AppStaggeredItem(
                        index: index,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: AppCard(
                            onTap: () => _showInvoiceDetail(context, invoice),
                            child: Row(
                              children: [
                                AppModernIcon(
                                  icon: invoice.isIssued
                                      ? CupertinoIcons.checkmark_seal_fill
                                      : CupertinoIcons.doc_text,
                                  size: 38,
                                  iconSize: 18,
                                  showShadow: false,
                                  gradient: invoice.isIssued
                                      ? AppGradients.success(context)
                                      : AppGradients.primary(context),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              invoice.number,
                                              style: AppTypography.headline
                                                  .copyWith(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                  ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: AppSpacing.xs),
                                          AppBadge(
                                            label: invoice.status.name
                                                .toUpperCase(),
                                            variant: invoice.isIssued
                                                ? AppBadgeVariant.success
                                                : AppBadgeVariant.warning,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: AppSpacing.xxs),
                                      Text(
                                        client?.name ?? 'Unknown Client',
                                        style: AppTypography.subheadline
                                            .copyWith(
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
                                      money: invoice.total,
                                      style: AppTypography.headline.copyWith(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.xxs),
                                    Text(
                                      invoice.createdAt
                                          .toIso8601String()
                                          .substring(0, 10),
                                      style: AppTypography.caption2.copyWith(
                                        color: AppColors.textTertiary(context),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }, childCount: state.filteredInvoices.length),
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
