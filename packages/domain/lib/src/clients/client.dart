import 'package:meta/meta.dart';

import '../common/validation_utils.dart';
import 'client_id.dart';

@immutable
class Client {
  Client({
    required this.id,
    required String name,
    String? phone,
    String? notes,
    required this.createdAt,
    DateTime? updatedAt,
  }) : name = ValidationUtils.validateAndTrimRequired(
         name,
         name: 'name',
         message: 'Client name cannot be empty.',
       ),
       phone = ValidationUtils.normalizeOptionalString(phone),
       notes = ValidationUtils.normalizeOptionalString(notes),
       updatedAt = updatedAt ?? createdAt {
    if (this.updatedAt.isBefore(createdAt)) {
      throw ArgumentError.value(
        this.updatedAt,
        'updatedAt',
        'updatedAt cannot be before createdAt.',
      );
    }
  }

  factory Client.create({
    ClientId? id,
    required String name,
    String? phone,
    String? notes,
    DateTime? createdAt,
  }) {
    final now = createdAt ?? DateTime.now();

    return Client(
      id: id ?? ClientId.generate(),
      name: name,
      phone: phone,
      notes: notes,
      createdAt: now,
      updatedAt: now,
    );
  }

  final ClientId id;

  final String name;

  final String? phone;

  final String? notes;

  final DateTime createdAt;

  final DateTime updatedAt;

  Client rename(String newName, {DateTime? updatedAt}) {
    return Client(
      id: id,
      name: newName,
      phone: phone,
      notes: notes,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Client changePhone(String? newPhone, {DateTime? updatedAt}) {
    return Client(
      id: id,
      name: name,
      phone: newPhone,
      notes: notes,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Client updatePhone(String? newPhone, {DateTime? updatedAt}) =>
      changePhone(newPhone, updatedAt: updatedAt);

  Client updateNotes(String? newNotes, {DateTime? updatedAt}) {
    return Client(
      id: id,
      name: name,
      phone: phone,
      notes: newNotes,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Client changeNotes(String? newNotes, {DateTime? updatedAt}) =>
      updateNotes(newNotes, updatedAt: updatedAt);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Client && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Client(id: $id, name: $name, phone: $phone, notes: $notes, createdAt: $createdAt, updatedAt: $updatedAt)';
}
