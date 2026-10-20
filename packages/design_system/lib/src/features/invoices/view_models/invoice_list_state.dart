import 'package:domain/domain.dart';
import 'package:flutter/foundation.dart';

enum InvoiceListStatus { initial, loading, loaded, error }

@immutable
class InvoiceListViewState {
  const InvoiceListViewState({
    this.status = InvoiceListStatus.initial,
    this.invoices = const [],
    this.filteredInvoices = const [],
    this.clientsById = const {},
    this.statusFilter,
    this.searchQuery = '',
    this.errorMessage,
  });

  final InvoiceListStatus status;
  final List<Invoice> invoices;
  final List<Invoice> filteredInvoices;
  final Map<ClientId, Client> clientsById;
  final InvoiceStatus? statusFilter;
  final String searchQuery;
  final String? errorMessage;

  bool get isLoading => status == InvoiceListStatus.loading && invoices.isEmpty;
  bool get isLoaded => status == InvoiceListStatus.loaded;
  bool get hasError => status == InvoiceListStatus.error;
  bool get isEmpty => status == InvoiceListStatus.loaded && invoices.isEmpty;
  bool get isSearchEmpty =>
      status == InvoiceListStatus.loaded &&
      invoices.isNotEmpty &&
      filteredInvoices.isEmpty;

  int get totalCount => invoices.length;
  int get filteredCount => filteredInvoices.length;

  InvoiceListViewState copyWith({
    InvoiceListStatus? status,
    List<Invoice>? invoices,
    List<Invoice>? filteredInvoices,
    Map<ClientId, Client>? clientsById,
    InvoiceStatus? Function()? statusFilter,
    String? searchQuery,
    String? errorMessage,
  }) {
    return InvoiceListViewState(
      status: status ?? this.status,
      invoices: invoices ?? this.invoices,
      filteredInvoices: filteredInvoices ?? this.filteredInvoices,
      clientsById: clientsById ?? this.clientsById,
      statusFilter: statusFilter != null ? statusFilter() : this.statusFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InvoiceListViewState &&
          other.status == status &&
          other.searchQuery == searchQuery &&
          other.statusFilter == statusFilter &&
          other.errorMessage == errorMessage &&
          other.invoices.length == invoices.length &&
          other.filteredInvoices.length == filteredInvoices.length;

  @override
  int get hashCode => Object.hash(
    status,
    searchQuery,
    statusFilter,
    errorMessage,
    invoices.length,
    filteredInvoices.length,
  );
}
