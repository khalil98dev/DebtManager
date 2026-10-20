import 'package:flutter/cupertino.dart';

import '../../tokens/app_colors.dart';
import '../../tokens/app_durations.dart';
import '../../tokens/app_radii.dart';
import '../../tokens/app_spacing.dart';
import '../../tokens/app_typography.dart';

/// Apple-style search field supporting auto-focus, clear button,
/// keyboard focus state, glowing focus ring, and native Cupertino interactions.
class AppSearchField extends StatefulWidget {
  const AppSearchField({
    super.key,
    this.controller,
    this.placeholder = 'Search clients...',
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.autofocus = false,
    this.focusNode,
  });

  final TextEditingController? controller;
  final String placeholder;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;
  final bool autofocus;
  final FocusNode? focusNode;

  @override
  State<AppSearchField> createState() => _AppSearchFieldState();
}

class _AppSearchFieldState extends State<AppSearchField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  bool _hasText = false;
  bool _isFocused = false;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _focusNode = widget.focusNode ?? FocusNode();

    _hasText = _controller.text.isNotEmpty;
    _controller.addListener(_handleTextChange);
    _focusNode.addListener(_handleFocusChange);
  }

  void _handleTextChange() {
    final hasText = _controller.text.isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
  }

  void _handleFocusChange() {
    if (_focusNode.hasFocus != _isFocused) {
      setState(() => _isFocused = _focusNode.hasFocus);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_handleTextChange);
    _focusNode.removeListener(_handleFocusChange);
    if (widget.controller == null) {
      _controller.dispose();
    }
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _clear() {
    _controller.clear();
    widget.onChanged?.call('');
    widget.onClear?.call();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.maybeBrightnessOf(context) == Brightness.dark;

    final backgroundColor = isDark
        ? (_isFocused ? const Color(0xFF242426) : const Color(0xFF1C1C1E))
        : (_isFocused ? CupertinoColors.white : const Color(0xFFE5E5EA));

    final borderColor = _isFocused
        ? AppColors.primaryAccent(context)
        : (_isHovered
              ? AppColors.border(context)
              : (isDark
                    ? AppColors.borderDark.withValues(alpha: 0.3)
                    : CupertinoColors.transparent));

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: AppDurations.quick,
        curve: Curves.easeOutCubic,
        height: 38.0,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: AppRadii.smRadius,
          border: Border.all(color: borderColor, width: _isFocused ? 1.5 : 1.0),
          boxShadow: _isFocused
              ? [
                  BoxShadow(
                    color: AppColors.primaryAccent(
                      context,
                    ).withValues(alpha: 0.16),
                    blurRadius: 8.0,
                    spreadRadius: 1.0,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs + 2),
        child: Row(
          children: [
            Icon(
              CupertinoIcons.search,
              size: 17.0,
              color: _isFocused
                  ? AppColors.primaryAccent(context)
                  : AppColors.textSecondary(context),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: CupertinoTextField(
                controller: _controller,
                focusNode: _focusNode,
                autofocus: widget.autofocus,
                placeholder: widget.placeholder,
                placeholderStyle: AppTypography.subheadline.copyWith(
                  color: AppColors.textTertiary(context),
                ),
                style: AppTypography.subheadline.copyWith(
                  color: AppColors.textPrimary(context),
                ),
                decoration: null,
                padding: EdgeInsets.zero,
                cursorColor: AppColors.primaryAccent(context),
                textInputAction: TextInputAction.search,
                onChanged: widget.onChanged,
                onSubmitted: widget.onSubmitted,
              ),
            ),
            if (_hasText)
              CupertinoButton(
                padding: EdgeInsets.zero,
                minimumSize: const Size(28, 28),
                onPressed: _clear,
                child: Icon(
                  CupertinoIcons.clear_thick_circled,
                  size: 17.0,
                  color: AppColors.textTertiary(context),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
