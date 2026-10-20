import 'package:domain/domain.dart';
import 'package:flutter/foundation.dart';

enum AllocationWorkflowStatus { initial, loading, submitting, success, error }

/// Candidate payment with pre-computed remaining capacity.
@immutable
class PaymentCandidate {
  const PaymentCandidate({
    required this.payment,
    required this.allocatedAmount,
    required this.remainingCapacity,
  });

  final Payment payment;
  final Money allocatedAmount;
  final Money remainingCapacity;
}

/// Candidate invoice with pre-computed remaining unpaid debt.
@immutable
class InvoiceCandidate {
  const InvoiceCandidate({
    required this.invoice,
    required this.allocatedAmount,
    required this.remainingBalance,
  });

  final Invoice invoice;
  final Money allocatedAmount;
  final Money remainingBalance;
}

@immutable
class AllocationWorkflowState {
  const AllocationWorkflowState({
    this.status = AllocationWorkflowStatus.initial,
    this.availableClients = const [],
    this.selectedClient,
    this.candidatePayments = const [],
    this.candidateInvoices = const [],
    this.selectedPayment,
    this.selectedInvoice,
    this.amount,
    this.amountText = '',
    this.amountError,
    this.errorMessage,
  });

  final AllocationWorkflowStatus status;
  final List<Client> availableClients;
  final Client? selectedClient;
  final List<PaymentCandidate> candidatePayments;
  final List<InvoiceCandidate> candidateInvoices;
  final PaymentCandidate? selectedPayment;
  final InvoiceCandidate? selectedInvoice;
  final Money? amount;
  final String amountText;
  final String? amountError;
  final String? errorMessage;

  bool get isLoading => status == AllocationWorkflowStatus.loading;
  bool get isSubmitting => status == AllocationWorkflowStatus.submitting;
  bool get isSuccess => status == AllocationWorkflowStatus.success;

  Money? get maxAllocatableAmount {
    if (selectedPayment == null || selectedInvoice == null) return null;
    final payRemaining = selectedPayment!.remainingCapacity;
    final invRemaining = selectedInvoice!.remainingBalance;
    return payRemaining < invRemaining ? payRemaining : invRemaining;
  }

  AllocationWorkflowState copyWith({
    AllocationWorkflowStatus? status,
    List<Client>? availableClients,
    Client? Function()? selectedClient,
    List<PaymentCandidate>? candidatePayments,
    List<InvoiceCandidate>? candidateInvoices,
    PaymentCandidate? Function()? selectedPayment,
    InvoiceCandidate? Function()? selectedInvoice,
    Money? Function()? amount,
    String? amountText,
    String? amountError,
    String? errorMessage,
  }) {
    return AllocationWorkflowState(
      status: status ?? this.status,
      availableClients: availableClients ?? this.availableClients,
      selectedClient: selectedClient != null
          ? selectedClient()
          : this.selectedClient,
      candidatePayments: candidatePayments ?? this.candidatePayments,
      candidateInvoices: candidateInvoices ?? this.candidateInvoices,
      selectedPayment: selectedPayment != null
          ? selectedPayment()
          : this.selectedPayment,
      selectedInvoice: selectedInvoice != null
          ? selectedInvoice()
          : this.selectedInvoice,
      amount: amount != null ? amount() : this.amount,
      amountText: amountText ?? this.amountText,
      amountError: amountError,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
