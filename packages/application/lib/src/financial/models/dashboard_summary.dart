import 'package:domain/domain.dart';
import 'package:meta/meta.dart';

/// Immutable model representing top-level aggregated financial and operational metrics.
@immutable
class DashboardSummary {
  const DashboardSummary({
    required this.totalClients,
    required this.totalDraftInvoices,
    required this.totalIssuedInvoices,
    required this.totalBilled,
    required this.totalAllocatedPayments,
    required this.totalOutstandingDebt,
    required this.totalUnallocatedCredit,
    required this.netPosition,
    required this.recentInvoices,
    required this.recentPayments,
    required this.currency,
  });

  final int totalClients;
  final int totalDraftInvoices;
  final int totalIssuedInvoices;
  final Money totalBilled;
  final Money totalAllocatedPayments;
  final Money totalOutstandingDebt;
  final Money totalUnallocatedCredit;
  final Money netPosition;
  final List<Invoice> recentInvoices;
  final List<Payment> recentPayments;
  final Currency currency;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DashboardSummary &&
          other.totalClients == totalClients &&
          other.totalDraftInvoices == totalDraftInvoices &&
          other.totalIssuedInvoices == totalIssuedInvoices &&
          other.totalBilled == totalBilled &&
          other.totalAllocatedPayments == totalAllocatedPayments &&
          other.totalOutstandingDebt == totalOutstandingDebt &&
          other.totalUnallocatedCredit == totalUnallocatedCredit &&
          other.netPosition == netPosition &&
          other.currency == currency;

  @override
  int get hashCode => Object.hash(
    totalClients,
    totalDraftInvoices,
    totalIssuedInvoices,
    totalBilled,
    totalAllocatedPayments,
    totalOutstandingDebt,
    totalUnallocatedCredit,
    netPosition,
    currency,
  );
}
