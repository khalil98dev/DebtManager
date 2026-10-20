import 'package:application/application.dart';
import 'package:domain/domain.dart';
import 'package:flutter/foundation.dart';

import 'client_detail_state.dart';

/// ViewModel orchestrating client profile details, financial position, and associated records.
class ClientDetailViewModel extends ChangeNotifier {
  ClientDetailViewModel({
    required this.clientId,
    required this.clientRepository,
    required this.invoiceRepository,
    required this.paymentRepository,
    required this.paymentAllocationRepository,
    required this.getClientFinancialPosition,
  });

  final ClientId clientId;
  final ClientRepository clientRepository;
  final InvoiceRepository invoiceRepository;
  final PaymentRepository paymentRepository;
  final PaymentAllocationRepository paymentAllocationRepository;
  final GetClientFinancialPosition getClientFinancialPosition;

  ClientDetailState _state = const ClientDetailState();
  ClientDetailState get state => _state;

  Future<void> loadDetails() async {
    _state = _state.copyWith(
      status: ClientDetailStatus.loading,
      errorMessage: null,
    );
    notifyListeners();

    try {
      final client = await clientRepository.getById(clientId);
      if (client == null) {
        _state = _state.copyWith(
          status: ClientDetailStatus.error,
          errorMessage: 'Client not found.',
        );
        notifyListeners();
        return;
      }

      final invoices = await invoiceRepository.getByClientId(clientId);
      final payments = await paymentRepository.getByClientId(clientId);
      final allocations = await paymentAllocationRepository.getByClientId(
        clientId,
      );

      final positionResult = await getClientFinancialPosition.execute(
        GetClientFinancialPositionQuery(clientId: clientId),
      );

      _state = _state.copyWith(
        status: ClientDetailStatus.loaded,
        client: client,
        position: positionResult.dataOrNull,
        invoices: invoices,
        payments: payments,
        allocations: allocations,
      );
    } catch (e) {
      _state = _state.copyWith(
        status: ClientDetailStatus.error,
        errorMessage: 'Failed to load client details: $e',
      );
    }
    notifyListeners();
  }

  Future<bool> deleteClient() async {
    try {
      await clientRepository.deleteById(clientId);
      return true;
    } catch (e) {
      _state = _state.copyWith(
        errorMessage: 'Cannot delete client with existing financial records.',
      );
      notifyListeners();
      return false;
    }
  }

  Future<void> refresh() => loadDetails();
}
