import 'package:domain/domain.dart';

import '../../common/result.dart';
import '../../repositories/client_repository.dart';
import '../../repositories/invoice_repository.dart';
import 'update_invoice_draft_command.dart';

/// Orchestrates updating an existing draft [Invoice].
final class UpdateInvoiceDraft {
  const UpdateInvoiceDraft({
    required this.clientRepository,
    required this.invoiceRepository,
  });

  final ClientRepository clientRepository;
  final InvoiceRepository invoiceRepository;

  Future<Result<Invoice>> execute(UpdateInvoiceDraftCommand command) async {
    try {
      final existing = await invoiceRepository.getById(command.id);
      if (existing == null) {
        return Result.failure(
          NotFoundFailure(
            message: 'Invoice with ID ${command.id} does not exist.',
            entityType: 'Invoice',
            entityId: command.id,
          ),
        );
      }

      if (!existing.isDraft) {
        return Result.failure(
          ConflictFailure(
            message:
                'Cannot modify invoice ${command.id} because it has already been issued. Issued invoices are immutable.',
          ),
        );
      }

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

      // Check unique number if changed
      final trimmedNumber = command.number.trim();
      if (trimmedNumber.isNotEmpty && trimmedNumber != existing.number) {
        final existingByNumber = await invoiceRepository.getByNumber(
          trimmedNumber,
        );
        if (existingByNumber != null && existingByNumber.id != command.id) {
          return Result.failure(
            ConflictFailure(
              message:
                  "An invoice with number '$trimmedNumber' already exists.",
            ),
          );
        }
      }

      final updated = Invoice.draft(
        id: command.id,
        clientId: command.clientId,
        number: command.number,
        lines: command.lines,
        notes: command.notes,
        currency: command.currency ?? existing.currency,
        createdAt: existing.createdAt,
      );

      await invoiceRepository.add(updated);
      return Result.success(updated);
    } on CurrencyMismatchException catch (e) {
      return Result.failure(ValidationFailure(message: e.message, cause: e));
    } on ArgumentError catch (e) {
      return Result.failure(
        ValidationFailure(
          message: e.message?.toString() ?? 'Invalid invoice update data.',
          cause: e,
        ),
      );
    } catch (e) {
      return Result.failure(
        RepositoryFailure(
          message: 'Failed to update draft invoice: $e',
          cause: e,
        ),
      );
    }
  }
}
