import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/cupertino.dart';

/// Desktop-density Invoices management and details screen.
class DesktopInvoicesScreen extends StatefulWidget {
  const DesktopInvoicesScreen({super.key, required this.dependencies});

  final AppDependencies dependencies;

  @override
  State<DesktopInvoicesScreen> createState() => _DesktopInvoicesScreenState();
}

class _DesktopInvoicesScreenState extends State<DesktopInvoicesScreen> {
  late final InvoiceListViewModel _listViewModel;
  InvoiceDetailViewModel? _detailViewModel;
  Invoice? _selectedInvoice;

  @override
  void initState() {
    super.initState();
    _listViewModel = InvoiceListViewModel(
      invoiceRepository: widget.dependencies.invoiceRepository,
      clientRepository: widget.dependencies.clientRepository,
    );
    _listViewModel.loadInvoices();
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

  void _onInvoiceSelected(Invoice invoice) {
    setState(() {
      _selectedInvoice = invoice;
      _detailViewModel?.dispose();
      _detailViewModel = InvoiceDetailViewModel(
        invoiceId: invoice.id,
        invoiceRepository: widget.dependencies.invoiceRepository,
        clientRepository: widget.dependencies.clientRepository,
        paymentAllocationRepository:
            widget.dependencies.paymentAllocationRepository,
        issueInvoice: widget.dependencies.issueInvoice,
      );
      _detailViewModel!.loadDetails();
    });
  }

  Future<void> _refresh() async {
    await _listViewModel.loadInvoices();
    if (_selectedInvoice != null && _detailViewModel != null) {
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

          if (_selectedInvoice == null &&
              listState.filteredInvoices.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted &&
                  _selectedInvoice == null &&
                  listState.filteredInvoices.isNotEmpty) {
                _onInvoiceSelected(listState.filteredInvoices.first);
              }
            });
          } else if (_selectedInvoice != null &&
              !listState.filteredInvoices.any(
                (i) => i.id == _selectedInvoice!.id,
              )) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                if (listState.filteredInvoices.isNotEmpty) {
                  _onInvoiceSelected(listState.filteredInvoices.first);
                } else {
                  setState(() => _selectedInvoice = null);
                }
              }
            });
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Toolbar & Header
              AppPageHeader(
                title: 'Invoices',
                subtitle:
                    'Manage draft line items, issued receivables, and payments',
                badgeCount: listState.isLoaded ? listState.totalCount : null,
                actions: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 260,
                      child: AppSearchField(
                        placeholder: 'Search invoice # or client...',
                        onChanged: _listViewModel.search,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    AppSegmentedFilter<String>(
                      value: listState.statusFilter?.name ?? 'all',
                      segments: const {
                        'all': 'All',
                        'draft': 'Drafts',
                        'issued': 'Issued',
                      },
                      onChanged: (val) {
                        if (val == 'all') {
                          _listViewModel.filterByStatus(null);
                        } else if (val == 'draft') {
                          _listViewModel.filterByStatus(InvoiceStatus.draft);
                        } else if (val == 'issued') {
                          _listViewModel.filterByStatus(InvoiceStatus.issued);
                        }
                      },
                    ),
                    if (widget.dependencies.hasPermission(
                      AppPermission.manageInvoices,
                    )) ...[
                      const SizedBox(width: AppSpacing.md),
                      AppButton(
                        text: 'New Invoice',
                        icon: const Icon(CupertinoIcons.plus, size: 14),
                        size: AppButtonSize.compact,
                        onPressed: () async {
                          final created = await InvoiceFormDialog.show(
                            context,
                            clientRepository:
                                widget.dependencies.clientRepository,
                            createInvoice: widget.dependencies.createInvoice,
                            updateInvoiceDraft:
                                widget.dependencies.updateInvoiceDraft,
                            issueInvoice: widget.dependencies.hasPermission(
                                  AppPermission.issueInvoices,
                                )
                                ? widget.dependencies.issueInvoice
                                : null,
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
                          if (created != null) {
                            widget.dependencies.notifyDataChanged();
                            await _refresh();
                            _onInvoiceSelected(created);
                          }
                        },
                      ),
                    ],
                  ],
                ),
              ),

              // Split View Content
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Invoices List column
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
                        child: _buildInvoicesList(context, listState),
                      ),
                    ),

                    // Invoice Detail column with smooth cross-fade
                    Expanded(
                      child: AnimatedContentSwitcher(
                        transitionType: ContentTransitionType.fade,
                        child: Container(
                          key: ValueKey(
                            'inv_detail_${_selectedInvoice?.id.value ?? "none"}',
                          ),
                          child: _buildInvoiceDetailPanel(context),
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

  Widget _buildInvoicesList(BuildContext context, InvoiceListViewState state) {
    if (state.isLoading) {
      return const Center(child: CupertinoActivityIndicator(radius: 12));
    }

    if (state.isEmpty) {
      return Center(
        child: AppEmptyState(
          icon: CupertinoIcons.doc_text,
          title: 'No Invoices Found',
          description:
              'Create your first invoice draft to begin tracking debt.',
          actionLabel: 'Create Invoice Draft',
          onAction: () async {
            final created = await InvoiceFormDialog.show(
              context,
              clientRepository: widget.dependencies.clientRepository,
              createInvoice: widget.dependencies.createInvoice,
              updateInvoiceDraft: widget.dependencies.updateInvoiceDraft,
              issueInvoice: widget.dependencies.issueInvoice,
              createClient: widget.dependencies.createClient,
              updateClient: widget.dependencies.updateClient,
            );
            if (created != null) {
              widget.dependencies.notifyDataChanged();
              await _refresh();
              _onInvoiceSelected(created);
            }
          },
        ),
      );
    }

    if (state.isSearchEmpty) {
      return Center(
        child: AppEmptyState(
          icon: CupertinoIcons.search,
          title: 'No Matching Invoices',
          description: 'Try adjusting your search query or status filter.',
          actionLabel: 'Clear Search',
          onAction: () {
            _listViewModel.search('');
            _listViewModel.filterByStatus(null);
          },
        ),
      );
    }

    return ListView.separated(
      itemCount: state.filteredInvoices.length,
      separatorBuilder: (_, _) =>
          Container(height: 1, color: AppColors.separator(context)),
      itemBuilder: (context, index) {
        final invoice = state.filteredInvoices[index];
        final client = state.clientsById[invoice.clientId];
        final isSelected = _selectedInvoice?.id == invoice.id;

        return AppStaggeredItem(
          index: index,
          child: _DesktopInvoiceListItem(
            invoice: invoice,
            client: client,
            isSelected: isSelected,
            onTap: () => _onInvoiceSelected(invoice),
          ),
        );
      },
    );
  }

  Widget _buildInvoiceDetailPanel(BuildContext context) {
    if (_selectedInvoice == null || _detailViewModel == null) {
      return Center(
        child: AppEmptyState(
          icon: CupertinoIcons.doc_text_search,
          title: 'Select an Invoice',
          description:
              'Choose an invoice from the list to view its line items and allocations.',
        ),
      );
    }

    return ListenableBuilder(
      listenable: _detailViewModel!,
      builder: (context, _) {
        final detailState = _detailViewModel!.state;
        final invoice = detailState.invoice ?? _selectedInvoice!;
        final client = detailState.client;

        return ListView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          children: [
            // Detail Header Card
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
                              Text(
                                invoice.number,
                                style: AppTypography.largeTitle.copyWith(
                                  fontSize: 22,
                                  color: AppColors.textPrimary(context),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              AppBadge(
                                label: invoice.status.name.toUpperCase(),
                                variant: invoice.isIssued
                                    ? AppBadgeVariant.success
                                    : AppBadgeVariant.neutral,
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
                      // Action buttons
                      const SizedBox(width: AppSpacing.md),
                      Flexible(
                        child: Wrap(
                          alignment: WrapAlignment.end,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: AppSpacing.xs,
                          runSpacing: AppSpacing.xs,
                          children: [
                            if (widget.dependencies.hasPermission(
                              AppPermission.printInvoices,
                            ))
                              AppButton(
                                text: 'Print Invoice',
                                icon: const Icon(
                                  CupertinoIcons.printer_fill,
                                  size: 14,
                                ),
                                size: AppButtonSize.compact,
                                variant: AppButtonVariant.secondary,
                                onPressed: () {
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
                            if (invoice.isDraft) ...[
                              if (widget.dependencies.hasPermission(
                                AppPermission.manageInvoices,
                              ))
                                AppButton(
                                  text: 'Edit Draft',
                                  icon: const Icon(
                                    CupertinoIcons.pencil,
                                    size: 14,
                                  ),
                                  size: AppButtonSize.compact,
                                  variant: AppButtonVariant.secondary,
                                  onPressed: () async {
                                    final updated = await InvoiceFormDialog.show(
                                      context,
                                      clientRepository:
                                          widget.dependencies.clientRepository,
                                      createInvoice:
                                          widget.dependencies.createInvoice,
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
                                      initialInvoice: invoice,
                                    );
                                    if (updated != null) {
                                      widget.dependencies.notifyDataChanged();
                                      await _refresh();
                                    }
                                  },
                                ),
                              if (widget.dependencies.hasPermission(
                                AppPermission.issueInvoices,
                              ))
                                AppButton(
                                  text: 'Issue Invoice',
                                  icon: const Icon(
                                    CupertinoIcons.checkmark_seal_fill,
                                    size: 14,
                                  ),
                                  size: AppButtonSize.compact,
                                  variant: AppButtonVariant.primary,
                                  isLoading: detailState.isMutating,
                                  onPressed: () async {
                                    final confirmed =
                                        await AppConfirmationDialog.show(
                                          context,
                                          title:
                                              'Issue Invoice ${invoice.number}?',
                                          message:
                                              'Once issued, this invoice becomes a legal financial claim and cannot be edited. Outstanding debt will be recorded for ${client?.name}.',
                                          confirmLabel: 'Issue Invoice',
                                        );
                                    if (confirmed == true) {
                                      final success = await _detailViewModel!
                                          .issue();
                                      if (success) {
                                        widget.dependencies.notifyDataChanged();
                                        await _refresh();
                                      }
                                    }
                                  },
                                ),
                            ] else if (widget.dependencies.hasPermission(
                              AppPermission.recordPayments,
                            )) ...[
                              AppButton(
                                text: 'Record Payment',
                                icon: const Icon(
                                  CupertinoIcons.arrow_down_circle,
                                  size: 14,
                                ),
                                size: AppButtonSize.compact,
                                variant: AppButtonVariant.secondary,
                                onPressed: () async {
                                  final payment = await PaymentFormDialog.show(
                                    context,
                                    clientRepository:
                                        widget.dependencies.clientRepository,
                                    recordPayment:
                                        widget.dependencies.recordPayment,
                                    preselectedClientId: invoice.clientId,
                                  );
                                  if (payment != null) {
                                    await _refresh();
                                  }
                                },
                              ),
                            ],
                          ],
                        ),
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
                        'Created Date',
                        invoice.createdAt.toIso8601String().substring(0, 10),
                      ),
                      const SizedBox(width: AppSpacing.xl),
                      _buildMetaField(
                        context,
                        'Issued Date',
                        invoice.issuedAt?.toIso8601String().substring(0, 10) ??
                            'Draft (Not Issued)',
                      ),
                      const SizedBox(width: AppSpacing.xl),
                      _buildMetaField(
                        context,
                        'Line Items Count',
                        '${invoice.lines.length} items',
                      ),
                      const SizedBox(width: AppSpacing.xl),
                      if (invoice.notes != null)
                        Expanded(
                          child: _buildMetaField(
                            context,
                            'Notes',
                            invoice.notes!,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Line Items Table Card
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface(context),
                borderRadius: AppRadii.lgRadius,
                border: Border.all(color: AppColors.border(context)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x08000000),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const AppModernIcon(
                              icon: CupertinoIcons.list_bullet,
                              size: 30,
                              iconSize: 15,
                              showShadow: false,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              'Invoice Line Items',
                              style: AppTypography.headline.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary(context),
                              ),
                            ),
                          ],
                        ),
                        AppBadge(
                          label: '${invoice.lines.length} items',
                          variant: AppBadgeVariant.neutral,
                        ),
                      ],
                    ),
                  ),
                  Container(height: 1, color: AppColors.separator(context)),

                  // Clean Table Header
                  Container(
                    color: AppColors.surfaceSecondary(
                      context,
                    ).withValues(alpha: 0.6),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs + 2,
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 38,
                          child: Text(
                            '#',
                            style: AppTypography.caption2.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary(context),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          flex: 4,
                          child: Text(
                            'ITEM DESCRIPTION',
                            style: AppTypography.caption2.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                              color: AppColors.textSecondary(context),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 80,
                          child: Text(
                            'QTY',
                            style: AppTypography.caption2.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                              color: AppColors.textSecondary(context),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'UNIT PRICE',
                            style: AppTypography.caption2.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                              color: AppColors.textSecondary(context),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              'LINE TOTAL',
                              style: AppTypography.caption2.copyWith(
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                                color: AppColors.textSecondary(context),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(height: 1, color: AppColors.separator(context)),

                  // Clean Line Items Rows
                  for (int i = 0; i < invoice.lines.length; i++) ...[
                    _DesktopInvoiceLineRow(
                      line: invoice.lines[i],
                      index: i + 1,
                    ),
                    if (i < invoice.lines.length - 1)
                      Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                        ),
                        height: 0.8,
                        color: AppColors.separator(
                          context,
                        ).withValues(alpha: 0.5),
                      ),
                  ],

                  Container(height: 1, color: AppColors.separator(context)),

                  // Invoice Totals Footer
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              'Subtotal: ',
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
                        if (invoice.discountTotal.isPositive) ...[
                          const SizedBox(height: AppSpacing.xxs),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                'Discount: ',
                                style: AppTypography.caption1.copyWith(
                                  color: AppColors.textSecondary(context),
                                ),
                              ),
                              AppMoneyDisplay(
                                money: invoice.discountTotal,
                                style: AppTypography.caption1.copyWith(
                                  color: AppColors.destructive(context),
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: AppSpacing.xs),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              'Total Billed: ',
                              style: AppTypography.headline.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            AppMoneyDisplay(
                              money: invoice.total,
                              style: AppTypography.headline.copyWith(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryAccent(context),
                              ),
                            ),
                          ],
                        ),
                        if (invoice.isIssued) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                'Remaining Balance: ',
                                style: AppTypography.headline.copyWith(
                                  fontSize: 15,
                                  color: detailState.remainingBalance.isPositive
                                      ? AppColors.destructive(context)
                                      : AppColors.success(context),
                                ),
                              ),
                              AppMoneyDisplay(
                                money: detailState.remainingBalance,
                                style: AppTypography.headline.copyWith(
                                  fontSize: 17,
                                  color: detailState.remainingBalance.isPositive
                                      ? AppColors.destructive(context)
                                      : AppColors.success(context),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
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

class _DesktopInvoiceListItem extends StatefulWidget {
  const _DesktopInvoiceListItem({
    required this.invoice,
    required this.client,
    required this.isSelected,
    required this.onTap,
  });

  final Invoice invoice;
  final Client? client;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_DesktopInvoiceListItem> createState() =>
      _DesktopInvoiceListItemState();
}

class _DesktopInvoiceListItemState extends State<_DesktopInvoiceListItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final invoice = widget.invoice;
    final client = widget.client;
    final isSelected = widget.isSelected;

    final bgColor = isSelected
        ? AppColors.primaryAccent(context).withValues(alpha: 0.08)
        : (_isHovered ? AppColors.hover(context) : AppColors.surface(context));

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: AppDurations.motionDuration(
            context,
            AppDurations.selection,
          ),
          curve: AppDurations.easeOut,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: bgColor,
            border: Border(
              left: BorderSide(
                color: isSelected
                    ? AppColors.primaryAccent(context)
                    : CupertinoColors.transparent,
                width: 3.5,
              ),
            ),
          ),
          child: Row(
            children: [
              AppModernIcon(
                icon: invoice.isIssued
                    ? CupertinoIcons.checkmark_seal_fill
                    : CupertinoIcons.doc_text,
                size: 34,
                iconSize: 17,
                showShadow: false,
                gradient: invoice.isIssued
                    ? AppGradients.success(context)
                    : AppGradients.primary(context),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            invoice.number,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.body.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? AppColors.primaryAccent(context)
                                  : AppColors.textPrimary(context),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        AppBadge(
                          label: invoice.status.name.toUpperCase(),
                          variant: invoice.isIssued
                              ? AppBadgeVariant.success
                              : AppBadgeVariant.neutral,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      client?.name ?? 'Unknown Client',
                      style: AppTypography.caption1.copyWith(
                        color: AppColors.textSecondary(context),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      invoice.createdAt.toIso8601String().substring(0, 10),
                      style: AppTypography.caption2.copyWith(
                        color: AppColors.textTertiary(context),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              AppMoneyDisplay(
                money: invoice.total,
                style: AppTypography.headline.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DesktopInvoiceLineRow extends StatefulWidget {
  const _DesktopInvoiceLineRow({required this.line, required this.index});

  final InvoiceLine line;
  final int index;

  @override
  State<_DesktopInvoiceLineRow> createState() => _DesktopInvoiceLineRowState();
}

class _DesktopInvoiceLineRowState extends State<_DesktopInvoiceLineRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final line = widget.line;
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: AppDurations.motionDuration(context, AppDurations.quick),
        curve: AppDurations.easeOut,
        color: _isHovered
            ? AppColors.hover(context)
            : CupertinoColors.transparent,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + 2,
        ),
        child: Row(
          children: [
            // Item Index Chip
            SizedBox(
              width: 38,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.canvas(context),
                  borderRadius: AppRadii.xsRadius,
                  border: Border.all(color: AppColors.border(context)),
                ),
                alignment: Alignment.center,
                child: Text(
                  '#${widget.index}',
                  style: AppTypography.caption2.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary(context),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            // Description
            Expanded(
              flex: 4,
              child: Text(
                line.description,
                style: AppTypography.body.copyWith(
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary(context),
                ),
              ),
            ),
            // Qty
            SizedBox(
              width: 80,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.canvas(context),
                    borderRadius: AppRadii.pillRadius,
                  ),
                  child: Text(
                    '${line.quantity}x',
                    style: AppTypography.caption1.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary(context),
                    ),
                  ),
                ),
              ),
            ),
            // Unit Price
            Expanded(
              flex: 2,
              child: AppMoneyDisplay(
                money: line.unitPrice,
                style: AppTypography.body.copyWith(
                  color: AppColors.textSecondary(context),
                ),
              ),
            ),
            // Line Total
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerRight,
                child: AppMoneyDisplay(
                  money: line.lineTotal,
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary(context),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
