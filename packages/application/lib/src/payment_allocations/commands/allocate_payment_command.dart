/// Allocate payment command.
library;

import 'package:domain/domain.dart';

/// Command input for allocating funds from a payment to an invoice.
///
/// Encapsulates all data required to create a [PaymentAllocation].
/// Supports optional pre-generated [id] for offline creation and synchronization.
final class AllocatePaymentCommand {
  const AllocatePaymentCommand({
    required this.paymentId,
    required this.invoiceId,
    required this.amount,
    this.id,
    this.createdAt,
  });

  /// Payment from which funds are being allocated.
  final PaymentId paymentId;

  /// Invoice to which funds are being applied.
  final InvoiceId invoiceId;

  /// Monetary amount to allocate (must be strictly positive).
  final Money amount;

  /// Optional pre-generated payment allocation identifier (for offline generation and sync).
  final PaymentAllocationId? id;

  /// Optional creation audit timestamp (defaults to current time if omitted).
  final DateTime? createdAt;
}
