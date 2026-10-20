import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Tooltip;
import 'package:flutter/services.dart';

import '../../tokens/app_colors.dart';
import '../../tokens/app_durations.dart';
import '../../tokens/app_radii.dart';
import '../../tokens/app_spacing.dart';

/// An Apple-inspired circular or squircle icon button with tactile feedback,
/// gradient fill option, hover illumination, and smooth scale transitions.
class AppIconButton extends StatefulWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.semanticLabel,
    this.size = 36.0,
    this.iconSize = 18.0,
    this.color,
    this.backgroundColor,
    this.gradient,
    this.isCircle = true,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final String? semanticLabel;
  final double size;
  final double iconSize;
  final Color? color;
  final Color? backgroundColor;
  final Gradient? gradient;
  final bool isCircle;

  @override
  State<AppIconButton> createState() => _AppIconButtonState();
}

class _AppIconButtonState extends State<AppIconButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.onPressed != null;
    final effectiveColor = widget.gradient != null
        ? CupertinoColors.white
        : (_isHovered && isEnabled
              ? AppColors.primaryAccent(context)
              : (widget.color ?? AppColors.textPrimary(context)));

    final effectiveBackground =
        widget.backgroundColor ??
        (_isHovered && isEnabled
            ? AppColors.hover(context)
            : CupertinoColors.transparent);

    final scale = isEnabled
        ? (_isPressed ? 0.92 : (_isHovered ? 1.06 : 1.0))
        : 1.0;

    final shadow = widget.gradient != null && isEnabled
        ? [
            BoxShadow(
              color: AppColors.primaryAccent(
                context,
              ).withValues(alpha: _isHovered ? 0.40 : 0.22),
              blurRadius: _isHovered ? 12 : 6,
              offset: const Offset(0, 2),
            ),
          ]
        : null;

    final border = widget.gradient != null
        ? Border.all(
            color: CupertinoColors.white.withValues(alpha: 0.24),
            width: 0.8,
          )
        : (_isHovered && isEnabled && widget.backgroundColor == null
              ? Border.all(
                  color: AppColors.border(context).withValues(alpha: 0.5),
                  width: 0.8,
                )
              : null);

    Widget button = MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() {
        _isHovered = false;
        _isPressed = false;
      }),
      cursor: isEnabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTapDown: isEnabled
            ? (_) {
                setState(() => _isPressed = true);
                HapticFeedback.lightImpact();
              }
            : null,
        onTapUp: isEnabled ? (_) => setState(() => _isPressed = false) : null,
        onTapCancel: isEnabled
            ? () => setState(() => _isPressed = false)
            : null,
        child: AnimatedScale(
          scale: scale,
          duration: AppDurations.motionDuration(context, AppDurations.micro),
          curve: _isPressed ? AppDurations.easeOut : AppDurations.springBounce,
          child: AnimatedContainer(
            duration: AppDurations.motionDuration(context, AppDurations.quick),
            curve: AppDurations.easeOut,
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: widget.isCircle ? BoxShape.circle : BoxShape.rectangle,
              borderRadius: widget.isCircle ? null : AppRadii.smRadius,
              color: widget.gradient == null ? effectiveBackground : null,
              gradient: widget.gradient,
              boxShadow: shadow,
              border: border,
            ),
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              pressedOpacity: 0.75,
              onPressed: widget.onPressed,
              minimumSize: const Size(
                AppSpacing.minTouchTarget,
                AppSpacing.minTouchTarget,
              ),
              child: Icon(
                widget.icon,
                size: widget.iconSize,
                color: isEnabled
                    ? effectiveColor
                    : AppColors.textQuaternary(context),
              ),
            ),
          ),
        ),
      ),
    );

    if (widget.tooltip != null) {
      button = Tooltip(message: widget.tooltip!, child: button);
    }

    return Semantics(
      button: true,
      enabled: isEnabled,
      label: widget.semanticLabel ?? widget.tooltip,
      child: button,
    );
  }
}
