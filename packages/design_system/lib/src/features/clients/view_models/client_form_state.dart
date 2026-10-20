import 'package:domain/domain.dart';
import 'package:flutter/foundation.dart';

enum ClientFormStatus { initial, submitting, success, error }

@immutable
class ClientFormState {
  const ClientFormState({
    this.status = ClientFormStatus.initial,
    this.client,
    this.name = '',
    this.phone = '',
    this.notes = '',
    this.nameError,
    this.errorMessage,
  });

  final ClientFormStatus status;
  final Client? client;
  final String name;
  final String phone;
  final String notes;
  final String? nameError;
  final String? errorMessage;

  bool get isEditing => client != null;
  bool get isSubmitting => status == ClientFormStatus.submitting;
  bool get isSuccess => status == ClientFormStatus.success;
  bool get hasError => status == ClientFormStatus.error;

  ClientFormState copyWith({
    ClientFormStatus? status,
    Client? client,
    String? name,
    String? phone,
    String? notes,
    String? nameError,
    String? errorMessage,
  }) {
    return ClientFormState(
      status: status ?? this.status,
      client: client ?? this.client,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      notes: notes ?? this.notes,
      nameError: nameError,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClientFormState &&
          other.status == status &&
          other.client == client &&
          other.name == name &&
          other.phone == phone &&
          other.notes == notes &&
          other.nameError == nameError &&
          other.errorMessage == errorMessage;

  @override
  int get hashCode =>
      Object.hash(status, client, name, phone, notes, nameError, errorMessage);
}
