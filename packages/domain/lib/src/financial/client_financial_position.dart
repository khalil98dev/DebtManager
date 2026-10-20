import 'package:meta/meta.dart';

import '../clients/client_id.dart';
import '../value_objects/money.dart';

/// An immutable domain value object representing the comprehensive financial position
/// of a [Client] in a specific [Currency].
///
/// Encapsulates total billed debt on issued invoices, allocated payments,
/// remaining outstanding debt, unallocated credits, and overall net position.
@immutable
class ClientFinancialPosition {
  /// Creates a [ClientFinancialPosition] instance.
  const ClientFinancialPosition({
    required this.clientId,
    required this.currency,
    required this.totalInvoiced,
    required this.totalAllocatedPayments,
    required this.outstandingDebt,
    required this.unallocatedCredit,
    required this.netPosition,
  });

  /// Identifier of the client.
  final ClientId clientId;

  /// Currency in which all financial position amounts are denominated.
  final Currency currency;

  /// Sum of all finalized/issued invoices billed to this client.
  final Money totalInvoiced;

  /// Total payment funds that have been allocated to this client's issued invoices.
  final Money totalAllocatedPayments;

  /// Remaining unpaid debt across all issued invoices (`totalInvoiced - totalAllocatedPayments`).
  final Money outstandingDebt;

  /// Remaining unallocated payment funds held on the client's account.
  final Money unallocatedCredit;

  /// The net financial position: `outstandingDebt - unallocatedCredit`.
  ///
  /// - **Positive**: Client has net outstanding debt payable to the business.
  /// - **Negative**: Client has net excess credit with the business.
  /// - **Zero**: Account is completely balanced.
  final Money netPosition;

  /// Whether the client has any remaining unpaid debt on issued invoices.
  bool get hasOutstandingDebt => outstandingDebt.isPositive;

  /// Whether the client has any unallocated credit available.
  bool get hasUnallocatedCredit => unallocatedCredit.isPositive;

  /// Whether the client is a net debtor (`netPosition > 0`).
  bool get isNetDebtor => netPosition.isPositive;

  /// Whether the client is a net creditor (`netPosition < 0`).
  bool get isNetCreditor => netPosition.isNegative;

  /// Whether the client's financial position is completely balanced (`netPosition == 0`).
  bool get isBalanced => netPosition.isZero;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ClientFinancialPosition &&
          other.clientId == clientId &&
          other.currency == currency &&
          other.totalInvoiced == totalInvoiced &&
          other.totalAllocatedPayments == totalAllocatedPayments &&
          other.outstandingDebt == outstandingDebt &&
          other.unallocatedCredit == unallocatedCredit &&
          other.netPosition == netPosition);

  @override
  int get hashCode => Object.hash(
    clientId,
    currency,
    totalInvoiced,
    totalAllocatedPayments,
    outstandingDebt,
    unallocatedCredit,
    netPosition,
  );

  @override
  String toString() =>
      'ClientFinancialPosition(clientId: $clientId, currency: ${currency.code}, '
      'totalInvoiced: $totalInvoiced, totalAllocatedPayments: $totalAllocatedPayments, '
      'outstandingDebt: $outstandingDebt, unallocatedCredit: $unallocatedCredit, '
      'netPosition: $netPosition)';
}
