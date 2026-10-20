import 'package:flutter/cupertino.dart';

import '../../tokens/app_colors.dart';
import '../../tokens/app_durations.dart';
import '../../tokens/app_radii.dart';
import '../../tokens/app_spacing.dart';

/// An Apple-inspired container for selectable items (such as list rows,
/// table cells, cards, and chips) that smoothly animates selection,
/// hover illumination, and press states.
///
/// Features:
/// - Smooth animated background color, border color, and optional accent bar.
/// - Tactile micro-scale feedback on press.
/// - Zero layout shifts (fixed geometry padding).
/// - Full compliance with reduced-motion preferences.
class AnimatedSelectionContainer extends StatefulWidget {
  const AnimatedSelectionContainer({
    super.key,
    required this.child,
    this.isSelected = false,
    this.onTap,
    this.onLongPress,
    this.padding = const EdgeInsets.symmetric(
      horizontal: AppSpacing.md,
      vertical: AppSpacing.sm,
    ),
    this.margin,
    this.borderRadius = AppRadii.smRadius,
    this.selectedBackgroundColor,
    this.unselectedBackgroundColor,
    this.hoverBackgroundColor,
    this.selectedBorderColor,
    this.unselectedBorderColor,
    this.borderWidth = 1.0,
    this.selectedBorderWidth = 1.0,
    this.showLeadingIndicator = false,
    this.indicatorColor,
    this.indicatorWidth = 3.5,
    this.indicatorHeight = 16.0,
    this.enablePressScale = false,
    this.duration = AppDurations.selection,
    this.curve = AppDurations.easeOut,
  });

  final Widget child;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius borderRadius;
  final Color? selectedBackgroundColor;
  final Color? unselectedBackgroundColor;
  final Color? hoverBackgroundColor;
  final Color? selectedBorderColor;
  final Color? unselectedBorderColor;
  final double borderWidth;
  final double selectedBorderWidth;
  final bool showLeadingIndicator;
  final Color? indicatorColor;
  final double indicatorWidth;
  final double indicatorHeight;
  final bool enablePressScale;
  final Duration duration;
  final Curve curve;

  @override
  State<AnimatedSelectionContainer> createState() =>
      _AnimatedSelectionContainerState();
}

class _AnimatedSelectionContainerState
    extends State<AnimatedSelectionContainer> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final effectiveDuration = AppDurations.motionDuration(
      context,
      widget.duration,
    );
    final isInteractive = widget.onTap != null || widget.onLongPress != null;

    final defaultSelectedBg = AppColors.primaryAccent(
      context,
    ).withValues(alpha: 0.08);
    final defaultHoverBg = AppColors.hover(context);
    final defaultUnselectedBg = CupertinoColors.transparent;

    final effectiveBg = widget.isSelected
        ? (widget.selectedBackgroundColor ?? defaultSelectedBg)
        : (_isHovered && isInteractive
              ? (widget.hoverBackgroundColor ?? defaultHoverBg)
              : (widget.unselectedBackgroundColor ?? defaultUnselectedBg));

    final effectiveBorderColor = widget.isSelected
        ? (widget.selectedBorderColor ?? AppColors.primaryAccent(context))
        : (_isHovered && isInteractive
              ? AppColors.border(context)
              : (widget.unselectedBorderColor ?? CupertinoColors.transparent));

    final effectiveBorderWidth = widget.isSelected
        ? widget.selectedBorderWidth
        : widget.borderWidth;

    final effectiveIndicatorColor =
        widget.indicatorColor ?? AppColors.primaryAccent(context);

    final scale = (widget.enablePressScale && _isPressed && isInteractive)
        ? 0.985
        : 1.0;

    Widget container = AnimatedContainer(
      duration: effectiveDuration,
      curve: widget.curve,
      margin: widget.margin,
      padding: widget.padding,
      decoration: BoxDecoration(
        color: effectiveBg,
        borderRadius: widget.borderRadius,
        border: Border.all(
          color: effectiveBorderColor,
          width: effectiveBorderWidth,
        ),
      ),
      child: Row(
        children: [
          if (widget.showLeadingIndicator) ...[
            AnimatedContainer(
              duration: effectiveDuration,
              curve: widget.curve,
              width: widget.isSelected ? widget.indicatorWidth : 0.0,
              height: widget.indicatorHeight,
              margin: EdgeInsets.only(
                right: widget.isSelected ? AppSpacing.xs : 0.0,
              ),
              decoration: BoxDecoration(
                color: effectiveIndicatorColor,
                borderRadius: AppRadii.pillRadius,
              ),
            ),
          ],
          Expanded(child: widget.child),
        ],
      ),
    );

    if (widget.enablePressScale) {
      container = AnimatedScale(
        scale: scale,
        duration: AppDurations.motionDuration(context, AppDurations.micro),
        curve: AppDurations.easeOut,
        child: container,
      );
    }

    if (!isInteractive) {
      return container;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() {
        _isHovered = false;
        _isPressed = false;
      }),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        behavior: HitTestBehavior.opaque,
        child: container,
      ),
    );
  }
}
