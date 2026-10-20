import 'package:flutter/cupertino.dart';

import '../../tokens/app_colors.dart';
import '../../tokens/app_durations.dart';
import '../../tokens/app_radii.dart';
import '../../tokens/app_spacing.dart';
import '../../tokens/app_typography.dart';

/// An Apple-inspired expandable disclosure container for collapsible invoice details,
/// line items, payment breakdowns, and settings sections.
///
/// Features:
/// - Smooth vertical size expansion and fade transition.
/// - Synchronized rotating disclosure chevron.
/// - Proper AnimationController lifecycle management and disposal.
/// - Full compliance with reduced-motion preferences.
class AppExpandableSection extends StatefulWidget {
  const AppExpandableSection({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.leading,
    this.trailing,
    this.initiallyExpanded = false,
    this.onExpansionChanged,
    this.duration = AppDurations.expand,
    this.curve = AppDurations.easeOut,
    this.backgroundColor,
    this.borderRadius = AppRadii.mdRadius,
    this.showBorder = true,
  });

  final String title;
  final Widget child;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final bool initiallyExpanded;
  final ValueChanged<bool>? onExpansionChanged;
  final Duration duration;
  final Curve curve;
  final Color? backgroundColor;
  final BorderRadius borderRadius;
  final bool showBorder;

  @override
  State<AppExpandableSection> createState() => _AppExpandableSectionState();
}

class _AppExpandableSectionState extends State<AppExpandableSection>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _heightFactor;
  late final Animation<double> _chevronTurns;
  late final Animation<double> _opacity;
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
      value: _isExpanded ? 1.0 : 0.0,
    );

    final curved = CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
      reverseCurve: AppDurations.easeIn,
    );

    _heightFactor = curved;
    _chevronTurns = Tween<double>(begin: 0.0, end: 0.5).animate(curved);
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
      ),
    );
  }

  @override
  void didUpdateWidget(AppExpandableSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.duration != oldWidget.duration) {
      _controller.duration = widget.duration;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpansion() {
    final isReduced = AppDurations.isReducedMotion(context);
    setState(() {
      _isExpanded = !_isExpanded;
      if (isReduced) {
        _controller.value = _isExpanded ? 1.0 : 0.0;
      } else {
        if (_isExpanded) {
          _controller.forward();
        } else {
          _controller.reverse();
        }
      }
      widget.onExpansionChanged?.call(_isExpanded);
    });
  }

  @override
  Widget build(BuildContext context) {
    final effectiveBg = widget.backgroundColor ?? AppColors.surface(context);
    final borderColor = AppColors.border(context).withValues(alpha: 0.6);

    return Container(
      decoration: BoxDecoration(
        color: effectiveBg,
        borderRadius: widget.borderRadius,
        border: widget.showBorder
            ? Border.all(color: borderColor, width: 0.8)
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header disclosure button
          CupertinoButton(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm + 2,
            ),
            onPressed: _toggleExpansion,
            child: Row(
              children: [
                if (widget.leading != null) ...[
                  widget.leading!,
                  const SizedBox(width: AppSpacing.sm),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.title,
                        style: AppTypography.headline.copyWith(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary(context),
                        ),
                      ),
                      if (widget.subtitle != null) ...[
                        const SizedBox(height: 2.0),
                        Text(
                          widget.subtitle!,
                          style: AppTypography.caption1.copyWith(
                            color: AppColors.textSecondary(context),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (widget.trailing != null) ...[
                  widget.trailing!,
                  const SizedBox(width: AppSpacing.xs),
                ],
                RotationTransition(
                  turns: _chevronTurns,
                  child: Icon(
                    CupertinoIcons.chevron_down,
                    size: 15.0,
                    color: AppColors.textTertiary(context),
                  ),
                ),
              ],
            ),
          ),

          // Collapsible expandable body
          ClipRect(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Align(
                  alignment: Alignment.topCenter,
                  heightFactor: _heightFactor.value,
                  child: FadeTransition(opacity: _opacity, child: child),
                );
              },
              child: widget.child,
            ),
          ),
        ],
      ),
    );
  }
}
