import 'package:flutter/widgets.dart';

/// Centralized animation and transition tokens aligned with Apple Human Interface Guidelines.
/// Tuned for fluid, responsive, and noticeably smooth visual transitions.
abstract final class AppDurations {
  /// 160ms: micro-interactions, press feedback, tactile bounce, hover illumination.
  static const Duration micro = Duration(milliseconds: 160);

  /// 180ms: quick tactile reactions and responsive icon states.
  static const Duration quick = Duration(milliseconds: 180);

  /// 260ms: item selection changes, card border highlights, and checkbox/radio toggles.
  static const Duration selection = Duration(milliseconds: 260);

  /// 320ms: section content changes, tab switches, and split-view detail cross-fades.
  static const Duration content = Duration(milliseconds: 320);

  /// 300ms: accordion expand and collapse disclosure transitions.
  static const Duration expand = Duration(milliseconds: 300);

  /// 300ms: standard UI transitions and state morphs.
  static const Duration standard = Duration(milliseconds: 300);

  /// 350ms: screen and route push/pop transitions.
  static const Duration screen = Duration(milliseconds: 350);

  /// 350ms: modal presentations and backdrop blur transitions.
  static const Duration modal = Duration(milliseconds: 350);

  /// 450ms: major emphasized transitions, sheet presentations, hero morphs.
  static const Duration emphasized = Duration(milliseconds: 450);

  // --- Animation Curves ---

  /// Primary decelerating curve: natural, responsive Apple-style smooth motion.
  static const Curve easeOut = Curves.easeOutCubic;

  /// High-order deceleration curve for luxuriously smooth finishes.
  static const Curve easeOutQuart = Curves.easeOutQuart;

  /// Primary accelerating reverse curve: clean, crisp exit transitions.
  static const Curve easeIn = Curves.easeInCubic;

  /// Smooth deceleration curve for subtle slide transitions.
  static const Curve smoothEaseOut = Curves.easeOutCubic;

  /// Standard ease in-out curve for symmetrical loops or reciprocal morphs.
  static const Curve standardCurve = Curves.easeInOutCubic;

  /// Emphasized deceleration curve for sheet presentations.
  static const Curve emphasizedCurve = Curves.fastEaseInToSlowEaseOut;

  /// Subtle tactile spring bounce curve for button releases and dialog pops.
  static const Curve springBounce = Curves.easeOutBack;

  // --- Reduced Motion Accessibility Helpers ---

  /// Determines whether the user has requested reduced motion through system accessibility settings.
  static bool isReducedMotion(BuildContext context) {
    return MediaQuery.maybeOf(context)?.disableAnimations ?? false;
  }

  /// Returns [Duration.zero] if the user has requested reduced motion;
  /// otherwise returns the requested [duration].
  static Duration motionDuration(BuildContext context, Duration duration) {
    return isReducedMotion(context) ? Duration.zero : duration;
  }
}
