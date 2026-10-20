import 'package:domain/domain.dart';
import 'package:flutter/foundation.dart';

enum PaymentFormStatus { initial, loading, submitting, success, error }

@immutable
class PaymentFormState {
  const PaymentFormState({
    this.status = PaymentFormStatus.initial,
    this.selectedClient,
    this.availableClients = const [],
    this.amount,
    this.amountText = '',
    this.currency = Currency.dzd,
    required this.receivedAt,
    this.notes = '',
    this.clientError,
    this.amountError,
    this.errorMessage,
  });

  final PaymentFormStatus status;
  final Client? selectedClient;
  final List<Client> availableClients;
  final Money? amount;
  final String amountText;
  final Currency currency;
  final DateTime receivedAt;
  final String notes;

  final String? clientError;
  final String? amountError;
  final String? errorMessage;

  bool get isSubmitting => status == PaymentFormStatus.submitting;
  bool get isSuccess => status == PaymentFormStatus.success;

  PaymentFormState copyWith({
    PaymentFormStatus? status,
    Client? Function()? selectedClient,
    List<Client>? availableClients,
    Money? Function()? amount,
    String? amountText,
    Currency? currency,
    DateTime? receivedAt,
    String? notes,
    String? clientError,
    String? amountError,
    String? errorMessage,
  }) {
    return PaymentFormState(
      status: status ?? this.status,
      selectedClient: selectedClient != null
          ? selectedClient()
          : this.selectedClient,
      availableClients: availableClients ?? this.availableClients,
      amount: amount != null ? amount() : this.amount,
      amountText: amountText ?? this.amountText,
      currency: currency ?? this.currency,
      receivedAt: receivedAt ?? this.receivedAt,
      notes: notes ?? this.notes,
      clientError: clientError,
      amountError: amountError,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
