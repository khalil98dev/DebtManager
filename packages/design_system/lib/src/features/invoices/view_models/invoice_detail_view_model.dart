import 'package:application/application.dart';
import 'package:domain/domain.dart';
import 'package:flutter/foundation.dart';

import 'invoice_detail_state.dart';

/// ViewModel orchestrating invoice view, allocations display, issuance, and deletion.
class InvoiceDetailViewModel extends ChangeNotifier {
  InvoiceDetailViewModel({
    required this.invoiceId,
    required this.invoiceRepository,
    required this.clientRepository,
    required this.paymentAllocationRepository,
    required this.issueInvoice,
  });

  final InvoiceId invoiceId;
  final InvoiceRepository invoiceRepository;
  final ClientRepository clientRepository;
  final PaymentAllocationRepository paymentAllocationRepository;
  final IssueInvoice issueInvoice;

  InvoiceDetailState _state = const InvoiceDetailState();
  InvoiceDetailState get state => _state;

  Future<void> loadDetails() async {
    _state = _state.copyWith(
      status: InvoiceDetailStatus.loading,
      errorMessage: null,
    );
    notifyListeners();

    try {
      final invoice = await invoiceRepository.getById(invoiceId);
      if (invoice == null) {
        _state = _state.copyWith(
          status: InvoiceDetailStatus.error,
          errorMessage: 'Invoice not found.',
        );
        notifyListeners();
        return;
      }

      final client = await clientRepository.getById(invoice.clientId);
      final allocations = await paymentAllocationRepository.getByInvoiceId(
        invoiceId,
      );

      _state = _state.copyWith(
        status: InvoiceDetailStatus.loaded,
        invoice: invoice,
        client: client,
        allocations: allocations,
      );
    } catch (e) {
      _state = _state.copyWith(
        status: InvoiceDetailStatus.error,
        errorMessage: 'Failed to load invoice: $e',
      );
    }
    notifyListeners();
  }

  Future<bool> issue() async {
    if (_state.isMutating) return false;

    _state = _state.copyWith(
      status: InvoiceDetailStatus.mutating,
      errorMessage: null,
    );
    notifyListeners();

    final result = await issueInvoice.execute(
      IssueInvoiceCommand(invoiceId: invoiceId),
    );

    if (result.isSuccess) {
      final updated = result.dataOrNull!;
      _state = _state.copyWith(
        status: InvoiceDetailStatus.loaded,
        invoice: updated,
      );
      notifyListeners();
      return true;
    } else {
      _state = _state.copyWith(
        status: InvoiceDetailStatus.loaded,
        errorMessage:
            result.failureOrNull?.message ?? 'Failed to issue invoice.',
      );
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteDraft() async {
    if (_state.isMutating) return false;

    _state = _state.copyWith(
      status: InvoiceDetailStatus.mutating,
      errorMessage: null,
    );
    notifyListeners();

    try {
      await invoiceRepository.deleteById(invoiceId);
      return true;
    } catch (e) {
      _state = _state.copyWith(
        status: InvoiceDetailStatus.loaded,
        errorMessage: 'Failed to delete draft invoice: $e',
      );
      notifyListeners();
      return false;
    }
  }

  Future<void> refresh() => loadDetails();
}
