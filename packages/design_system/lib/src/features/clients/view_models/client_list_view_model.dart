import 'package:application/application.dart';
import 'package:domain/domain.dart';
import 'package:flutter/foundation.dart';

import 'client_list_state.dart';

/// ViewModel orchestrating client listing, search filtering, and state transitions.
///
/// Fully decoupled from UI widgets and easily tested with unit tests.
class ClientListViewModel extends ChangeNotifier {
  ClientListViewModel({required this.repository});

  final ClientRepository repository;

  ClientListViewState _state = const ClientListViewState();
  ClientListViewState get state => _state;

  /// Loads all clients from the repository and initializes list state.
  Future<void> loadClients({bool showLoading = true}) async {
    if (showLoading || _state.status != ClientListStatus.loaded) {
      _state = _state.copyWith(
        status: ClientListStatus.loading,
        errorMessage: null,
      );
      notifyListeners();
    }

    try {
      final clients = await repository.getAll();
      final sortedClients = List<Client>.from(clients)
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

      final filtered = _applyFilter(sortedClients, _state.searchQuery);

      _state = _state.copyWith(
        status: ClientListStatus.loaded,
        clients: sortedClients,
        filteredClients: filtered,
      );
    } catch (e) {
      _state = _state.copyWith(
        status: ClientListStatus.error,
        errorMessage: 'Failed to load clients: $e',
      );
    }
    notifyListeners();
  }

  /// Searches clients in-memory by name and phone number.
  void search(String query) {
    final trimmed = query.trim();
    final filtered = _applyFilter(_state.clients, trimmed);

    _state = _state.copyWith(searchQuery: query, filteredClients: filtered);
    notifyListeners();
  }

  /// Clears the active search query.
  void clearSearch() {
    search('');
  }

  /// Deletes a client by ID.
  Future<bool> deleteClient(ClientId id) async {
    try {
      await repository.deleteById(id);
      final remaining = _state.clients.where((c) => c.id != id).toList();
      final filtered = _applyFilter(remaining, _state.searchQuery);

      _state = _state.copyWith(clients: remaining, filteredClients: filtered);
      notifyListeners();
      return true;
    } catch (e) {
      _state = _state.copyWith(
        status: ClientListStatus.error,
        errorMessage: 'Failed to delete client: $e',
      );
      notifyListeners();
      return false;
    }
  }

  /// Refreshes the client list while maintaining current search filter.
  Future<void> refresh() => loadClients(showLoading: false);

  List<Client> _applyFilter(List<Client> list, String query) {
    if (query.isEmpty) return list;

    final lower = query.toLowerCase();
    return list.where((client) {
      final matchesName = client.name.toLowerCase().contains(lower);
      final matchesPhone =
          client.phone != null && client.phone!.toLowerCase().contains(lower);
      return matchesName || matchesPhone;
    }).toList();
  }
}
