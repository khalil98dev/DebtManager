import 'package:domain/domain.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../../tokens/app_spacing.dart';
import '../surfaces/app_badge.dart';
import 'app_text_field.dart';

/// Specialized input field for entering exact monetary amounts.
///
/// Features:
/// - Currency badge suffix indicating denomination.
/// - Decimal input filtering restricted to currency precision.
/// - Safe exact string parsing to [Money] without double-precision arithmetic.
class AppMoneyField extends StatelessWidget {
  const AppMoneyField({
    super.key,
    required this.label,
    required this.currency,
    this.controller,
    this.initialValue,
    this.placeholder = '0.00',
    this.helperText,
    this.errorText,
    this.isRequired = false,
    this.autofocus = false,
    this.onChanged,
    this.onMoneyChanged,
  });

  final String label;
  final Currency currency;
  final TextEditingController? controller;
  final String? initialValue;
  final String placeholder;
  final String? helperText;
  final String? errorText;
  final bool isRequired;
  final bool autofocus;
  final ValueChanged<String>? onChanged;
  final ValueChanged<Money?>? onMoneyChanged;

  static Money? parse(String rawText, Currency currency) {
    final trimmed = rawText.trim().replaceAll(',', '.');
    if (trimmed.isEmpty) return null;
    try {
      return Money.fromDecimalString(trimmed, currency);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final decimalDigits = currency.decimalDigits;
    final regexPattern = decimalDigits > 0
        ? r'^\d*[\.,]?\d{0,' + decimalDigits.toString() + r'}'
        : r'^\d*';

    return AppTextField(
      label: label,
      controller: controller,
      initialValue: initialValue,
      placeholder: placeholder,
      helperText: helperText,
      errorText: errorText,
      isRequired: isRequired,
      autofocus: autofocus,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(regexPattern)),
      ],
      suffix: Padding(
        padding: const EdgeInsets.only(right: AppSpacing.sm),
        child: AppBadge(label: currency.code, variant: AppBadgeVariant.neutral),
      ),
      onChanged: (text) {
        onChanged?.call(text);
        if (onMoneyChanged != null) {
          final parsed = parse(text, currency);
          onMoneyChanged!(parsed);
        }
      },
    );
  }
}
