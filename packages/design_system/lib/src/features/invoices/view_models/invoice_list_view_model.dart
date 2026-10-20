import 'package:application/application.dart';
import 'package:domain/domain.dart';
import 'package:flutter/foundation.dart';

import 'invoice_list_state.dart';

/// ViewModel orchestrating invoice list querying, status filtering, and search.
class InvoiceListViewModel extends ChangeNotifier {
  InvoiceListViewModel({
    required this.invoiceRepository,
    required this.clientRepository,
  });

  final InvoiceRepository invoiceRepository;
  final ClientRepository clientRepository;

  InvoiceListViewState _state = const InvoiceListViewState();
  InvoiceListViewState get state => _state;

  Future<void> loadInvoices({bool showLoading = true}) async {
    if (showLoading || _state.status != InvoiceListStatus.loaded) {
      _state = _state.copyWith(
        status: InvoiceListStatus.loading,
        errorMessage: null,
      );
      notifyListeners();
    }

    try {
      final invoices = await invoiceRepository.getAll();
      final clients = await clientRepository.getAll();
      final clientsById = {for (final c in clients) c.id: c};

      final sorted = List<Invoice>.from(invoices)
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      final filtered = _applyFilter(
        sorted,
        _state.searchQuery,
        _state.statusFilter,
        clientsById,
      );

      _state = _state.copyWith(
        status: InvoiceListStatus.loaded,
        invoices: sorted,
        filteredInvoices: filtered,
        clientsById: clientsById,
      );
    } catch (e) {
      _state = _state.copyWith(
        status: InvoiceListStatus.error,
        errorMessage: 'Failed to load invoices: $e',
      );
    }
    notifyListeners();
  }

  void search(String query) {
    final filtered = _applyFilter(
      _state.invoices,
      query,
      _state.statusFilter,
      _state.clientsById,
    );
    _state = _state.copyWith(searchQuery: query, filteredInvoices: filtered);
    notifyListeners();
  }

  void clearSearch() => search('');

  void filterByStatus(InvoiceStatus? status) {
    final filtered = _applyFilter(
      _state.invoices,
      _state.searchQuery,
      status,
      _state.clientsById,
    );
    _state = _state.copyWith(
      statusFilter: () => status,
      filteredInvoices: filtered,
    );
    notifyListeners();
  }

  Future<void> refresh() => loadInvoices(showLoading: false);

  List<Invoice> _applyFilter(
    List<Invoice> list,
    String query,
    InvoiceStatus? status,
    Map<ClientId, Client> clientsById,
  ) {
    var result = list;
    if (status != null) {
      result = result.where((inv) => inv.status == status).toList();
    }

    final trimmed = query.trim().toLowerCase();
    if (trimmed.isEmpty) return result;

    return result.where((inv) {
      final matchesNumber = inv.number.toLowerCase().contains(trimmed);
      final client = clientsById[inv.clientId];
      final matchesClient =
          client != null && client.name.toLowerCase().contains(trimmed);
      return matchesNumber || matchesClient;
    }).toList();
  }
}
