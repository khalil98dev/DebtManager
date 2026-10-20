import 'package:meta/meta.dart';

import '../invoices/invoice_id.dart';
import '../value_objects/money.dart';
import 'payment_allocation_id.dart';
import 'payment_id.dart';

export 'payment_allocation_id.dart';

/// An immutable domain entity representing the allocation of funds from a [Payment]
/// to an specific [Invoice].
///
/// Decouples payments from invoices by modeling their many-to-many relationship.
/// Stores only typed identifiers ([paymentId], [invoiceId]), the allocated [amount],
/// and audit timestamp [createdAt].
///
/// ### Domain Service & Application Validation Boundaries
/// Because `PaymentAllocation` is an isolated entity that does not hold navigation
/// references to `Payment` or `Invoice` aggregates, cross-aggregate business rules
/// must be validated against related records at the application or domain-service boundary:
///
/// 1. **Currency Consistency**: The allocation [amount] currency must match both
///    the payment currency and the invoice currency.
/// 2. **Payment Ownership & Invoice Ownership**: The referenced payment and invoice
///    must both belong to the exact same client.
/// 3. **Allocation Limits (Payment Capacity & Invoice Balance)**:
///    - The allocation [amount] cannot exceed the remaining unallocated capacity
///      of the payment (`payment.amount - totalAllocatedToOtherInvoices`).
///    - The allocation [amount] cannot exceed the remaining unpaid balance
///      of the invoice (`invoice.total - totalAllocatedFromOtherPayments`).
/// 4. **Duplicate Allocation Policies**: Application and domain services must
///    enforce uniqueness or merge policies to prevent conflicting duplicate active
///    allocations for the same payment-invoice pair.
/// 5. **Entity Isolation**: This entity intentionally contains no database queries,
///    navigation properties, balance calculations, or payment mutation methods.
@immutable
class PaymentAllocation {
  /// Creates a [PaymentAllocation] instance with strict invariant validation.
  ///
  /// - [amount] must be strictly positive (> 0).
  PaymentAllocation({
    required this.id,
    required this.paymentId,
    required this.invoiceId,
    required this.amount,
    required this.createdAt,
  }) {
    if (!amount.isPositive) {
      throw ArgumentError.value(
        amount,
        'amount',
        'Payment allocation amount must be strictly positive (> 0).',
      );
    }
  }

  /// Factory constructor for creating a new [PaymentAllocation].
  ///
  /// Automatically generates an offline-ready [PaymentAllocationId] if [id] is omitted.
  /// Defaults [createdAt] to the current timestamp if not explicitly supplied.
  factory PaymentAllocation.create({
    PaymentAllocationId? id,
    required PaymentId paymentId,
    required InvoiceId invoiceId,
    required Money amount,
    DateTime? createdAt,
  }) {
    return PaymentAllocation(
      id: id ?? PaymentAllocationId.generate(),
      paymentId: paymentId,
      invoiceId: invoiceId,
      amount: amount,
      createdAt: createdAt ?? DateTime.now(),
    );
  }

  /// Unique identifier of this payment allocation.
  final PaymentAllocationId id;

  /// Identifier of the payment funding this allocation.
  final PaymentId paymentId;

  /// Identifier of the invoice receiving this allocation.
  final InvoiceId invoiceId;

  /// Monetary amount allocated to the invoice (strictly positive).
  final Money amount;

  /// System audit timestamp when this allocation record was created.
  final DateTime createdAt;

  /// Monetary currency of this allocation, derived from [amount].
  Currency get currency => amount.currency;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is PaymentAllocation && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'PaymentAllocation(id: $id, paymentId: $paymentId, invoiceId: $invoiceId, '
      'amount: $amount, createdAt: $createdAt)';
}
