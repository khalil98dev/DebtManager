import 'package:application/application.dart';
import 'package:domain/domain.dart';
import 'package:flutter/foundation.dart';

import 'allocation_workflow_state.dart';

/// ViewModel orchestrating payment-to-invoice allocation workflows.
class AllocationWorkflowViewModel extends ChangeNotifier {
  AllocationWorkflowViewModel({
    required this.clientRepository,
    required this.invoiceRepository,
    required this.paymentRepository,
    required this.paymentAllocationRepository,
    required this.allocatePayment,
    ClientId? preselectedClientId,
    PaymentId? preselectedPaymentId,
    InvoiceId? preselectedInvoiceId,
  }) {
    _preselectedClientId = preselectedClientId;
    _preselectedPaymentId = preselectedPaymentId;
    _preselectedInvoiceId = preselectedInvoiceId;
  }

  final ClientRepository clientRepository;
  final InvoiceRepository invoiceRepository;
  final PaymentRepository paymentRepository;
  final PaymentAllocationRepository paymentAllocationRepository;
  final AllocatePayment allocatePayment;

  ClientId? _preselectedClientId;
  PaymentId? _preselectedPaymentId;
  InvoiceId? _preselectedInvoiceId;

  AllocationWorkflowState _state = const AllocationWorkflowState();
  AllocationWorkflowState get state => _state;

  Future<void> initialize() async {
    _state = _state.copyWith(status: AllocationWorkflowStatus.loading);
    notifyListeners();

    try {
      final clients = await clientRepository.getAll();
      _state = _state.copyWith(
        status: AllocationWorkflowStatus.initial,
        availableClients: clients,
      );

      if (_preselectedClientId != null) {
        final client = clients
            .where((c) => c.id == _preselectedClientId)
            .firstOrNull;
        if (client != null) {
          await onClientSelected(client);
        }
      }
    } catch (e) {
      _state = _state.copyWith(
        status: AllocationWorkflowStatus.error,
        errorMessage: 'Failed to initialize allocation candidates: $e',
      );
    }
    notifyListeners();
  }

  Future<void> onClientSelected(Client client) async {
    _state = _state.copyWith(
      selectedClient: () => client,
      selectedPayment: () => null,
      selectedInvoice: () => null,
      amount: () => null,
      amountText: '',
      amountError: null,
      errorMessage: null,
    );
    notifyListeners();

    try {
      final payments = await paymentRepository.getByClientId(client.id);
      final invoices = await invoiceRepository.getByClientId(
        client.id,
        status: InvoiceStatus.issued,
      );
      final allocations = await paymentAllocationRepository.getByClientId(
        client.id,
      );

      // Compute allocations by payment
      final allocsByPayment = <PaymentId, Money>{};
      for (final a in allocations) {
        allocsByPayment[a.paymentId] =
            (allocsByPayment[a.paymentId] ?? Money.zero(a.currency)) + a.amount;
      }

      // Compute allocations by invoice
      final allocsByInvoice = <InvoiceId, Money>{};
      for (final a in allocations) {
        allocsByInvoice[a.invoiceId] =
            (allocsByInvoice[a.invoiceId] ?? Money.zero(a.currency)) + a.amount;
      }

      // Filter payments with remaining capacity > 0
      final candidatePayments = <PaymentCandidate>[];
      for (final p in payments) {
        final allocated = allocsByPayment[p.id] ?? Money.zero(p.currency);
        final remaining = p.amount > allocated
            ? p.amount - allocated
            : Money.zero(p.currency);
        if (remaining.isPositive) {
          candidatePayments.add(
            PaymentCandidate(
              payment: p,
              allocatedAmount: allocated,
              remainingCapacity: remaining,
            ),
          );
        }
      }

      // Filter issued invoices with remaining balance > 0
      final candidateInvoices = <InvoiceCandidate>[];
      for (final inv in invoices) {
        final allocated = allocsByInvoice[inv.id] ?? Money.zero(inv.currency);
        final remaining = inv.total > allocated
            ? inv.total - allocated
            : Money.zero(inv.currency);
        if (remaining.isPositive) {
          candidateInvoices.add(
            InvoiceCandidate(
              invoice: inv,
              allocatedAmount: allocated,
              remainingBalance: remaining,
            ),
          );
        }
      }

      PaymentCandidate? selectedPayment;
      if (_preselectedPaymentId != null) {
        selectedPayment = candidatePayments
            .where((p) => p.payment.id == _preselectedPaymentId)
            .firstOrNull;
      }

      InvoiceCandidate? selectedInvoice;
      if (_preselectedInvoiceId != null) {
        selectedInvoice = candidateInvoices
            .where((i) => i.invoice.id == _preselectedInvoiceId)
            .firstOrNull;
      }

      _state = _state.copyWith(
        candidatePayments: candidatePayments,
        candidateInvoices: candidateInvoices,
        selectedPayment: () => selectedPayment ?? candidatePayments.firstOrNull,
        selectedInvoice: () => selectedInvoice ?? candidateInvoices.firstOrNull,
      );

      _autoFillMaxAmount();
    } catch (e) {
      _state = _state.copyWith(
        errorMessage: 'Failed to load client allocation candidates: $e',
      );
    }
    notifyListeners();
  }

