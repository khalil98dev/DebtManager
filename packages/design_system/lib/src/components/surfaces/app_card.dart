import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../../tokens/app_colors.dart';
import '../../tokens/app_durations.dart';
import '../../tokens/app_radii.dart';
import '../../tokens/app_spacing.dart';

/// De-boxed card surface adhering to UI-Skills:
/// - Light mode: subtle 1px border + soft ambient shadow (`0 2px 8px rgba(0,0,0,0.03)`).
/// - Dark mode: progressive surface lightening with subtle rim light (`rgba(255,255,255,0.09)`), no black shadows.
/// - Interactive cards include spring-physics press scale (0.98) and light tactile haptics.
class AppCard extends StatefulWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = AppSpacing.card,
    this.margin,
    this.onTap,
    this.isSelected = false,
    this.borderRadius = AppRadii.mdRadius,
    this.backgroundColor,
    this.translucent = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final bool isSelected;
  final BorderRadius borderRadius;
  final Color? backgroundColor;
  final bool translucent;

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.maybeBrightnessOf(context) == Brightness.dark;
    final isInteractive = widget.onTap != null;

    final rawBaseColor = widget.backgroundColor ?? AppColors.surface(context);
    final baseColor = (widget.backgroundColor == null && widget.translucent)
        ? rawBaseColor.withValues(alpha: isDark ? 0.86 : 0.90)
        : rawBaseColor;

    final borderColor = widget.isSelected
        ? AppColors.primaryAccent(context)
        : (_isHovered && isInteractive
              ? AppColors.primaryAccent(context).withValues(alpha: 0.35)
              : (isDark
                    ? CupertinoColors.white.withValues(alpha: 0.09)
                    : AppColors.border(context)));

    final ambientShadows = isDark
        ? null
        : [
            BoxShadow(
              color: CupertinoColors.black.withValues(
                alpha: _isHovered && isInteractive ? 0.05 : 0.03,
              ),
              blurRadius: _isHovered && isInteractive ? 14.0 : 8.0,
              offset: Offset(0, _isHovered && isInteractive ? 4.0 : 2.0),
            ),
          ];

    final scale = isInteractive
        ? (_isPressed ? 0.98 : (_isHovered ? 1.005 : 1.0))
        : 1.0;

    Widget card = AnimatedContainer(
      duration: AppDurations.motionDuration(context, AppDurations.selection),
      curve: AppDurations.easeOut,
      margin: widget.margin,
      padding: widget.padding,
      decoration: BoxDecoration(
        color: _isHovered && isInteractive
            ? Color.alphaBlend(AppColors.hover(context), baseColor)
            : baseColor,
        borderRadius: widget.borderRadius,
        border: Border.all(
          color: borderColor,
          width: widget.isSelected ? 1.5 : 1.0,
        ),
        boxShadow: ambientShadows,
      ),
      child: widget.child,
    );

    if (isInteractive) {
      card = MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() {
          _isHovered = false;
          _isPressed = false;
        }),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTapDown: (_) {
            setState(() => _isPressed = true);
            HapticFeedback.lightImpact();
          },
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          onTap: widget.onTap,
          behavior: HitTestBehavior.opaque,
          child: AnimatedScale(
            scale: scale,
            duration: AppDurations.motionDuration(context, AppDurations.micro),
            curve: _isPressed ? AppDurations.easeOut : AppDurations.springBounce,
            child: card,
          ),
        ),
      );
    }

    return card;
  }
}
