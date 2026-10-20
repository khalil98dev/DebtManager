import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../../tokens/app_colors.dart';
import '../../tokens/app_durations.dart';
import '../../tokens/app_radii.dart';
import '../../tokens/app_spacing.dart';
import '../../tokens/app_typography.dart';

/// Senior-grade, top-labeled text input field following UI-Skills recommendations.
///
/// Features:
/// - Top-aligned label with optional required asterisk indicator.
/// - Ambient glowing focus ring and mouse hover illumination.
/// - Inline error message with warning icon.
/// - Smooth animated transitions and custom prefix/suffix badge integration.
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.controller,
    this.initialValue,
    this.placeholder,
    this.helperText,
    this.errorText,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.isRequired = false,
    this.autofocus = false,
    this.maxLines = 1,
    this.maxLength,
    this.inputFormatters,
    this.onChanged,
    this.onSubmitted,
    this.prefix,
    this.suffix,
  });

  final String label;
  final TextEditingController? controller;
  final String? initialValue;
  final String? placeholder;
  final String? helperText;
  final String? errorText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final bool isRequired;
  final bool autofocus;
  final int maxLines;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final Widget? prefix;
  final Widget? suffix;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late final FocusNode _focusNode;
  TextEditingController? _internalController;
  bool _isFocused = false;
  bool _isHovered = false;

  TextEditingController get _effectiveController =>
      widget.controller ?? _internalController!;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);

    if (widget.controller == null) {
      _internalController = TextEditingController(text: widget.initialValue);
    }
  }

  @override
  void didUpdateWidget(AppTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller == null && oldWidget.controller != null) {
      _internalController = TextEditingController(
        text: oldWidget.controller!.text,
      );
    } else if (widget.controller != null && oldWidget.controller == null) {
      _internalController?.dispose();
      _internalController = null;
    }
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus != _isFocused) {
      setState(() => _isFocused = _focusNode.hasFocus);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _internalController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty;

    final borderColor = hasError
        ? AppColors.destructive(context)
        : _isFocused
        ? AppColors.primaryAccent(context)
        : _isHovered
        ? AppColors.textTertiary(context).withValues(alpha: 0.6)
        : AppColors.border(context);

    final glowColor = hasError
        ? AppColors.destructive(context)
        : AppColors.primaryAccent(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Top-aligned label
        Row(
          children: [
            Flexible(
              child: Text(
                widget.label,
                style: AppTypography.subheadline.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary(context),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (widget.isRequired) ...[
              const SizedBox(width: AppSpacing.xxs),
              Text(
                '*',
                style: AppTypography.subheadline.copyWith(
                  color: AppColors.destructive(context),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.xs),

        // Input container with glowing focus ring and hover detection
        MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: AnimatedContainer(
            duration: AppDurations.quick,
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: AppColors.surface(context),
              borderRadius: AppRadii.smRadius,
              border: Border.all(
                color: borderColor,
                width: _isFocused ? 1.5 : 1.0,
              ),
              boxShadow: _isFocused
                  ? [
                      BoxShadow(
                        color: glowColor.withValues(alpha: 0.16),
                        blurRadius: 8.0,
                        spreadRadius: 1.0,
                        offset: const Offset(0, 1),
                      ),
                    ]
                  : null,
            ),
            child: CupertinoTextField(
              controller: _effectiveController,
              focusNode: _focusNode,
              autofocus: widget.autofocus,
              placeholder: widget.placeholder,
              placeholderStyle: AppTypography.body.copyWith(
                color: AppColors.textTertiary(context),
              ),
              style: AppTypography.body.copyWith(
                color: AppColors.textPrimary(context),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: null,
              cursorColor: AppColors.primaryAccent(context),
              keyboardType: widget.keyboardType,
              textInputAction: widget.textInputAction,
              obscureText: widget.obscureText,
              maxLines: widget.maxLines,
              maxLength: widget.maxLength,
              inputFormatters: widget.inputFormatters,
              onChanged: widget.onChanged,
              onSubmitted: widget.onSubmitted,
              prefix: widget.prefix,
              suffix: widget.suffix,
            ),
          ),
        ),

        // Helper or Error Text
        if (hasError) ...[
          const SizedBox(height: AppSpacing.xxs + 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                CupertinoIcons.exclamationmark_circle_fill,
                size: 13.0,
                color: AppColors.destructive(context),
              ),
              const SizedBox(width: AppSpacing.xxs),
              Expanded(
                child: Text(
                  widget.errorText!,
                  style: AppTypography.footnote.copyWith(
                    color: AppColors.destructive(context),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ] else if (widget.helperText != null) ...[
          const SizedBox(height: AppSpacing.xxs + 2),
          Text(
            widget.helperText!,
            style: AppTypography.footnote.copyWith(
              color: AppColors.textSecondary(context),
            ),
          ),
        ],
      ],
    );
  }
}
