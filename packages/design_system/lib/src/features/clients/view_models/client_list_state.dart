import 'package:domain/domain.dart';
import 'package:flutter/foundation.dart';

enum ClientListStatus { initial, loading, loaded, error }

@immutable
class ClientListViewState {
  const ClientListViewState({
    this.status = ClientListStatus.initial,
    this.clients = const [],
    this.filteredClients = const [],
    this.searchQuery = '',
    this.errorMessage,
  });

  final ClientListStatus status;
  final List<Client> clients;
  final List<Client> filteredClients;
  final String searchQuery;
  final String? errorMessage;

  bool get isLoading => status == ClientListStatus.loading && clients.isEmpty;
  bool get isRefreshing =>
      status == ClientListStatus.loading && clients.isNotEmpty;
  bool get isLoaded => status == ClientListStatus.loaded;
  bool get hasError => status == ClientListStatus.error;

  /// True when the user has zero clients in total.
  bool get isEmpty => status == ClientListStatus.loaded && clients.isEmpty;

  /// True when clients exist, but the current search query returned zero matches.
  bool get isSearchEmpty =>
      status == ClientListStatus.loaded &&
      clients.isNotEmpty &&
      filteredClients.isEmpty &&
      searchQuery.trim().isNotEmpty;

  int get totalCount => clients.length;
  int get filteredCount => filteredClients.length;

  ClientListViewState copyWith({
    ClientListStatus? status,
    List<Client>? clients,
    List<Client>? filteredClients,
    String? searchQuery,
    String? errorMessage,
  }) {
    return ClientListViewState(
      status: status ?? this.status,
      clients: clients ?? this.clients,
      filteredClients: filteredClients ?? this.filteredClients,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClientListViewState &&
          other.status == status &&
          other.searchQuery == searchQuery &&
          other.errorMessage == errorMessage &&
          other.clients.length == clients.length &&
          other.filteredClients.length == filteredClients.length;

  @override
  int get hashCode => Object.hash(
    status,
    searchQuery,
    errorMessage,
    clients.length,
    filteredClients.length,
  );
}
