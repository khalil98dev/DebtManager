import 'package:meta/meta.dart';

import '../clients/client_id.dart';
import '../common/validation_utils.dart';
import '../value_objects/money.dart';
import 'payment_id.dart';

export 'payment_id.dart';

/// An immutable domain entity representing a payment received from a client.
///
/// Encapsulates the receipt of funds independently of any specific invoice,
/// debt balance, or payment allocation.
///
/// In accordance with financial domain invariants and auditing rules, core
/// transaction attributes ([id], [clientId], [amount], [receivedAt], and [createdAt])
/// are strictly immutable facts of the financial event. They cannot be altered
/// through unrestricted domain entity mutations. Only administrative metadata
/// ([notes]) provides an immutable domain update operation ([updateNotes]).
@immutable
class Payment {
  /// Creates a [Payment] instance with strict invariant validation.
  ///
  /// - [amount] must be strictly positive (> 0).
  /// - [notes] is trimmed and normalized to `null` if empty or whitespace-only.
  Payment({
    required this.id,
    required this.clientId,
    required this.amount,
    required this.receivedAt,
    String? notes,
    required this.createdAt,
  }) : notes = ValidationUtils.normalizeOptionalString(notes) {
    if (!amount.isPositive) {
      throw ArgumentError.value(
        amount,
        'amount',
        'Payment amount must be strictly positive (> 0).',
      );
    }
  }

  /// Factory constructor for creating a new [Payment].
  ///
  /// Automatically generates an offline-ready [PaymentId] if [id] is omitted.
  /// If [createdAt] is not provided, defaults to the current timestamp.
  /// If [receivedAt] is not provided, defaults to [createdAt].
  factory Payment.create({
    PaymentId? id,
    required ClientId clientId,
    required Money amount,
    DateTime? receivedAt,
    String? notes,
    DateTime? createdAt,
  }) {
    final created = createdAt ?? DateTime.now();
    return Payment(
      id: id ?? PaymentId.generate(),
      clientId: clientId,
      amount: amount,
      receivedAt: receivedAt ?? created,
      notes: notes,
      createdAt: created,
    );
  }

  /// Unique identifier of this payment.
  final PaymentId id;

  /// Identifier of the client who made the payment.
  final ClientId clientId;

  /// Monetary amount of funds received (strictly positive).
  final Money amount;

  /// Timestamp when the payment was physically received.
  final DateTime receivedAt;

  /// Optional notes or payment reference (e.g. check number, receipt memo).
  final String? notes;

  /// System audit timestamp when this payment record was created.
  final DateTime createdAt;

  /// Monetary currency of this payment.
  Currency get currency => amount.currency;

  /// Returns a new [Payment] with updated [newNotes].
  ///
  /// Trims whitespace, normalizes blank values to `null`, and preserves
  /// all financial transaction facts ([id], [clientId], [amount], [receivedAt],
  /// and [createdAt]).
  Payment updateNotes(String? newNotes) {
    return Payment(
      id: id,
      clientId: clientId,
      amount: amount,
      receivedAt: receivedAt,
      notes: newNotes,
      createdAt: createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Payment && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Payment(id: $id, clientId: $clientId, amount: $amount, '
      'receivedAt: $receivedAt, notes: $notes, createdAt: $createdAt)';
}
