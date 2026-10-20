import 'package:domain/domain.dart';

/// Command to update an existing client's details.
final class UpdateClientCommand {
  const UpdateClientCommand({
    required this.id,
    required this.name,
    this.phone,
    this.notes,
  });

  final ClientId id;
  final String name;
  final String? phone;
  final String? notes;
}
