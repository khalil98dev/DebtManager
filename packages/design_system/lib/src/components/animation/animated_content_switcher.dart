import 'package:flutter/cupertino.dart';

import '../../tokens/app_durations.dart';

/// Transition style for [AnimatedContentSwitcher].
enum ContentTransitionType {
  /// Pure Apple cross-fade: fast, subtle, minimal GPU cost. Ideal for lists & large data.
  fade,

  /// Subtle fade paired with a gentle vertical translation (e.g., 6–10 pixels).
  fadeSlideY,

  /// Subtle fade paired with a gentle horizontal translation.
  fadeSlideX,

  /// Subtle fade paired with a 0.98 -> 1.0 micro scale.
  fadeScale,
}

/// A centralized, Apple-inspired content switcher for page changes,
/// tab switching, and state transitions (e.g. loading -> empty -> populated).
///
/// Ensures incoming and outgoing content transitions smoothly without layout flicker,
/// clipping, or layout jumping.
class AnimatedContentSwitcher extends StatelessWidget {
  const AnimatedContentSwitcher({
    super.key,
    required this.child,
    this.transitionType = ContentTransitionType.fade,
    this.duration = AppDurations.content,
    this.reverseDuration,
    this.curve = AppDurations.easeOut,
    this.reverseCurve = AppDurations.easeIn,
    this.slideOffset = 0.015,
    this.alignment = Alignment.topLeft,
  });

  /// The child widget to display. Ensure each distinct view or state
  /// provides a stable [Key] (such as [ValueKey]).
  final Widget child;

  /// The visual style of transition between outgoing and incoming widgets.
  final ContentTransitionType transitionType;

  /// Duration of the transition.
  final Duration duration;

  /// Optional duration for the exit transition. Defaults to [duration].
  final Duration? reverseDuration;

  /// The curve for the forward entrance animation.
  final Curve curve;

  /// The curve for the reverse exit animation.
  final Curve reverseCurve;

  /// Relative offset for slide transitions (defaults to 0.015 = ~1.5% of viewport).
  final double slideOffset;

  /// Alignment within the transition container.
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final effectiveDuration = AppDurations.motionDuration(context, duration);
    final effectiveReverseDuration = reverseDuration != null
        ? AppDurations.motionDuration(context, reverseDuration!)
        : effectiveDuration;

    final isReducedMotion = AppDurations.isReducedMotion(context);

    return AnimatedSwitcher(
      duration: effectiveDuration,
      reverseDuration: effectiveReverseDuration,
      switchInCurve: curve,
      switchOutCurve: reverseCurve,
      layoutBuilder: (currentChild, previousChildren) {
        return Stack(
          alignment: alignment,
          children: [...previousChildren, ?currentChild],
        );
      },
      transitionBuilder: (child, animation) {
        if (isReducedMotion) {
          return child;
        }

        switch (transitionType) {
          case ContentTransitionType.fade:
            return FadeTransition(opacity: animation, child: child);

          case ContentTransitionType.fadeSlideY:
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
              ),
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: Offset(0, slideOffset),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );

          case ContentTransitionType.fadeSlideX:
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
              ),
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: Offset(slideOffset, 0),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );

          case ContentTransitionType.fadeScale:
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.98, end: 1.0).animate(animation),
                child: child,
              ),
            );
        }
      },
      child: child,
    );
  }
}
