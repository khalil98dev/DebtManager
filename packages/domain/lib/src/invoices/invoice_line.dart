import 'package:meta/meta.dart';

import '../common/validation_utils.dart';
import '../value_objects/money.dart';
import 'invoice_line_id.dart';

export 'invoice_line_id.dart';

/// An immutable domain entity representing a single line item within an invoice.
///
/// Encapsulates an itemized description, quantity, unit price, and discount,
/// ensuring integer-based precision arithmetic, currency consistency, and
/// validation across all monetary calculations.
@immutable
class InvoiceLine {
  /// Creates an [InvoiceLine] instance with strict invariant validation.
  ///
  /// - [description] is trimmed and must not be empty.
  /// - [quantity] must be strictly positive (> 0).
  /// - [unitPrice] and [discount] must be non-negative.
  /// - [discount] defaults to zero in the currency of [unitPrice] if omitted or null.
  /// - [discount] and [unitPrice] must share the exact same currency.
  /// - [discount] cannot exceed [grossTotal].
  InvoiceLine({
    required this.id,
    required String description,
    required this.quantity,
    required this.unitPrice,
    Money? discount,
    required this.createdAt,
  }) : description = ValidationUtils.validateAndTrimRequired(
         description,
         name: 'description',
         message: 'Invoice line description cannot be empty.',
       ),
       discount = discount ?? Money.zero(unitPrice.currency) {
    _validateState(
      quantity: quantity,
      unitPrice: unitPrice,
      discount: this.discount,
    );
  }

  /// Factory constructor for creating a new [InvoiceLine].
  ///
  /// Automatically generates an offline-ready [InvoiceLineId] and sets [createdAt]
  /// to the current timestamp if not explicitly supplied.
  factory InvoiceLine.create({
    InvoiceLineId? id,
    required String description,
    required int quantity,
    required Money unitPrice,
    Money? discount,
    DateTime? createdAt,
  }) {
    return InvoiceLine(
      id: id ?? InvoiceLineId.generate(),
      description: description,
      quantity: quantity,
      unitPrice: unitPrice,
      discount: discount,
      createdAt: createdAt ?? DateTime.now(),
    );
  }

  /// Unique identifier of this invoice line item.
  final InvoiceLineId id;

  /// Trimmed description of the goods or services.
  final String description;

  /// Number of units purchased (strictly positive).
  final int quantity;

  /// Unit price per single item.
  final Money unitPrice;

  /// Total discount deducted from [grossTotal] for this line item.
  final Money discount;

  /// Timestamp when this line item was created.
  final DateTime createdAt;

  /// Currency of this line item, determined by [unitPrice].
  Currency get currency => unitPrice.currency;

  /// The total amount before discount: `unitPrice * quantity`.
  ///
  /// Propagates [MoneyOverflowException] if integer overflow occurs.
  Money get grossTotal => unitPrice * quantity;

  /// The net total amount after discount: `grossTotal - discount`.
  Money get lineTotal => grossTotal - discount;

  /// Returns a new [InvoiceLine] with updated [newDescription].
  ///
  /// Trims whitespace, validates that [newDescription] is not empty, and
  /// preserves [id], [createdAt], [quantity], [unitPrice], and [discount].
  InvoiceLine updateDescription(String newDescription) {
    return InvoiceLine(
      id: id,
      description: newDescription,
      quantity: quantity,
      unitPrice: unitPrice,
      discount: discount,
      createdAt: createdAt,
    );
  }

  /// Alias for [updateDescription].
  InvoiceLine changeDescription(String newDescription) =>
      updateDescription(newDescription);

  /// Returns a new [InvoiceLine] with updated [newQuantity].
  ///
  /// Throws [ArgumentError] if [newQuantity] <= 0 or if the existing [discount]
  /// exceeds the newly calculated [grossTotal].
  InvoiceLine updateQuantity(int newQuantity) {
    return InvoiceLine(
      id: id,
      description: description,
      quantity: newQuantity,
      unitPrice: unitPrice,
      discount: discount,
      createdAt: createdAt,
    );
  }

  /// Alias for [updateQuantity].
  InvoiceLine changeQuantity(int newQuantity) => updateQuantity(newQuantity);

