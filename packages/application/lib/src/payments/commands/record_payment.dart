/// Record payment execution.
library;

import 'package:domain/domain.dart';

import '../../common/result.dart';
import '../../repositories/client_repository.dart';
import '../../repositories/payment_repository.dart';
import 'record_payment_command.dart';

final class RecordPayment {
  const RecordPayment({
    required this.clientRepository,
    required this.paymentRepository,
  });

  final ClientRepository clientRepository;
  final PaymentRepository paymentRepository;

  /// Executes payment recording and persistence.
  Future<Result<Payment>> execute(RecordPaymentCommand command) async {
    try {
      // 1. Verify that the referenced client exists.
      final clientExists = await clientRepository.existsById(command.clientId);
      if (!clientExists) {
        return Result.failure(
          NotFoundFailure(
            message: 'Client with ID ${command.clientId} does not exist.',
            entityType: 'Client',
            entityId: command.clientId,
          ),
        );
      }

      // 2. If ID is provided, check for existing payment with this ID (idempotency or collision).
      if (command.id != null) {
        final existing = await paymentRepository.getById(command.id!);
        if (existing != null) {
          final normalizedNotes = ValidationUtils.normalizeOptionalString(
            command.notes,
          );
          final isMatch =
              existing.clientId == command.clientId &&
              existing.amount == command.amount &&
              existing.notes == normalizedNotes &&
              (command.receivedAt == null ||
                  existing.receivedAt == command.receivedAt);

          if (isMatch) {
            // Idempotent retry: exact same payment data replayed with the same ID.
            return Result.success(existing);
          } else {
            // ID collision: existing record with differing data.
            return Result.failure(
              ConflictFailure(
                message:
                    'Payment with ID ${command.id} already exists with differing data.',
              ),
            );
          }
        }
      }

      // 3. Construct domain aggregate (enforces positive amount).
      final payment = Payment.create(
        id: command.id,
        clientId: command.clientId,
        amount: command.amount,
        receivedAt: command.receivedAt,
        notes: command.notes,
        createdAt: command.createdAt,
      );

      // 4. Persist to repository.
      await paymentRepository.add(payment);
      return Result.success(payment);
    } on ArgumentError catch (e) {
      return Result.failure(
        ValidationFailure(
          message: e.message?.toString() ?? 'Invalid payment data.',
          cause: e,
        ),
      );
    } catch (e) {
      return Result.failure(
        RepositoryFailure(message: 'Failed to record payment: $e', cause: e),
      );
    }
  }
}
