/// Allocate payment execution.
library;

import 'package:domain/domain.dart';

import '../../common/result.dart';
import '../../repositories/unit_of_work.dart';
import 'allocate_payment_command.dart';

/// Coordinates allocating funds from a [Payment] to an [Invoice].
///
/// Executes atomically within a unit-of-work persistence boundary.
///
/// Supports offline-first creation:
/// - If [AllocatePaymentCommand.id] is omitted, generates a new stable [PaymentAllocationId].
/// - If [AllocatePaymentCommand.id] is supplied, verifies whether an allocation with that ID exists:
///   - If matching existing data is found, handles as an idempotent retry.
///   - If differing existing data is found, returns a [ConflictFailure].
final class AllocatePayment {
  const AllocatePayment(this._unitOfWork);

  final UnitOfWork _unitOfWork;

  /// Executes payment allocation within a transactional boundary.
  Future<Result<PaymentAllocation>> execute(
    AllocatePaymentCommand command,
  ) async {
    try {
      return await _unitOfWork.saveChangesAsync((scope) async {
        // 1. If ID is provided, check for existing allocation with this ID (idempotency or collision).
        if (command.id != null) {
          final existing = await scope.paymentAllocations.getById(command.id!);
          if (existing != null) {
            final isMatch =
                existing.paymentId == command.paymentId &&
                existing.invoiceId == command.invoiceId &&
                existing.amount == command.amount;

            if (isMatch) {
              // Idempotent retry: exact same allocation data replayed with the same ID.
              return Result.success(existing);
            } else {
              // ID collision: existing record with differing data.
              return Result.failure(
                ConflictFailure(
                  message:
                      'Payment allocation with ID ${command.id} already exists with differing data.',
                ),
              );
            }
          }
        }

        // 2. Validate amount invariant.
        if (!command.amount.isPositive) {
          return Result.failure(
            ValidationFailure(
              message: 'Allocation amount must be strictly positive (> 0).',
            ),
          );
        }

        // 3. Verify payment existence.
        final payment = await scope.payments.getById(command.paymentId);
        if (payment == null) {
          return Result.failure(
            NotFoundFailure(
              message: 'Payment with ID ${command.paymentId} does not exist.',
              entityType: 'Payment',
              entityId: command.paymentId,
            ),
          );
        }

        // 4. Verify invoice existence.
        final invoice = await scope.invoices.getById(command.invoiceId);
        if (invoice == null) {
          return Result.failure(
            NotFoundFailure(
              message: 'Invoice with ID ${command.invoiceId} does not exist.',
              entityType: 'Invoice',
              entityId: command.invoiceId,
            ),
          );
        }

        // 5. Validate client ownership.
        if (payment.clientId != invoice.clientId) {
          return Result.failure(
            ValidationFailure(
              message:
                  'Cross-client allocation violation: Payment belongs to '
                  'client ${payment.clientId}, but invoice belongs to client ${invoice.clientId}.',
            ),
          );
        }

        // 6. Validate invoice status (only issued invoices can receive allocations).
        if (!invoice.isIssued) {
          return Result.failure(
            ValidationFailure(
              message:
                  'Cannot allocate payment to draft invoice ${invoice.id}. '
                  'Only issued invoices can receive allocations.',
            ),
          );
        }

        // 7. Validate currency compatibility.
        if (command.amount.currency != payment.currency) {
          return Result.failure(
            ValidationFailure(
              message:
                  'Currency mismatch: Allocation currency (${command.amount.currency.code}) '
                  'does not match payment currency (${payment.currency.code}).',
            ),
          );
        }
        if (command.amount.currency != invoice.currency) {
          return Result.failure(
            ValidationFailure(
              message:
                  'Currency mismatch: Allocation currency (${command.amount.currency.code}) '
                  'does not match invoice currency (${invoice.currency.code}).',
            ),
          );
        }

        // 8. Check for duplicate active allocation between this payment and invoice.
        final existingPairAllocation = await scope.paymentAllocations
            .getByPaymentAndInvoice(command.paymentId, command.invoiceId);
        if (existingPairAllocation != null) {
          return Result.failure(
            ConflictFailure(
              message:
                  'An active allocation already exists between payment '
                  '${command.paymentId} and invoice ${command.invoiceId}.',
            ),
          );
        }

        // 9. Validate payment remaining unallocated capacity.
        final paymentAllocations = await scope.paymentAllocations
            .getByPaymentId(command.paymentId);
        final totalAllocatedFromPayment = paymentAllocations.fold<Money>(
          Money.zero(payment.currency),
          (sum, a) => sum + a.amount,
        );
        final remainingPaymentCapacity =
            payment.amount - totalAllocatedFromPayment;
        if (command.amount > remainingPaymentCapacity) {
          return Result.failure(
            ValidationFailure(
              message:
                  'Payment capacity exceeded: Remaining unallocated capacity is '
                  '$remainingPaymentCapacity, but requested allocation is ${command.amount}.',
            ),
          );
        }

        // 10. Validate invoice remaining unpaid balance.
        final invoiceAllocations = await scope.paymentAllocations
            .getByInvoiceId(command.invoiceId);
        final totalAllocatedToInvoice = invoiceAllocations.fold<Money>(
          Money.zero(invoice.currency),
          (sum, a) => sum + a.amount,
        );
        final remainingInvoiceBalance = invoice.total - totalAllocatedToInvoice;
        if (command.amount > remainingInvoiceBalance) {
          return Result.failure(
            ValidationFailure(
              message:
                  'Invoice balance exceeded: Remaining unpaid balance is '
                  '$remainingInvoiceBalance, but requested allocation is ${command.amount}.',
            ),
          );
        }

        // 11. Construct domain entity and save atomically within transaction scope.
        final allocation = PaymentAllocation.create(
          id: command.id,
          paymentId: command.paymentId,
          invoiceId: command.invoiceId,
          amount: command.amount,
          createdAt: command.createdAt,
        );

        await scope.paymentAllocations.add(allocation);
        return Result.success(allocation);
      });
    } on ArgumentError catch (e) {
      return Result.failure(
        ValidationFailure(
          message: e.message?.toString() ?? 'Invalid allocation parameters.',
          cause: e,
        ),
      );
    } catch (e) {
      return Result.failure(
        RepositoryFailure(message: 'Failed to allocate payment: $e', cause: e),
      );
    }
  }
}
