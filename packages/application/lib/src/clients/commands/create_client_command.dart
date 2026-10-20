/// Create client command.
library;

import 'package:domain/domain.dart';

/// Command input for creating a new client.
///
/// Encapsulates all data required to request creation of a [Client].
/// Supports optional pre-generated [id] for offline-first creation and synchronization.
final class CreateClientCommand {
  const CreateClientCommand({
    required this.name,
    this.phone,
    this.notes,
    this.id,
    this.createdAt,
  });

  /// Optional pre-generated client identifier (for offline generation and sync).
  final ClientId? id;

  /// Name of the client (required, non-empty after trimming).
  final String name;

  /// Optional contact phone number.
  final String? phone;

  /// Optional administrative notes.
  final String? notes;

  /// Optional creation timestamp (defaults to current time if omitted).
  final DateTime? createdAt;
}
