import 'package:application/application.dart';
import 'package:domain/domain.dart';
import 'package:flutter/foundation.dart';

import 'payment_form_state.dart';

/// ViewModel managing recording a received payment from a client.
class PaymentFormViewModel extends ChangeNotifier {
  PaymentFormViewModel({
    required this.clientRepository,
    required this.recordPayment,
    ClientId? preselectedClientId,
  }) {
    _state = PaymentFormState(receivedAt: DateTime.now());
    _preselectedClientId = preselectedClientId;
  }

  final ClientRepository clientRepository;
  final RecordPayment recordPayment;
  ClientId? _preselectedClientId;

  PaymentFormState _state = PaymentFormState(receivedAt: DateTime.now());
  PaymentFormState get state => _state;

  Future<void> initialize() async {
    _state = _state.copyWith(status: PaymentFormStatus.loading);
    notifyListeners();

    try {
      final clients = await clientRepository.getAll();
      Client? selected;
      if (_preselectedClientId != null) {
        selected = clients
            .where((c) => c.id == _preselectedClientId)
            .firstOrNull;
      }

      _state = _state.copyWith(
        status: PaymentFormStatus.initial,
        availableClients: clients,
        selectedClient: () => selected ?? _state.selectedClient,
      );
    } catch (e) {
      _state = _state.copyWith(
        status: PaymentFormStatus.error,
        errorMessage: 'Failed to load clients: $e',
      );
    }
    notifyListeners();
  }

  /// Refreshes the available client list from repository.
  Future<void> refreshClients() async {
    try {
      final clients = await clientRepository.getAll();
      _state = _state.copyWith(availableClients: clients);
      notifyListeners();
    } catch (_) {}
  }

  void onClientSelected(Client client) {
    _state = _state.copyWith(
      selectedClient: () => client,
      clientError: null,
      errorMessage: null,
    );
    notifyListeners();
  }

  void onAmountChanged(String text) {
    Money? parsed;
    final cleaned = text.trim().replaceAll(',', '.');
    if (cleaned.isNotEmpty) {
      try {
        parsed = Money.fromDecimalString(cleaned, _state.currency);
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

  void onReceivedAtChanged(DateTime date) {
    _state = _state.copyWith(receivedAt: date);
    notifyListeners();
  }

  void onNotesChanged(String notes) {
    _state = _state.copyWith(notes: notes, errorMessage: null);
    notifyListeners();
  }

  Future<Payment?> submit() async {
    if (_state.isSubmitting) return null;

    String? clientError;
    if (_state.selectedClient == null) {
      clientError = 'Please select a client.';
    }

    String? amountError;
    if (_state.amount == null || !_state.amount!.isPositive) {
      amountError = 'Please enter a valid positive payment amount.';
    }

    if (clientError != null || amountError != null) {
      _state = _state.copyWith(
        clientError: clientError,
        amountError: amountError,
      );
      notifyListeners();
      return null;
    }

    _state = _state.copyWith(
      status: PaymentFormStatus.submitting,
      errorMessage: null,
    );
    notifyListeners();

    final result = await recordPayment.execute(
      RecordPaymentCommand(
        clientId: _state.selectedClient!.id,
        amount: _state.amount!,
        receivedAt: _state.receivedAt,
        notes: _state.notes.trim().isEmpty ? null : _state.notes.trim(),
      ),
    );

    if (result.isSuccess) {
      final saved = result.dataOrNull!;
      _state = _state.copyWith(status: PaymentFormStatus.success);
      notifyListeners();
      return saved;
    } else {
      _state = _state.copyWith(
        status: PaymentFormStatus.error,
        errorMessage:
            result.failureOrNull?.message ?? 'Failed to record payment.',
      );
      notifyListeners();
      return null;
    }
  }
}
