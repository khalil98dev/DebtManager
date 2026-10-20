/// Get payment by ID execution.
library;

import 'package:domain/domain.dart';

import '../../common/result.dart';
import '../../repositories/payment_repository.dart';
import 'get_payment_by_id_query.dart';

/// Orchestrates retrieving a single [Payment] by its unique [PaymentId].
final class GetPaymentById {
  const GetPaymentById(this._paymentRepository);

  final PaymentRepository _paymentRepository;

  /// Executes the payment retrieval query.
  Future<Result<Payment>> execute(GetPaymentByIdQuery query) async {
    try {
      final payment = await _paymentRepository.getById(query.id);
      if (payment == null) {
        return Result.failure(
          NotFoundFailure(
            message: 'Payment with ID ${query.id} was not found.',
            entityType: 'Payment',
            entityId: query.id,
          ),
        );
      }
      return Result.success(payment);
    } catch (e) {
      return Result.failure(
        RepositoryFailure(message: 'Failed to retrieve payment: $e', cause: e),
      );
    }
  }
}
