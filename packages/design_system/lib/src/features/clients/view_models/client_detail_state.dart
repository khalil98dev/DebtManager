import 'package:domain/domain.dart';
import 'package:flutter/foundation.dart';

enum ClientDetailStatus { initial, loading, loaded, error }

@immutable
class ClientDetailState {
  const ClientDetailState({
    this.status = ClientDetailStatus.initial,
    this.client,
    this.position,
    this.invoices = const [],
    this.payments = const [],
    this.allocations = const [],
    this.errorMessage,
  });

  final ClientDetailStatus status;
  final Client? client;
  final ClientFinancialPosition? position;
  final List<Invoice> invoices;
  final List<Payment> payments;
  final List<PaymentAllocation> allocations;
  final String? errorMessage;

  bool get isLoading => status == ClientDetailStatus.loading && client == null;
  bool get isLoaded => status == ClientDetailStatus.loaded;
  bool get hasError => status == ClientDetailStatus.error;

  ClientDetailState copyWith({
    ClientDetailStatus? status,
    Client? client,
    ClientFinancialPosition? position,
    List<Invoice>? invoices,
    List<Payment>? payments,
    List<PaymentAllocation>? allocations,
    String? errorMessage,
  }) {
    return ClientDetailState(
      status: status ?? this.status,
      client: client ?? this.client,
      position: position ?? this.position,
      invoices: invoices ?? this.invoices,
      payments: payments ?? this.payments,
      allocations: allocations ?? this.allocations,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClientDetailState &&
          other.status == status &&
          other.client == client &&
          other.position == position &&
          other.errorMessage == errorMessage &&
          other.invoices.length == invoices.length &&
          other.payments.length == payments.length;

  @override
  int get hashCode => Object.hash(
    status,
    client,
    position,
    invoices.length,
    payments.length,
    errorMessage,
  );
}
