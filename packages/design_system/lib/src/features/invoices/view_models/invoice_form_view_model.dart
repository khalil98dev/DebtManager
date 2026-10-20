import 'package:application/application.dart';
import 'package:domain/domain.dart';
import 'package:flutter/foundation.dart';

import 'invoice_form_state.dart';

/// ViewModel managing draft invoice creation and editing with live financial line totals.
class InvoiceFormViewModel extends ChangeNotifier {
  InvoiceFormViewModel({
    required this.clientRepository,
    required this.createInvoice,
    required this.updateInvoiceDraft,
    this.issueInvoice,
    Invoice? initialInvoice,
    ClientId? preselectedClientId,
  }) {
    if (initialInvoice != null) {
      final initialLines = initialInvoice.lines
          .map(
            (l) => InvoiceLineFormItem(
              id: l.id,
              description: l.description,
              quantity: l.quantity,
              unitPriceText: l.unitPrice.format(includeSymbol: false),
              discountText: l.discount.isZero
                  ? ''
                  : l.discount.format(includeSymbol: false),
              unitPrice: l.unitPrice,
              discount: l.discount,
              createdAt: l.createdAt,
            ),
          )
          .toList();

      _state = InvoiceFormState(
        editingInvoice: initialInvoice,
        number: initialInvoice.number,
        notes: initialInvoice.notes ?? '',
        currency: initialInvoice.currency,
        lines: initialLines,
      );
    } else {
      // Default: 1 empty line item
      final defaultLine = InvoiceLineFormItem(
        id: InvoiceLineId.generate(),
        description: '',
        quantity: 1,
        createdAt: DateTime.now(),
      );

      _state = InvoiceFormState(
        number:
            'INV-${DateTime.now().year}-${DateTime.now().millisecondsSinceEpoch % 10000}',
        lines: [defaultLine],
      );
    }

    _preselectedClientId = preselectedClientId ?? initialInvoice?.clientId;
  }

  final ClientRepository clientRepository;
  final CreateInvoice createInvoice;
  final UpdateInvoiceDraft updateInvoiceDraft;
  final IssueInvoice? issueInvoice;
  ClientId? _preselectedClientId;

  InvoiceFormState _state = const InvoiceFormState();
  InvoiceFormState get state => _state;

