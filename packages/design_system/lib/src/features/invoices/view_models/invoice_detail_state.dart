import 'package:domain/domain.dart';
import 'package:flutter/foundation.dart';

enum InvoiceDetailStatus { initial, loading, loaded, mutating, error }

@immutable
class InvoiceDetailState {
  const InvoiceDetailState({
    this.status = InvoiceDetailStatus.initial,
    this.invoice,
    this.client,
    this.allocations = const [],
    this.errorMessage,
  });

  final InvoiceDetailStatus status;
  final Invoice? invoice;
  final Client? client;
  final List<PaymentAllocation> allocations;
  final String? errorMessage;

  bool get isLoading =>
      status == InvoiceDetailStatus.loading && invoice == null;
  bool get isLoaded => status == InvoiceDetailStatus.loaded;
  bool get isMutating => status == InvoiceDetailStatus.mutating;
  bool get hasError => status == InvoiceDetailStatus.error;

  Money get totalAllocated {
    if (invoice == null) return Money.zero(Currency.dzd);
    var sum = Money.zero(invoice!.currency);
    for (final a in allocations) {
      if (a.currency == invoice!.currency) {
        sum += a.amount;
      }
    }
    return sum;
  }

  Money get remainingBalance {
    if (invoice == null) return Money.zero(Currency.dzd);
    return invoice!.total > totalAllocated
        ? invoice!.total - totalAllocated
        : Money.zero(invoice!.currency);
  }

  bool get isFullyPaid =>
      invoice != null && invoice!.isIssued && remainingBalance.isZero;

  InvoiceDetailState copyWith({
    InvoiceDetailStatus? status,
    Invoice? invoice,
    Client? client,
    List<PaymentAllocation>? allocations,
    String? errorMessage,
  }) {
    return InvoiceDetailState(
      status: status ?? this.status,
      invoice: invoice ?? this.invoice,
      client: client ?? this.client,
      allocations: allocations ?? this.allocations,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InvoiceDetailState &&
          other.status == status &&
          other.invoice == invoice &&
          other.client == client &&
          other.allocations.length == allocations.length &&
          other.errorMessage == errorMessage;

  @override
  int get hashCode =>
      Object.hash(status, invoice, client, allocations.length, errorMessage);
}
