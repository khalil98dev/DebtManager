import '../clients/client_id.dart';
import '../invoices/invoice.dart';
import '../payments/payment.dart';
import '../payments/payment_allocation.dart';
import '../value_objects/money.dart';
import 'client_financial_position.dart';

/// A deterministic domain calculation service that computes the [ClientFinancialPosition]
/// for a client from supplied domain records without external dependencies.
abstract final class ClientFinancialCalculator {
  /// Computes the [ClientFinancialPosition] for [clientId] across the provided
  /// [invoices], [payments], and [allocations].
  ///
  /// ### Domain Rules & Invariants:
  /// 1. **Issued Invoices Only**: Only issued invoices ([Invoice.isIssued]) are
  ///    included in debt calculations. Drafts are excluded from billed totals.
  /// 2. **Client Isolation**: Only invoices and payments belonging to [clientId]
  ///    are computed into the client's financial position.
  /// 3. **Cross-Aggregate Consistency**:
  ///    - Every allocation must reference a payment and an invoice present in the
  ///      supplied collections.
  ///    - The referenced payment and invoice must belong to the exact same client.
  ///    - Allocations cannot reference draft invoices.
  ///    - An allocation's currency must match both the payment and invoice currencies.
  /// 4. **No Over-Allocation**:
  ///    - Total allocations funded by a payment cannot exceed the payment's [amount].
  ///    - Total allocations applied to an invoice cannot exceed the invoice's [total].
  /// 5. **No Duplicate Allocations**: Duplicate allocation IDs and duplicate active
  ///    allocations between the same payment-invoice pair are rejected with [ArgumentError].
  /// 6. **Single Currency per Position**: All records for the calculated client must share
  ///    the same currency, throwing [CurrencyMismatchException] if mixed.
  static ClientFinancialPosition calculate({
    required ClientId clientId,
    Iterable<Invoice> invoices = const [],
    Iterable<Payment> payments = const [],
    Iterable<PaymentAllocation> allocations = const [],
    Currency? currency,
  }) {
    final invoiceList = List<Invoice>.unmodifiable(invoices);
    final paymentList = List<Payment>.unmodifiable(payments);
    final allocationList = List<PaymentAllocation>.unmodifiable(allocations);

    final paymentMap = {for (final p in paymentList) p.id: p};
    final invoiceMap = {for (final i in invoiceList) i.id: i};

    final seenAllocationIds = <PaymentAllocationId>{};
    final seenPairs = <(PaymentId, InvoiceId)>{};
    final allocationsByPayment = <PaymentId, List<PaymentAllocation>>{};
    final allocationsByInvoice = <InvoiceId, List<PaymentAllocation>>{};

    // Validate every supplied allocation
    for (final alloc in allocationList) {
      if (!seenAllocationIds.add(alloc.id)) {
        throw ArgumentError.value(
          alloc.id,
          'allocations',
          'Duplicate allocation ID found: ${alloc.id}.',
        );
      }

      final payment = paymentMap[alloc.paymentId];
      if (payment == null) {
        throw ArgumentError.value(
          alloc.paymentId,
          'allocations',
          'Allocation ${alloc.id} references non-existent payment ${alloc.paymentId}.',
        );
      }

      final invoice = invoiceMap[alloc.invoiceId];
      if (invoice == null) {
        throw ArgumentError.value(
          alloc.invoiceId,
          'allocations',
          'Allocation ${alloc.id} references non-existent invoice ${alloc.invoiceId}.',
        );
      }

      if (payment.clientId != invoice.clientId) {
        throw ArgumentError(
          'Cross-client allocation violation: Payment ${payment.id} belongs to '
          'client ${payment.clientId}, but invoice ${invoice.id} belongs to client ${invoice.clientId}.',
        );
      }

      final pair = (alloc.paymentId, alloc.invoiceId);
      if (!seenPairs.add(pair)) {
        throw ArgumentError(
          'Duplicate active allocation found for payment ${alloc.paymentId} and invoice ${alloc.invoiceId}.',
        );
      }

      if (!invoice.isIssued) {
        throw ArgumentError(
          'Allocation ${alloc.id} cannot reference draft invoice ${invoice.id}. '
          'Only issued invoices can receive allocations.',
        );
      }

      if (alloc.currency != payment.currency) {
        throw CurrencyMismatchException(
          payment.currency.code,
          alloc.currency.code,
        );
      }

      if (alloc.currency != invoice.currency) {
        throw CurrencyMismatchException(
          invoice.currency.code,
          alloc.currency.code,
        );
      }

      allocationsByPayment.putIfAbsent(alloc.paymentId, () => []).add(alloc);
      allocationsByInvoice.putIfAbsent(alloc.invoiceId, () => []).add(alloc);
    }

    // Verify payment capacity limits (no over-allocation of payments)
    for (final entry in allocationsByPayment.entries) {
      final payment = paymentMap[entry.key]!;
      var totalAllocated = Money.zero(payment.currency);
      for (final a in entry.value) {
        totalAllocated += a.amount;
      }
      if (totalAllocated > payment.amount) {
        throw ArgumentError(
          'Payment ${payment.id} is over-allocated: total allocated ($totalAllocated) '
          'exceeds payment amount (${payment.amount}).',
        );
      }
    }

    // Verify invoice balance limits (no over-allocation of invoices)
    for (final entry in allocationsByInvoice.entries) {
      final invoice = invoiceMap[entry.key]!;
      var totalAllocated = Money.zero(invoice.currency);
      for (final a in entry.value) {
        totalAllocated += a.amount;
      }
      if (totalAllocated > invoice.total) {
        throw ArgumentError(
          'Invoice ${invoice.id} is over-allocated: total allocated ($totalAllocated) '
          'exceeds invoice total (${invoice.total}).',
        );
      }
    }

    // Filter relevant records strictly for target clientId
    final clientInvoices = invoiceList
        .where((i) => i.clientId == clientId && i.isIssued)
        .toList();

    final clientPayments = paymentList
        .where((p) => p.clientId == clientId)
        .toList();

    final clientAllocations = allocationList
        .where((a) => paymentMap[a.paymentId]!.clientId == clientId)
        .toList();

    // Resolve denomination currency for the client's position
    Currency resolvedCurrency = currency ?? Currency.dzd;
    if (currency == null) {
      if (clientInvoices.isNotEmpty) {
        resolvedCurrency = clientInvoices.first.currency;
      } else if (clientPayments.isNotEmpty) {
        resolvedCurrency = clientPayments.first.currency;
      } else if (clientAllocations.isNotEmpty) {
        resolvedCurrency = clientAllocations.first.currency;
      }
    }

    // Validate that all client-scoped financial records match resolvedCurrency
    for (final invoice in clientInvoices) {
      if (invoice.currency != resolvedCurrency) {
        throw CurrencyMismatchException(
          resolvedCurrency.code,
          invoice.currency.code,
        );
      }
    }
    for (final payment in clientPayments) {
      if (payment.currency != resolvedCurrency) {
        throw CurrencyMismatchException(
          resolvedCurrency.code,
          payment.currency.code,
        );
      }
    }
    for (final alloc in clientAllocations) {
      if (alloc.currency != resolvedCurrency) {
        throw CurrencyMismatchException(
          resolvedCurrency.code,
          alloc.currency.code,
        );
      }
    }

    // Calculate totals using exact integer Money arithmetic
    var totalInvoiced = Money.zero(resolvedCurrency);
    for (final invoice in clientInvoices) {
      totalInvoiced += invoice.total;
    }

    var totalAllocatedPayments = Money.zero(resolvedCurrency);
    for (final alloc in clientAllocations) {
      totalAllocatedPayments += alloc.amount;
    }

    var outstandingDebt = Money.zero(resolvedCurrency);
    for (final invoice in clientInvoices) {
      final allocsForInvoice = allocationsByInvoice[invoice.id] ?? const [];
      var invoiceAllocated = Money.zero(resolvedCurrency);
      for (final a in allocsForInvoice) {
        invoiceAllocated += a.amount;
      }
      outstandingDebt += (invoice.total - invoiceAllocated);
    }

    var unallocatedCredit = Money.zero(resolvedCurrency);
    for (final payment in clientPayments) {
      final allocsForPayment = allocationsByPayment[payment.id] ?? const [];
      var paymentAllocated = Money.zero(resolvedCurrency);
      for (final a in allocsForPayment) {
        paymentAllocated += a.amount;
      }
      unallocatedCredit += (payment.amount - paymentAllocated);
    }

    final netPosition = outstandingDebt - unallocatedCredit;

    return ClientFinancialPosition(
      clientId: clientId,
      currency: resolvedCurrency,
      totalInvoiced: totalInvoiced,
      totalAllocatedPayments: totalAllocatedPayments,
      outstandingDebt: outstandingDebt,
      unallocatedCredit: unallocatedCredit,
      netPosition: netPosition,
    );
  }
}
