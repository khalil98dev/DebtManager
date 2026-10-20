/// Get invoice by ID execution.
library;

import 'package:domain/domain.dart';

import '../../common/result.dart';
import '../../repositories/invoice_repository.dart';
import 'get_invoice_by_id_query.dart';

/// Orchestrates retrieving a single [Invoice] by its unique [InvoiceId].
final class GetInvoiceById {
  const GetInvoiceById(this._invoiceRepository);

  final InvoiceRepository _invoiceRepository;

  /// Executes the invoice retrieval query.
  Future<Result<Invoice>> execute(GetInvoiceByIdQuery query) async {
    try {
      final invoice = await _invoiceRepository.getById(query.id);
      if (invoice == null) {
        return Result.failure(
          NotFoundFailure(
            message: 'Invoice with ID ${query.id} was not found.',
            entityType: 'Invoice',
            entityId: query.id,
          ),
        );
      }
      return Result.success(invoice);
    } catch (e) {
      return Result.failure(
        RepositoryFailure(message: 'Failed to retrieve invoice: $e', cause: e),
      );
    }
  }
}
