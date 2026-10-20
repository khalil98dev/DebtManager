import 'package:domain/domain.dart';

import '../../common/result.dart';
import '../../repositories/client_repository.dart';
import '../../repositories/invoice_repository.dart';
import '../../repositories/payment_allocation_repository.dart';
import '../../repositories/payment_repository.dart';
import '../models/dashboard_summary.dart';
import 'get_dashboard_summary_query.dart';

/// Orchestrates calculating the global operational and financial summary for the dashboard.
final class GetDashboardSummary {
  const GetDashboardSummary({
    required this.clientRepository,
    required this.invoiceRepository,
    required this.paymentRepository,
    required this.paymentAllocationRepository,
  });

  final ClientRepository clientRepository;
  final InvoiceRepository invoiceRepository;
  final PaymentRepository paymentRepository;
  final PaymentAllocationRepository paymentAllocationRepository;

  Future<Result<DashboardSummary>> execute(
    GetDashboardSummaryQuery query,
  ) async {
    try {
      final clients = await clientRepository.getAll();
      final invoices = await invoiceRepository.getAll();
      final payments = await paymentRepository.getAll();
      final allocations = await paymentAllocationRepository.getAll();

      final currency = query.currency ?? Currency.dzd;

      final draftInvoices = invoices.where((i) => i.isDraft).toList();
      final issuedInvoices = invoices.where((i) => i.isIssued).toList();

      var totalBilled = Money.zero(currency);
      for (final inv in issuedInvoices) {
        if (inv.currency == currency) {
          totalBilled += inv.total;
        }
      }

      var totalPayments = Money.zero(currency);
      for (final p in payments) {
        if (p.currency == currency) {
          totalPayments += p.amount;
        }
      }

      var totalAllocated = Money.zero(currency);
      for (final a in allocations) {
        if (a.currency == currency) {
          totalAllocated += a.amount;
        }
      }

      final outstandingDebt = totalBilled - totalAllocated;
      final unallocatedCredit = totalPayments - totalAllocated;
      final netPosition = outstandingDebt - unallocatedCredit;

      // Sort recent records
      final sortedInvoices = List<Invoice>.from(invoices)
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      final recentInvoices = sortedInvoices.take(5).toList(growable: false);

      final sortedPayments = List<Payment>.from(payments)
        ..sort((a, b) => b.receivedAt.compareTo(a.receivedAt));
      final recentPayments = sortedPayments.take(5).toList(growable: false);

      return Result.success(
        DashboardSummary(
          totalClients: clients.length,
          totalDraftInvoices: draftInvoices.length,
          totalIssuedInvoices: issuedInvoices.length,
          totalBilled: totalBilled,
          totalAllocatedPayments: totalAllocated,
          totalOutstandingDebt: outstandingDebt,
          totalUnallocatedCredit: unallocatedCredit,
          netPosition: netPosition,
          recentInvoices: recentInvoices,
          recentPayments: recentPayments,
          currency: currency,
        ),
      );
    } catch (e) {
      return Result.failure(
        RepositoryFailure(
          message: 'Failed to compute dashboard summary: $e',
          cause: e,
        ),
      );
    }
  }
}
