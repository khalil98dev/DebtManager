import 'package:domain/domain.dart';
import 'package:flutter/foundation.dart';

enum PaymentDetailStatus { initial, loading, loaded, error }

@immutable
class PaymentDetailState {
  const PaymentDetailState({
    this.status = PaymentDetailStatus.initial,
    this.payment,
    this.client,
    this.allocations = const [],
    this.errorMessage,
  });

  final PaymentDetailStatus status;
  final Payment? payment;
  final Client? client;
  final List<PaymentAllocation> allocations;
  final String? errorMessage;

  bool get isLoading =>
      status == PaymentDetailStatus.loading && payment == null;
  bool get isLoaded => status == PaymentDetailStatus.loaded;
  bool get hasError => status == PaymentDetailStatus.error;

  Money get totalAllocated {
    if (payment == null) return Money.zero(Currency.dzd);
    var sum = Money.zero(payment!.currency);
    for (final a in allocations) {
      if (a.currency == payment!.currency) {
        sum += a.amount;
      }
    }
    return sum;
  }

  Money get unallocatedCredit {
    if (payment == null) return Money.zero(Currency.dzd);
    return payment!.amount > totalAllocated
        ? payment!.amount - totalAllocated
        : Money.zero(payment!.currency);
  }

  bool get isFullyAllocated => payment != null && unallocatedCredit.isZero;

  PaymentDetailState copyWith({
    PaymentDetailStatus? status,
    Payment? payment,
    Client? client,
    List<PaymentAllocation>? allocations,
    String? errorMessage,
  }) {
    return PaymentDetailState(
      status: status ?? this.status,
      payment: payment ?? this.payment,
      client: client ?? this.client,
      allocations: allocations ?? this.allocations,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaymentDetailState &&
          other.status == status &&
          other.payment == payment &&
          other.client == client &&
          other.allocations.length == allocations.length &&
          other.errorMessage == errorMessage;

  @override
  int get hashCode =>
      Object.hash(status, payment, client, allocations.length, errorMessage);
}
