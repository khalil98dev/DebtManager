import 'package:application/application.dart';
import 'package:domain/domain.dart';
import 'package:flutter/foundation.dart';

import 'payment_list_state.dart';

/// ViewModel orchestrating payment listing, search, and client resolution.
class PaymentListViewModel extends ChangeNotifier {
  PaymentListViewModel({
    required this.paymentRepository,
    required this.clientRepository,
  });

  final PaymentRepository paymentRepository;
  final ClientRepository clientRepository;

  PaymentListViewState _state = const PaymentListViewState();
  PaymentListViewState get state => _state;

  Future<void> loadPayments({bool showLoading = true}) async {
    if (showLoading || _state.status != PaymentListStatus.loaded) {
      _state = _state.copyWith(
        status: PaymentListStatus.loading,
        errorMessage: null,
      );
      notifyListeners();
    }

    try {
      final payments = await paymentRepository.getAll();
      final clients = await clientRepository.getAll();
      final clientsById = {for (final c in clients) c.id: c};

      final sorted = List<Payment>.from(payments)
        ..sort((a, b) => b.receivedAt.compareTo(a.receivedAt));

      final filtered = _applyFilter(sorted, _state.searchQuery, clientsById);

      _state = _state.copyWith(
        status: PaymentListStatus.loaded,
        payments: sorted,
        filteredPayments: filtered,
        clientsById: clientsById,
      );
    } catch (e) {
      _state = _state.copyWith(
        status: PaymentListStatus.error,
        errorMessage: 'Failed to load payments: $e',
      );
    }
    notifyListeners();
  }

  void search(String query) {
    final filtered = _applyFilter(_state.payments, query, _state.clientsById);
    _state = _state.copyWith(searchQuery: query, filteredPayments: filtered);
    notifyListeners();
  }

  void clearSearch() => search('');

  Future<void> refresh() => loadPayments(showLoading: false);

  List<Payment> _applyFilter(
    List<Payment> list,
    String query,
    Map<ClientId, Client> clientsById,
  ) {
    final trimmed = query.trim().toLowerCase();
    if (trimmed.isEmpty) return list;

    return list.where((p) {
      final client = clientsById[p.clientId];
      final matchesClient =
          client != null && client.name.toLowerCase().contains(trimmed);
      final matchesNotes =
          p.notes != null && p.notes!.toLowerCase().contains(trimmed);
      return matchesClient || matchesNotes;
    }).toList();
  }
}
