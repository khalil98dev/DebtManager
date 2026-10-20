/// Get payment allocation by ID execution.
library;

import 'package:domain/domain.dart';

import '../../common/result.dart';
import '../../repositories/payment_allocation_repository.dart';
import 'get_payment_allocation_by_id_query.dart';

/// Orchestrates retrieving a single [PaymentAllocation] by its unique [PaymentAllocationId].
final class GetPaymentAllocationById {
  const GetPaymentAllocationById(this._paymentAllocationRepository);

  final PaymentAllocationRepository _paymentAllocationRepository;

  /// Executes the payment allocation retrieval query.
  Future<Result<PaymentAllocation>> execute(
    GetPaymentAllocationByIdQuery query,
  ) async {
    try {
      final allocation = await _paymentAllocationRepository.getById(query.id);
      if (allocation == null) {
        return Result.failure(
          NotFoundFailure(
            message: 'Payment allocation with ID ${query.id} was not found.',
            entityType: 'PaymentAllocation',
            entityId: query.id,
          ),
        );
      }
      return Result.success(allocation);
    } catch (e) {
      return Result.failure(
        RepositoryFailure(
          message: 'Failed to retrieve payment allocation: $e',
          cause: e,
        ),
      );
    }
  }
}
