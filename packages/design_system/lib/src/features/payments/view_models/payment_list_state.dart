import 'package:domain/domain.dart';
import 'package:flutter/foundation.dart';

enum PaymentListStatus { initial, loading, loaded, error }

@immutable
class PaymentListViewState {
  const PaymentListViewState({
    this.status = PaymentListStatus.initial,
    this.payments = const [],
    this.filteredPayments = const [],
    this.clientsById = const {},
    this.searchQuery = '',
    this.errorMessage,
  });

  final PaymentListStatus status;
  final List<Payment> payments;
  final List<Payment> filteredPayments;
  final Map<ClientId, Client> clientsById;
  final String searchQuery;
  final String? errorMessage;

  bool get isLoading => status == PaymentListStatus.loading && payments.isEmpty;
  bool get isLoaded => status == PaymentListStatus.loaded;
  bool get hasError => status == PaymentListStatus.error;
  bool get isEmpty => status == PaymentListStatus.loaded && payments.isEmpty;
  bool get isSearchEmpty =>
      status == PaymentListStatus.loaded &&
      payments.isNotEmpty &&
      filteredPayments.isEmpty;

  int get totalCount => payments.length;
  int get filteredCount => filteredPayments.length;

  PaymentListViewState copyWith({
    PaymentListStatus? status,
    List<Payment>? payments,
    List<Payment>? filteredPayments,
    Map<ClientId, Client>? clientsById,
    String? searchQuery,
    String? errorMessage,
  }) {
    return PaymentListViewState(
      status: status ?? this.status,
      payments: payments ?? this.payments,
      filteredPayments: filteredPayments ?? this.filteredPayments,
      clientsById: clientsById ?? this.clientsById,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaymentListViewState &&
          other.status == status &&
          other.searchQuery == searchQuery &&
          other.errorMessage == errorMessage &&
          other.payments.length == payments.length &&
          other.filteredPayments.length == filteredPayments.length;

  @override
  int get hashCode => Object.hash(
    status,
    searchQuery,
    errorMessage,
    payments.length,
    filteredPayments.length,
  );
}
