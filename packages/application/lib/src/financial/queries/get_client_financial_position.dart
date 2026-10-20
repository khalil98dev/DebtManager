/// Get client financial position execution.
library;

import 'package:domain/domain.dart';

import '../../common/result.dart';
import '../../repositories/client_repository.dart';
import '../../repositories/invoice_repository.dart';
import '../../repositories/payment_allocation_repository.dart';
import '../../repositories/payment_repository.dart';
import 'get_client_financial_position_query.dart';

/// Orchestrates retrieving a client's invoices, payments, and allocations
/// and computing their deterministic [ClientFinancialPosition].
final class GetClientFinancialPosition {
  const GetClientFinancialPosition({
    required this.clientRepository,
    required this.invoiceRepository,
    required this.paymentRepository,
    required this.paymentAllocationRepository,
  });

  final ClientRepository clientRepository;
  final InvoiceRepository invoiceRepository;
  final PaymentRepository paymentRepository;
  final PaymentAllocationRepository paymentAllocationRepository;

  /// Executes the financial position calculation query.
  Future<Result<ClientFinancialPosition>> execute(
    GetClientFinancialPositionQuery query,
  ) async {
    try {
      final clientExists = await clientRepository.existsById(query.clientId);
      if (!clientExists) {
        return Result.failure(
          NotFoundFailure(
            message: 'Client with ID ${query.clientId} does not exist.',
            entityType: 'Client',
            entityId: query.clientId,
          ),
        );
      }

      final invoices = await invoiceRepository.getByClientId(query.clientId);
      final payments = await paymentRepository.getByClientId(query.clientId);
      final allocations = await paymentAllocationRepository.getByClientId(
        query.clientId,
      );

      final position = ClientFinancialCalculator.calculate(
        clientId: query.clientId,
        invoices: invoices,
        payments: payments,
        allocations: allocations,
        currency: query.currency,
      );

      return Result.success(position);
    } on CurrencyMismatchException catch (e) {
      return Result.failure(
        ValidationFailure(
          message:
              'Client has records with mismatched currencies: ${e.message}',
          cause: e,
        ),
      );
    } on ArgumentError catch (e) {
      return Result.failure(
        ValidationFailure(
          message:
              e.message?.toString() ?? 'Invalid financial calculation data.',
          cause: e,
        ),
      );
    } catch (e) {
      return Result.failure(
        RepositoryFailure(
          message: 'Failed to compute client financial position: $e',
          cause: e,
        ),
      );
    }
  }
}
