/// Record payment command.
library;

import 'package:domain/domain.dart';

/// Command input for recording a new payment received from a client.
///
/// Encapsulates all data required to record a [Payment].
/// Supports optional pre-generated [id] for offline creation and synchronization.
final class RecordPaymentCommand {
  const RecordPaymentCommand({
    required this.clientId,
    required this.amount,
    this.receivedAt,
    this.notes,
    this.id,
    this.createdAt,
  });

  /// Client who made the payment.
  final ClientId clientId;

  /// Monetary amount received (must be strictly positive).
  final Money amount;

  /// Timestamp when the payment was received (defaults to creation time if omitted).
  final DateTime? receivedAt;

  /// Optional payment notes or memo.
  final String? notes;

  /// Optional pre-generated payment identifier (for offline generation and sync).
  final PaymentId? id;

  /// Optional creation audit timestamp (defaults to current time if omitted).
  final DateTime? createdAt;
}
