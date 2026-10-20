/// Create draft invoice execution.
library;

import 'package:domain/domain.dart';

import '../../common/result.dart';
import '../../repositories/client_repository.dart';
import '../../repositories/invoice_repository.dart';
import 'create_invoice_command.dart';

final class CreateInvoice {
  const CreateInvoice({
    required this.clientRepository,
    required this.invoiceRepository,
  });

  final ClientRepository clientRepository;
  final InvoiceRepository invoiceRepository;

  Future<Result<Invoice>> execute(CreateInvoiceCommand command) async {
    try {
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

      // 2. If ID is provided, check for existing invoice with this ID (idempotency or collision).
      if (command.id != null) {
        final existing = await invoiceRepository.getById(command.id!);
        if (existing != null) {
          final trimmedNumber = command.number.trim();
          final normalizedNotes = ValidationUtils.normalizeOptionalString(
            command.notes,
          );
          final commandLines = command.lines.toList(growable: false);

          bool linesMatch = existing.lines.length == commandLines.length;
          if (linesMatch) {
            for (var i = 0; i < commandLines.length; i++) {
              final a = existing.lines[i];
              final b = commandLines[i];
              if (a.description != b.description ||
                  a.quantity != b.quantity ||
                  a.unitPrice != b.unitPrice) {
                linesMatch = false;
                break;
              }
            }
          }

          final isMatch =
              existing.clientId == command.clientId &&
              existing.number == trimmedNumber &&
              existing.notes == normalizedNotes &&
              linesMatch &&
              (command.currency == null ||
                  existing.currency == command.currency);

          if (isMatch) {
            // Idempotent retry: exact same invoice data replayed with the same ID.
            return Result.success(existing);
          } else {
            // ID collision: existing record with differing data.
            return Result.failure(
              ConflictFailure(
                message:
                    'Invoice with ID ${command.id} already exists with differing data.',
              ),
            );
          }
        }
      }

      // 3. Check for unique invoice number across all invoices.
      final trimmedNumber = command.number.trim();
      if (trimmedNumber.isNotEmpty) {
        final existingByNumber = await invoiceRepository.getByNumber(
          trimmedNumber,
        );
        if (existingByNumber != null) {
          if (command.id == null || existingByNumber.id != command.id) {
            return Result.failure(
              ConflictFailure(
                message:
                    "An invoice with number '$trimmedNumber' already exists.",
              ),
            );
          }
        }
      }

      // 4. Create draft invoice (domain aggregate enforces lines, currency, and number invariants).
      final invoice = Invoice.draft(
        id: command.id,
        clientId: command.clientId,
        number: command.number,
        lines: command.lines,
        notes: command.notes,
        currency: command.currency,
        createdAt: command.createdAt,
      );

      // 5. Persist to repository.
      await invoiceRepository.add(invoice);
      return Result.success(invoice);
    } on CurrencyMismatchException catch (e) {
      return Result.failure(ValidationFailure(message: e.message, cause: e));
    } on ArgumentError catch (e) {
      return Result.failure(
        ValidationFailure(
          message: e.message?.toString() ?? 'Invalid invoice data.',
          cause: e,
        ),
      );
    } catch (e) {
      return Result.failure(
        RepositoryFailure(message: 'Failed to create invoice: $e', cause: e),
      );
    }
  }
}
