import 'package:domain/domain.dart';
import 'package:flutter/foundation.dart';

enum FinancialOverviewStatus { initial, loading, loaded, error }

enum FinancialClientFilter { all, debtors, creditors, balanced }

@immutable
class ClientFinancialRow {
  const ClientFinancialRow({required this.client, required this.position});

  final Client client;
  final ClientFinancialPosition position;
}

@immutable
class FinancialOverviewState {
  const FinancialOverviewState({
    this.status = FinancialOverviewStatus.initial,
    this.clientRows = const [],
    this.filteredRows = const [],
    this.totalBilled,
    this.totalAllocated,
    this.totalOutstandingDebt,
    this.totalUnallocatedCredit,
    this.netPosition,
    this.currency = Currency.dzd,
    this.filter = FinancialClientFilter.all,
    this.searchQuery = '',
    this.errorMessage,
  });

  final FinancialOverviewStatus status;
  final List<ClientFinancialRow> clientRows;
  final List<ClientFinancialRow> filteredRows;
  final Money? totalBilled;
  final Money? totalAllocated;
  final Money? totalOutstandingDebt;
  final Money? totalUnallocatedCredit;
  final Money? netPosition;
  final Currency currency;
  final FinancialClientFilter filter;
  final String searchQuery;
  final String? errorMessage;

  bool get isLoading =>
      status == FinancialOverviewStatus.loading && clientRows.isEmpty;
  bool get isLoaded => status == FinancialOverviewStatus.loaded;
  bool get hasError => status == FinancialOverviewStatus.error;

  FinancialOverviewState copyWith({
    FinancialOverviewStatus? status,
    List<ClientFinancialRow>? clientRows,
    List<ClientFinancialRow>? filteredRows,
    Money? totalBilled,
    Money? totalAllocated,
    Money? totalOutstandingDebt,
    Money? totalUnallocatedCredit,
    Money? netPosition,
    Currency? currency,
    FinancialClientFilter? filter,
    String? searchQuery,
    String? errorMessage,
  }) {
    return FinancialOverviewState(
      status: status ?? this.status,
      clientRows: clientRows ?? this.clientRows,
      filteredRows: filteredRows ?? this.filteredRows,
      totalBilled: totalBilled ?? this.totalBilled,
      totalAllocated: totalAllocated ?? this.totalAllocated,
      totalOutstandingDebt: totalOutstandingDebt ?? this.totalOutstandingDebt,
      totalUnallocatedCredit:
          totalUnallocatedCredit ?? this.totalUnallocatedCredit,
      netPosition: netPosition ?? this.netPosition,
      currency: currency ?? this.currency,
      filter: filter ?? this.filter,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FinancialOverviewState &&
          other.status == status &&
          other.filter == filter &&
          other.searchQuery == searchQuery &&
          other.clientRows.length == clientRows.length &&
          other.filteredRows.length == filteredRows.length &&
          other.errorMessage == errorMessage;

  @override
  int get hashCode => Object.hash(
    status,
    filter,
    searchQuery,
    clientRows.length,
    filteredRows.length,
    errorMessage,
  );
}
