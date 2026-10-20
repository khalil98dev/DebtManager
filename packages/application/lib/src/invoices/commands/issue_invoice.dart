/// Issue invoice execution.
library;

import 'package:domain/domain.dart';

import '../../common/result.dart';
import '../../repositories/invoice_repository.dart';
import 'issue_invoice_command.dart';

/// Orchestrates finalizing and issuing a draft [Invoice].
final class IssueInvoice {
  const IssueInvoice(this._invoiceRepository);

  final InvoiceRepository _invoiceRepository;

  /// Executes invoice issuance.
  Future<Result<Invoice>> execute(IssueInvoiceCommand command) async {
    try {
      final invoice = await _invoiceRepository.getById(command.invoiceId);
      if (invoice == null) {
        return Result.failure(
          NotFoundFailure(
            message: 'Invoice with ID ${command.invoiceId} does not exist.',
            entityType: 'Invoice',
            entityId: command.invoiceId,
          ),
        );
      }

      if (invoice.isIssued) {
        return Result.failure(
          ConflictFailure(
            message: 'Invoice ${command.invoiceId} is already issued.',
          ),
        );
      }

      // Domain invariant check: draft must contain at least one line item and valid timestamp.
      final issuedInvoice = invoice.issue(issuedAt: command.issuedAt);

      await _invoiceRepository.add(issuedInvoice);
      return Result.success(issuedInvoice);
    } on StateError catch (e) {
      return Result.failure(ValidationFailure(message: e.message, cause: e));
    } on ArgumentError catch (e) {
      return Result.failure(
        ValidationFailure(
          message: e.message?.toString() ?? 'Invalid issue parameters.',
          cause: e,
        ),
      );
    } catch (e) {
      return Result.failure(
        RepositoryFailure(message: 'Failed to issue invoice: $e', cause: e),
      );
    }
  }
}