  /// Returns a new [InvoiceLine] with updated [newDiscount].
  ///
  /// Throws [ArgumentError] if [newDiscount] is negative or exceeds [grossTotal].
  /// Throws [CurrencyMismatchException] if [newDiscount] has a different currency than [unitPrice].
  InvoiceLine updateDiscount(Money newDiscount) {
    return InvoiceLine(
      id: id,
      description: description,
      quantity: quantity,
      unitPrice: unitPrice,
      discount: newDiscount,
      createdAt: createdAt,
    );
  }

  /// Alias for [updateDiscount].
  InvoiceLine changeDiscount(Money newDiscount) => updateDiscount(newDiscount);

  /// Returns a new [InvoiceLine] with updated [newUnitPrice] and optional [discount].
  ///
  /// ### Currency & Discount Handling:
  /// - If [newUnitPrice] has the **same currency** as the current unit price:
  ///   uses [discount] if explicitly provided, otherwise retains the current [discount]
  ///   (validating that it does not exceed the new [grossTotal]).
  /// - If [newUnitPrice] has a **different currency**:
  ///   uses [discount] if explicitly provided (which must match [newUnitPrice.currency]),
  ///   or safely resets discount to zero in the new currency (`Money.zero(newUnitPrice.currency)`).
  ///   An incompatible currency can never remain.
  InvoiceLine updateUnitPrice(Money newUnitPrice, {Money? discount}) {
    final resolvedDiscount =
        discount ??
        (newUnitPrice.currency == unitPrice.currency
            ? this.discount
            : Money.zero(newUnitPrice.currency));

    return InvoiceLine(
      id: id,
      description: description,
      quantity: quantity,
      unitPrice: newUnitPrice,
      discount: resolvedDiscount,
      createdAt: createdAt,
    );
  }

  /// Alias for [updateUnitPrice].
  InvoiceLine changeUnitPrice(Money newUnitPrice, {Money? discount}) =>
      updateUnitPrice(newUnitPrice, discount: discount);

  /// Returns a new [InvoiceLine] converted to [newCurrency] with [newUnitPrice]
  /// and optional [newDiscount].
  ///
  /// Throws [CurrencyMismatchException] if [newUnitPrice] does not match [newCurrency].
  InvoiceLine changeCurrency(
    Currency newCurrency, {
    required Money newUnitPrice,
    Money? newDiscount,
  }) {
    if (newUnitPrice.currency != newCurrency) {
      throw CurrencyMismatchException(
        newCurrency.code,
        newUnitPrice.currency.code,
      );
    }
    return updateUnitPrice(
      newUnitPrice,
      discount: newDiscount ?? Money.zero(newCurrency),
    );
  }

  /// Returns a copy of this [InvoiceLine] with specified fields replaced.
  ///
  /// If [unitPrice] is updated to a different currency and [discount] is omitted,
  /// the discount is automatically reset to zero in the new currency.
  InvoiceLine copyWith({
    String? description,
    int? quantity,
    Money? unitPrice,
    Money? discount,
  }) {
    final targetUnitPrice = unitPrice ?? this.unitPrice;
    final targetDiscount =
        discount ??
        (targetUnitPrice.currency == this.unitPrice.currency
            ? this.discount
            : Money.zero(targetUnitPrice.currency));

    return InvoiceLine(
      id: id,
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      unitPrice: targetUnitPrice,
      discount: targetDiscount,
      createdAt: createdAt,
    );
  }

  static void _validateState({
    required int quantity,
    required Money unitPrice,
    required Money discount,
  }) {
    if (quantity <= 0) {
      throw ArgumentError.value(
        quantity,
        'quantity',
        'Invoice line quantity must be greater than zero.',
      );
    }
    if (unitPrice.isNegative) {
      throw ArgumentError.value(
        unitPrice,
        'unitPrice',
        'Invoice line unit price cannot be negative.',
      );
    }
    if (discount.isNegative) {
      throw ArgumentError.value(
        discount,
        'discount',
        'Invoice line discount cannot be negative.',
      );
    }
    if (discount.currency != unitPrice.currency) {
      throw CurrencyMismatchException(
        unitPrice.currency.code,
        discount.currency.code,
      );
    }
    final gross = unitPrice * quantity;
    if (discount > gross) {
      throw ArgumentError.value(
        discount,
        'discount',
        'Invoice line discount ($discount) cannot exceed gross total ($gross).',
      );
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is InvoiceLine && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'InvoiceLine(id: $id, description: $description, quantity: $quantity, '
      'unitPrice: $unitPrice, discount: $discount, grossTotal: $grossTotal, '
      'lineTotal: $lineTotal, createdAt: $createdAt)';
}
