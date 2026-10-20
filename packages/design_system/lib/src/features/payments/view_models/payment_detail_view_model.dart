import 'package:application/application.dart';
import 'package:domain/domain.dart';
import 'package:flutter/foundation.dart';

import 'payment_detail_state.dart';

/// ViewModel orchestrating single payment inspection, allocations history, and remaining funds.
class PaymentDetailViewModel extends ChangeNotifier {
  PaymentDetailViewModel({
    required this.paymentId,
    required this.paymentRepository,
    required this.clientRepository,
    required this.paymentAllocationRepository,
  });

  final PaymentId paymentId;
  final PaymentRepository paymentRepository;
  final ClientRepository clientRepository;
  final PaymentAllocationRepository paymentAllocationRepository;

  PaymentDetailState _state = const PaymentDetailState();
  PaymentDetailState get state => _state;

  Future<void> loadDetails() async {
    _state = _state.copyWith(
      status: PaymentDetailStatus.loading,
      errorMessage: null,
    );
    notifyListeners();

    try {
      final payment = await paymentRepository.getById(paymentId);
      if (payment == null) {
        _state = _state.copyWith(
          status: PaymentDetailStatus.error,
          errorMessage: 'Payment not found.',
        );
        notifyListeners();
        return;
      }

      final client = await clientRepository.getById(payment.clientId);
      final allocations = await paymentAllocationRepository.getByPaymentId(
        paymentId,
      );

      _state = _state.copyWith(
        status: PaymentDetailStatus.loaded,
        payment: payment,
        client: client,
        allocations: allocations,
      );
    } catch (e) {
      _state = _state.copyWith(
        status: PaymentDetailStatus.error,
        errorMessage: 'Failed to load payment: $e',
      );
    }
    notifyListeners();
  }

  Future<void> refresh() => loadDetails();
}