  /// Refreshes the available client list from repository.
  Future<void> refreshClients() async {
    try {
      final clients = await clientRepository.getAll();
      _state = _state.copyWith(availableClients: clients);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> initialize() async {
    _state = _state.copyWith(status: InvoiceFormStatus.loading);
    notifyListeners();

    try {
      final clients = await clientRepository.getAll();
      Client? selected;
      if (_preselectedClientId != null) {
        selected = clients
            .where((c) => c.id == _preselectedClientId)
            .firstOrNull;
      }

      _state = _state.copyWith(
        status: InvoiceFormStatus.initial,
        availableClients: clients,
        selectedClient: () => selected ?? _state.selectedClient,
      );
    } catch (e) {
      _state = _state.copyWith(
        status: InvoiceFormStatus.error,
        errorMessage: 'Failed to load clients: $e',
      );
    }
    notifyListeners();
  }

  void onClientSelected(Client client) {
    _state = _state.copyWith(
      selectedClient: () => client,
      clientError: null,
      errorMessage: null,
    );
    notifyListeners();
  }

  void onNumberChanged(String number) {
    _state = _state.copyWith(
      number: number,
      numberError: null,
      errorMessage: null,
    );
    notifyListeners();
  }

  void onNotesChanged(String notes) {
    _state = _state.copyWith(notes: notes, errorMessage: null);
    notifyListeners();
  }

  void addLine() {
    final newLine = InvoiceLineFormItem(
      id: InvoiceLineId.generate(),
      description: '',
      quantity: 1,
      createdAt: DateTime.now(),
    );

    _state = _state.copyWith(
      lines: [..._state.lines, newLine],
      linesError: null,
      errorMessage: null,
    );
    notifyListeners();
  }

  void removeLine(InvoiceLineId id) {
    if (_state.lines.length <= 1) return; // Keep at least one line

    final updatedLines = _state.lines.where((l) => l.id != id).toList();
    _state = _state.copyWith(lines: updatedLines);
    notifyListeners();
  }

  void updateLineDescription(InvoiceLineId id, String text) {
    _updateLine(id, (line) => line.copyWith(description: text));
  }

  void updateLineQuantity(InvoiceLineId id, int quantity) {
    final safeQty = quantity > 0 ? quantity : 1;
    _updateLine(id, (line) => line.copyWith(quantity: safeQty));
  }

  void updateLineUnitPrice(InvoiceLineId id, String text) {
    Money? parsed;
    final cleaned = text.trim().replaceAll(',', '.');
    if (cleaned.isNotEmpty) {
      try {
        parsed = Money.fromDecimalString(cleaned, _state.currency);
      } catch (_) {
        parsed = null;
      }
    }
    _updateLine(
      id,
      (line) => line.copyWith(unitPriceText: text, unitPrice: () => parsed),
    );
  }

  void updateLineDiscount(InvoiceLineId id, String text) {
    Money? parsed;
    final cleaned = text.trim().replaceAll(',', '.');
    if (cleaned.isNotEmpty) {
      try {
        parsed = Money.fromDecimalString(cleaned, _state.currency);
      } catch (_) {
        parsed = null;
      }
    }
    _updateLine(
      id,
      (line) => line.copyWith(discountText: text, discount: () => parsed),
    );
  }

  void _updateLine(
    InvoiceLineId id,
    InvoiceLineFormItem Function(InvoiceLineFormItem) updater,
  ) {
    final updated = _state.lines
        .map((l) => l.id == id ? updater(l) : l)
        .toList();
    _state = _state.copyWith(
      lines: updated,
      linesError: null,
      errorMessage: null,
    );
    notifyListeners();
  }

  Future<Invoice?> submit({bool issueDirectly = false}) async {
    if (_state.isSubmitting) return null;

    // Validation
    String? clientError;
    if (_state.selectedClient == null) {
      clientError = 'Please select a client.';
    }

    String? numberError;
    if (_state.number.trim().isEmpty) {
      numberError = 'Invoice number cannot be empty.';
    }

    String? linesError;
    final domainLines = <InvoiceLine>[];
    for (var i = 0; i < _state.lines.length; i++) {
      final l = _state.lines[i];
      if (l.description.trim().isEmpty) {
        linesError = 'Line ${i + 1}: description cannot be empty.';
        break;
      }
      if (l.unitPrice == null) {
        linesError = 'Line ${i + 1}: valid unit price is required.';
        break;
      }

      domainLines.add(
        InvoiceLine(
          id: l.id,
          description: l.description.trim(),
          quantity: l.quantity,
          unitPrice: l.unitPrice!,
          discount: l.discount ?? Money.zero(_state.currency),
          createdAt: l.createdAt,
        ),
      );
    }

    if (clientError != null || numberError != null || linesError != null) {
      _state = _state.copyWith(
        clientError: clientError,
        numberError: numberError,
        linesError: linesError,
      );
      notifyListeners();
      return null;
    }

    _state = _state.copyWith(
      status: InvoiceFormStatus.submitting,
      errorMessage: null,
    );
    notifyListeners();

    final Result<Invoice> result;
    if (_state.isEditing) {
      result = await updateInvoiceDraft.execute(
        UpdateInvoiceDraftCommand(
          id: _state.editingInvoice!.id,
          clientId: _state.selectedClient!.id,
          number: _state.number.trim(),
          lines: domainLines,
          notes: _state.notes.trim().isEmpty ? null : _state.notes.trim(),
          currency: _state.currency,
        ),
      );
    } else {
      result = await createInvoice.execute(
        CreateInvoiceCommand(
          clientId: _state.selectedClient!.id,
          number: _state.number.trim(),
          lines: domainLines,
          notes: _state.notes.trim().isEmpty ? null : _state.notes.trim(),
          currency: _state.currency,
        ),
      );
    }

    if (result.isSuccess) {
      final saved = result.dataOrNull!;

      if (issueDirectly && issueInvoice != null) {
        final issueResult = await issueInvoice!.execute(
          IssueInvoiceCommand(invoiceId: saved.id, issuedAt: DateTime.now()),
        );
        if (issueResult.isSuccess) {
          final issued = issueResult.dataOrNull!;
          _state = _state.copyWith(
            status: InvoiceFormStatus.success,
            editingInvoice: issued,
          );
          notifyListeners();
          return issued;
        } else {
          _state = _state.copyWith(
            status: InvoiceFormStatus.error,
            errorMessage:
                issueResult.failureOrNull?.message ??
                'Failed to issue invoice.',
            editingInvoice: saved,
          );
          notifyListeners();
          return null;
        }
      }

      _state = _state.copyWith(
        status: InvoiceFormStatus.success,
        editingInvoice: saved,
      );
      notifyListeners();
      return saved;
    } else {
      _state = _state.copyWith(
        status: InvoiceFormStatus.error,
        errorMessage:
            result.failureOrNull?.message ?? 'Failed to save invoice.',
      );
      notifyListeners();
      return null;
    }
  }
}