  void onPaymentSelected(PaymentCandidate payment) {
    _state = _state.copyWith(
      selectedPayment: () => payment,
      amountError: null,
      errorMessage: null,
    );
    _autoFillMaxAmount();
    notifyListeners();
  }

  void onInvoiceSelected(InvoiceCandidate invoice) {
    _state = _state.copyWith(
      selectedInvoice: () => invoice,
      amountError: null,
      errorMessage: null,
    );
    _autoFillMaxAmount();
    notifyListeners();
  }

  void allocateMaximum() {
    _autoFillMaxAmount();
    notifyListeners();
  }

  void _autoFillMaxAmount() {
    final max = _state.maxAllocatableAmount;
    if (max != null && max.isPositive) {
      _state = _state.copyWith(
        amount: () => max,
        amountText: max.format(includeSymbol: false),
      );
    }
  }

  void onAmountChanged(String text) {
    Money? parsed;
    final currency = _state.selectedPayment?.payment.currency ?? Currency.dzd;
    final cleaned = text.trim().replaceAll(',', '.');
    if (cleaned.isNotEmpty) {
      try {
        parsed = Money.fromDecimalString(cleaned, currency);
      } catch (_) {
        parsed = null;
      }
    }

    _state = _state.copyWith(
      amountText: text,
      amount: () => parsed,
      amountError: null,
      errorMessage: null,
    );
    notifyListeners();
  }

  void setAmountToMax() {
    final max = _state.maxAllocatableAmount;
    if (max != null) {
      _state = _state.copyWith(
        amount: () => max,
        amountText: max.format(includeSymbol: false),
        amountError: null,
      );
      notifyListeners();
    }
  }

  Future<PaymentAllocation?> submit() async {
    if (_state.isSubmitting) return null;

    if (_state.selectedPayment == null) {
      _state = _state.copyWith(errorMessage: 'Please select a source payment.');
      notifyListeners();
      return null;
    }

    if (_state.selectedInvoice == null) {
      _state = _state.copyWith(errorMessage: 'Please select a target invoice.');
      notifyListeners();
      return null;
    }

    if (_state.amount == null || !_state.amount!.isPositive) {
      _state = _state.copyWith(
        amountError: 'Please enter a valid positive amount.',
      );
      notifyListeners();
      return null;
    }

    if (_state.amount! > _state.selectedPayment!.remainingCapacity) {
      _state = _state.copyWith(
        amountError:
            'Amount exceeds remaining payment capacity (${_state.selectedPayment!.remainingCapacity}).',
      );
      notifyListeners();
      return null;
    }

    if (_state.amount! > _state.selectedInvoice!.remainingBalance) {
      _state = _state.copyWith(
        amountError:
            'Amount exceeds remaining invoice balance (${_state.selectedInvoice!.remainingBalance}).',
      );
      notifyListeners();
      return null;
    }

    _state = _state.copyWith(
      status: AllocationWorkflowStatus.submitting,
      errorMessage: null,
    );
    notifyListeners();

    final result = await allocatePayment.execute(
      AllocatePaymentCommand(
        paymentId: _state.selectedPayment!.payment.id,
        invoiceId: _state.selectedInvoice!.invoice.id,
        amount: _state.amount!,
      ),
    );

    if (result.isSuccess) {
      final saved = result.dataOrNull!;
      _state = _state.copyWith(status: AllocationWorkflowStatus.success);
      notifyListeners();
      return saved;
    } else {
      _state = _state.copyWith(
        status: AllocationWorkflowStatus.error,
        errorMessage: result.failureOrNull?.message ?? 'Allocation failed.',
      );
      notifyListeners();
      return null;
    }
  }
}
