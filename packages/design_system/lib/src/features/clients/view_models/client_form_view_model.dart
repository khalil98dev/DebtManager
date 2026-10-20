import 'package:application/application.dart';
import 'package:domain/domain.dart';
import 'package:flutter/foundation.dart';

import 'client_form_state.dart';

/// ViewModel managing client creation and profile editing workflows.
class ClientFormViewModel extends ChangeNotifier {
  ClientFormViewModel({
    required this.createClient,
    required this.updateClient,
    Client? initialClient,
  }) {
    if (initialClient != null) {
      _state = ClientFormState(
        client: initialClient,
        name: initialClient.name,
        phone: initialClient.phone ?? '',
        notes: initialClient.notes ?? '',
      );
    }
  }

  final CreateClient createClient;
  final UpdateClient updateClient;

  ClientFormState _state = const ClientFormState();
  ClientFormState get state => _state;

  void onNameChanged(String value) {
    _state = _state.copyWith(name: value, nameError: null, errorMessage: null);
    notifyListeners();
  }

  void onPhoneChanged(String value) {
    _state = _state.copyWith(phone: value, errorMessage: null);
    notifyListeners();
  }

  void onNotesChanged(String value) {
    _state = _state.copyWith(notes: value, errorMessage: null);
    notifyListeners();
  }

  Future<Client?> submit() async {
    if (_state.isSubmitting) return null;

    final trimmedName = _state.name.trim();
    if (trimmedName.isEmpty) {
      _state = _state.copyWith(nameError: 'Client name cannot be empty.');
      notifyListeners();
      return null;
    }

    _state = _state.copyWith(
      status: ClientFormStatus.submitting,
      errorMessage: null,
    );
    notifyListeners();

    final phoneOrNull = _state.phone.trim().isEmpty
        ? null
        : _state.phone.trim();
    final notesOrNull = _state.notes.trim().isEmpty
        ? null
        : _state.notes.trim();

    final Result<Client> result;
    if (_state.isEditing) {
      result = await updateClient.execute(
        UpdateClientCommand(
          id: _state.client!.id,
          name: trimmedName,
          phone: phoneOrNull,
          notes: notesOrNull,
        ),
      );
    } else {
      result = await createClient.execute(
        CreateClientCommand(
          name: trimmedName,
          phone: phoneOrNull,
          notes: notesOrNull,
        ),
      );
    }

    if (result.isSuccess) {
      final savedClient = result.dataOrNull!;
      _state = _state.copyWith(
        status: ClientFormStatus.success,
        client: savedClient,
      );
      notifyListeners();
      return savedClient;
    } else {
      _state = _state.copyWith(
        status: ClientFormStatus.error,
        errorMessage: result.failureOrNull?.message ?? 'Operation failed.',
      );
      notifyListeners();
      return null;
    }
  }
}
