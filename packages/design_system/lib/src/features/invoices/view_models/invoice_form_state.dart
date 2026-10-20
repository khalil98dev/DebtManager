import 'package:domain/domain.dart';
import 'package:flutter/foundation.dart';

enum InvoiceFormStatus { initial, loading, submitting, success, error }

/// Represents an editable line row in the invoice form.
@immutable
class InvoiceLineFormItem {
  const InvoiceLineFormItem({
    required this.id,
    this.description = '',
    this.quantity = 1,
    this.unitPriceText = '',
    this.discountText = '',
    this.unitPrice,
    this.discount,
    required this.createdAt,
  });

  final InvoiceLineId id;
  final String description;
  final int quantity;
  final String unitPriceText;
  final String discountText;
  final Money? unitPrice;
  final Money? discount;
  final DateTime createdAt;

  Money lineTotal(Currency currency) {
    if (unitPrice == null || quantity <= 0) return Money.zero(currency);
    final gross = unitPrice! * quantity;
    final disc = discount ?? Money.zero(currency);
    return gross > disc ? gross - disc : Money.zero(currency);
  }

  InvoiceLineFormItem copyWith({
    String? description,
    int? quantity,
    String? unitPriceText,
    String? discountText,
    Money? Function()? unitPrice,
    Money? Function()? discount,
  }) {
    return InvoiceLineFormItem(
      id: id,
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      unitPriceText: unitPriceText ?? this.unitPriceText,
      discountText: discountText ?? this.discountText,
      unitPrice: unitPrice != null ? unitPrice() : this.unitPrice,
      discount: discount != null ? discount() : this.discount,
      createdAt: createdAt,
    );
  }
}

@immutable
class InvoiceFormState {
  const InvoiceFormState({
    this.status = InvoiceFormStatus.initial,
    this.editingInvoice,
    this.selectedClient,
    this.availableClients = const [],
    this.number = '',
    this.notes = '',
    this.currency = Currency.dzd,
    this.lines = const [],
    this.clientError,
    this.numberError,
    this.linesError,
    this.errorMessage,
  });

  final InvoiceFormStatus status;
  final Invoice? editingInvoice;
  final Client? selectedClient;
  final List<Client> availableClients;
  final String number;
  final String notes;
  final Currency currency;
  final List<InvoiceLineFormItem> lines;

  final String? clientError;
  final String? numberError;
  final String? linesError;
  final String? errorMessage;

  bool get isEditing => editingInvoice != null;
  bool get isSubmitting => status == InvoiceFormStatus.submitting;
  bool get isSuccess => status == InvoiceFormStatus.success;

  Money get grossTotal {
    var total = Money.zero(currency);
    for (final line in lines) {
      if (line.unitPrice != null && line.quantity > 0) {
        total += (line.unitPrice! * line.quantity);
      }
    }
    return total;
  }

  Money get discountTotal {
    var total = Money.zero(currency);
    for (final line in lines) {
      if (line.discount != null) {
        total += line.discount!;
      }
    }
    return total;
  }

  Money get netTotal => grossTotal > discountTotal
      ? grossTotal - discountTotal
      : Money.zero(currency);

  InvoiceFormState copyWith({
    InvoiceFormStatus? status,
    Invoice? editingInvoice,
    Client? Function()? selectedClient,
    List<Client>? availableClients,
    String? number,
    String? notes,
    Currency? currency,
    List<InvoiceLineFormItem>? lines,
    String? clientError,
    String? numberError,
    String? linesError,
    String? errorMessage,
  }) {
    return InvoiceFormState(
      status: status ?? this.status,
      editingInvoice: editingInvoice ?? this.editingInvoice,
      selectedClient: selectedClient != null
          ? selectedClient()
          : this.selectedClient,
      availableClients: availableClients ?? this.availableClients,
      number: number ?? this.number,
      notes: notes ?? this.notes,
      currency: currency ?? this.currency,
      lines: lines ?? this.lines,
      clientError: clientError,
      numberError: numberError,
      linesError: linesError,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
