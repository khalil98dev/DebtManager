import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../../tokens/app_colors.dart';
import '../../tokens/app_durations.dart';
import '../../tokens/app_gradients.dart';
import '../../tokens/app_radii.dart';
import '../../tokens/app_spacing.dart';
import '../../tokens/app_typography.dart';

enum AppButtonVariant { primary, secondary, tinted, destructive, plain }

enum AppButtonSize {
  compact(36.0, AppSpacing.sm, 13.0),
  regular(44.0, AppSpacing.md, 15.0),
  large(50.0, AppSpacing.lg, 17.0);

  const AppButtonSize(this.height, this.horizontalPadding, this.fontSize);
  final double height;
  final double horizontalPadding;
  final double fontSize;
}

/// Cupertino-inspired button with tactile feedback, gradient support,
/// loading spinner transitions, and smooth hover/press animations.
class AppButton extends StatefulWidget {
  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.regular,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.semanticLabel,
    this.gradient,
    this.useGradient = true,
  });

  final String text;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final Widget? icon;
  final bool isLoading;
  final bool isFullWidth;
  final String? semanticLabel;
  final Gradient? gradient;
  final bool useGradient;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  bool get _isEnabled => widget.onPressed != null && !widget.isLoading;

  @override
  Widget build(BuildContext context) {
    final colors = _resolveColors(context);
    final effectiveGradient = _resolveGradient(context);

    final scale = _isEnabled
        ? (_isPressed ? 0.96 : (_isHovered ? 1.02 : 1.0))
        : 1.0;

    final glowColor = effectiveGradient is LinearGradient
        ? effectiveGradient.colors.first
        : colors.backgroundColor;

    final showShadow =
        _isEnabled &&
        (widget.variant == AppButtonVariant.primary ||
            widget.variant == AppButtonVariant.destructive ||
            widget.gradient != null ||
            (widget.variant == AppButtonVariant.secondary && _isHovered)) &&
        widget.variant != AppButtonVariant.plain;

    final shadowList = showShadow
        ? [
            if (widget.variant == AppButtonVariant.secondary)
              BoxShadow(
                color: CupertinoColors.black.withValues(alpha: 0.05),
                blurRadius: 4.0,
                offset: const Offset(0, 1.5),
              )
            else
              BoxShadow(
                color: glowColor.withValues(alpha: _isHovered ? 0.38 : 0.22),
                blurRadius: _isHovered ? 14.0 : 8.0,
                offset: Offset(0, _isHovered ? 4.0 : 2.5),
              ),
          ]
        : null;

    Widget content = Row(
      mainAxisSize: widget.isFullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.isLoading) ...[
          CupertinoActivityIndicator(
            radius: widget.size == AppButtonSize.compact ? 8 : 10,
            color: colors.textColor,
          ),
          const SizedBox(width: AppSpacing.xs),
        ] else if (widget.icon != null) ...[
          IconTheme(
            data: IconThemeData(
              size: widget.size.fontSize + 2,
              color: colors.textColor,
            ),
            child: widget.icon!,
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
        Flexible(
          child: Text(
            widget.text,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.headline.copyWith(
              fontSize: widget.size.fontSize,
              fontWeight: FontWeight.w600,
              color: colors.textColor,
            ),
          ),
        ),
      ],
    );

    if (widget.isFullWidth) {
      content = SizedBox(width: double.infinity, child: content);
    }

    final buttonBox = AnimatedContainer(
      duration: AppDurations.motionDuration(context, AppDurations.quick),
      curve: AppDurations.easeOut,
      height: widget.size.height,
      decoration: BoxDecoration(
        color: effectiveGradient == null ? colors.backgroundColor : null,
        gradient: effectiveGradient,
        borderRadius: AppRadii.smRadius,
        border: colors.borderColor != null
            ? Border.all(color: colors.borderColor!, width: 1.0)
            : (effectiveGradient != null
                  ? Border.all(
                      color: CupertinoColors.white.withValues(alpha: 0.24),
                      width: 0.8,
                    )
                  : null),
        boxShadow: shadowList,
      ),
      child: CupertinoButton(
        padding: EdgeInsets.symmetric(
          horizontal: widget.size.horizontalPadding,
        ),
        pressedOpacity: 0.85,
        borderRadius: AppRadii.smRadius,
        onPressed: _isEnabled ? widget.onPressed : null,
        child: content,
      ),
    );

    return Semantics(
      button: true,
      enabled: _isEnabled,
      label: widget.semanticLabel ?? widget.text,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() {
          _isHovered = false;
          _isPressed = false;
        }),
        cursor: _isEnabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        child: GestureDetector(
          onTapDown: _isEnabled
              ? (_) {
                  setState(() => _isPressed = true);
                  HapticFeedback.lightImpact();
                }
              : null,
          onTapUp: _isEnabled
              ? (_) => setState(() => _isPressed = false)
              : null,
          onTapCancel: _isEnabled
              ? () => setState(() => _isPressed = false)
              : null,
          child: AnimatedScale(
            scale: scale,
            duration: AppDurations.motionDuration(context, AppDurations.micro),
            curve: _isPressed ? AppDurations.easeOut : AppDurations.springBounce,
            child: AnimatedOpacity(
              opacity: _isEnabled ? 1.0 : 0.5,
              duration: AppDurations.motionDuration(
                context,
                AppDurations.quick,
              ),
              child: buttonBox,
            ),
          ),
        ),
      ),
    );
  }

  Gradient? _resolveGradient(BuildContext context) {
    if (widget.gradient != null) return widget.gradient;
    if (!widget.useGradient) return null;

    switch (widget.variant) {
      case AppButtonVariant.primary:
        return AppGradients.primary(context);
      case AppButtonVariant.destructive:
        return AppGradients.destructive(context);
      default:
        return null;
    }
  }

  _ButtonColors _resolveColors(BuildContext context) {
    final isDark = CupertinoTheme.maybeBrightnessOf(context) == Brightness.dark;

    switch (widget.variant) {
      case AppButtonVariant.primary:
        return _ButtonColors(
          backgroundColor: AppColors.primaryAccent(context),
          textColor: CupertinoColors.white,
        );

      case AppButtonVariant.secondary:
        final bg = isDark
            ? (_isHovered ? const Color(0xFF323236) : const Color(0xFF242426))
            : (_isHovered ? const Color(0xFFE8E8ED) : const Color(0xFFF2F2F7));
        final border = isDark
            ? (_isHovered ? const Color(0xFF48484C) : const Color(0xFF38383A))
            : (_isHovered ? const Color(0xFFD1D1D6) : const Color(0xFFE5E5EA));

        return _ButtonColors(
          backgroundColor: bg,
          textColor: AppColors.textPrimary(context),
          borderColor: border,
        );

      case AppButtonVariant.tinted:
        final bg = isDark
            ? (_isHovered ? const Color(0x4D0A84FF) : const Color(0x2E0A84FF))
            : (_isHovered ? const Color(0x33007AFF) : const Color(0x1A007AFF));
        final border = AppColors.primaryAccent(
          context,
        ).withValues(alpha: isDark ? 0.35 : 0.22);

        return _ButtonColors(
          backgroundColor: bg,
          textColor: AppColors.primaryAccent(context),
          borderColor: border,
        );

      case AppButtonVariant.destructive:
        if (widget.useGradient) {
          return const _ButtonColors(
            backgroundColor: Color(0xFFFF3B30),
            textColor: CupertinoColors.white,
          );
        }
        return _ButtonColors(
          backgroundColor: isDark
              ? const Color(0x33FF453A)
              : const Color(0x1FFF3B30),
          textColor: isDark
              ? AppColors.destructiveDark
              : AppColors.destructiveLight,
          borderColor: AppColors.destructive(context).withValues(alpha: 0.30),
        );

      case AppButtonVariant.plain:
        return _ButtonColors(
          backgroundColor: _isHovered
              ? AppColors.hover(context)
              : CupertinoColors.transparent,
          textColor: AppColors.primaryAccent(context),
        );
    }
  }
}

class _ButtonColors {
  const _ButtonColors({
    required this.backgroundColor,
    required this.textColor,
    this.borderColor,
  });

  final Color backgroundColor;
  final Color textColor;
  final Color? borderColor;
}
