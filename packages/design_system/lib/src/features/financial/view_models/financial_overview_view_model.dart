import 'package:application/application.dart';
import 'package:domain/domain.dart';
import 'package:flutter/foundation.dart';

import 'financial_overview_state.dart';

/// ViewModel orchestrating client financial positions portfolio overview.
class FinancialOverviewViewModel extends ChangeNotifier {
  FinancialOverviewViewModel({
    required this.clientRepository,
    required this.getClientFinancialPosition,
  });

  final ClientRepository clientRepository;
  final GetClientFinancialPosition getClientFinancialPosition;

  FinancialOverviewState _state = const FinancialOverviewState();
  FinancialOverviewState get state => _state;

  Future<void> loadOverview({Currency? currency}) async {
    _state = _state.copyWith(
      status: FinancialOverviewStatus.loading,
      errorMessage: null,
    );
    notifyListeners();

    try {
      final clients = await clientRepository.getAll();
      final targetCurrency = currency ?? _state.currency;

      var totalBilled = Money.zero(targetCurrency);
      var totalAllocated = Money.zero(targetCurrency);
      var totalDebt = Money.zero(targetCurrency);
      var totalCredit = Money.zero(targetCurrency);

      final clientRows = <ClientFinancialRow>[];
      for (final client in clients) {
        final posResult = await getClientFinancialPosition.execute(
          GetClientFinancialPositionQuery(
            clientId: client.id,
            currency: targetCurrency,
          ),
        );
        if (posResult.isSuccess) {
          final pos = posResult.dataOrNull!;
          clientRows.add(ClientFinancialRow(client: client, position: pos));
          totalBilled += pos.totalInvoiced;
          totalAllocated += pos.totalAllocatedPayments;
          totalDebt += pos.outstandingDebt;
          totalCredit += pos.unallocatedCredit;
        }
      }

      final netPosition = totalDebt - totalCredit;

      final filtered = _applyFilter(
        clientRows,
        _state.filter,
        _state.searchQuery,
      );

      _state = _state.copyWith(
        status: FinancialOverviewStatus.loaded,
        clientRows: clientRows,
        filteredRows: filtered,
        totalBilled: totalBilled,
        totalAllocated: totalAllocated,
        totalOutstandingDebt: totalDebt,
        totalUnallocatedCredit: totalCredit,
        netPosition: netPosition,
        currency: targetCurrency,
      );
    } catch (e) {
      _state = _state.copyWith(
        status: FinancialOverviewStatus.error,
        errorMessage: 'Failed to load financial overview: $e',
      );
    }
    notifyListeners();
  }

  void search(String query) {
    final filtered = _applyFilter(_state.clientRows, _state.filter, query);
    _state = _state.copyWith(searchQuery: query, filteredRows: filtered);
    notifyListeners();
  }

  void clearSearch() => search('');

  void setFilter(FinancialClientFilter filter) {
    final filtered = _applyFilter(
      _state.clientRows,
      filter,
      _state.searchQuery,
    );
    _state = _state.copyWith(filter: filter, filteredRows: filtered);
    notifyListeners();
  }

  Future<void> refresh() => loadOverview(currency: _state.currency);

  List<ClientFinancialRow> _applyFilter(
    List<ClientFinancialRow> list,
    FinancialClientFilter filter,
    String query,
  ) {
    var result = list;
    switch (filter) {
      case FinancialClientFilter.all:
        break;
      case FinancialClientFilter.debtors:
        result = result.where((r) => r.position.hasOutstandingDebt).toList();
      case FinancialClientFilter.creditors:
        result = result.where((r) => r.position.hasUnallocatedCredit).toList();
      case FinancialClientFilter.balanced:
        result = result.where((r) => r.position.isBalanced).toList();
    }

    final trimmed = query.trim().toLowerCase();
    if (trimmed.isEmpty) return result;

    return result
        .where((r) => r.client.name.toLowerCase().contains(trimmed))
        .toList();
  }
}
