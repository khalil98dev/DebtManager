import 'package:flutter/cupertino.dart';

import '../../tokens/app_durations.dart';

/// Centralized route transitions tailored for desktop and mobile form-factors.
///
/// Principles:
/// - Desktop: Restrained, subtle vertical slide and cross-fade. Avoids mobile-style
///   full-width horizontal slide.
/// - Mobile: Native Cupertino slide and swipe-back gesture with subtle elevation.
/// - Accessibility: Instantly snaps to the route when reduced-motion is requested.
class AppPageRoute<T> extends PageRouteBuilder<T> {
  AppPageRoute._({
    required super.pageBuilder,
    required super.transitionsBuilder,
    required super.transitionDuration,
    required super.reverseTransitionDuration,
    super.settings,
    super.fullscreenDialog,
    super.barrierDismissible,
    super.barrierColor,
    super.barrierLabel,
    super.maintainState = true,
  });

  /// Factory creating an Apple macOS-styled subtle desktop route transition.
  /// Uses a restrained fade and gentle 15px vertical translation.
  factory AppPageRoute.desktop({
    required WidgetBuilder builder,
    RouteSettings? settings,
    bool fullscreenDialog = false,
    Duration duration = AppDurations.screen,
  }) {
    return AppPageRoute._(
      settings: settings,
      fullscreenDialog: fullscreenDialog,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      pageBuilder: (context, animation, secondaryAnimation) => builder(context),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        if (AppDurations.isReducedMotion(context)) {
          return child;
        }

        final curved = CurvedAnimation(
          parent: animation,
          curve: AppDurations.easeOut,
          reverseCurve: AppDurations.easeIn,
        );

        final fade = CurvedAnimation(
          parent: animation,
          curve: const Interval(0.0, 0.85, curve: Curves.easeOutCubic),
        );

        return FadeTransition(
          opacity: fade,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.0, 0.015),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  /// Factory creating an iOS-styled Cupertino mobile route transition.
  /// Uses a native horizontal slide with swipe-back capability.
  factory AppPageRoute.mobile({
    required WidgetBuilder builder,
    RouteSettings? settings,
    bool fullscreenDialog = false,
    Duration duration = AppDurations.screen,
  }) {
    return AppPageRoute._(
      settings: settings,
      fullscreenDialog: fullscreenDialog,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      pageBuilder: (context, animation, secondaryAnimation) => builder(context),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        if (AppDurations.isReducedMotion(context)) {
          return child;
        }

        return CupertinoPageTransition(
          primaryRouteAnimation: animation,
          secondaryRouteAnimation: secondaryAnimation,
          linearTransition: false,
          child: child,
        );
      },
    );
  }

  /// Factory creating a pure cross-fade route transition.
  factory AppPageRoute.fade({
    required WidgetBuilder builder,
    RouteSettings? settings,
    bool fullscreenDialog = false,
    Duration duration = AppDurations.content,
  }) {
    return AppPageRoute._(
      settings: settings,
      fullscreenDialog: fullscreenDialog,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      pageBuilder: (context, animation, secondaryAnimation) => builder(context),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        if (AppDurations.isReducedMotion(context)) {
          return child;
        }

        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: AppDurations.easeOut,
            reverseCurve: AppDurations.easeIn,
          ),
          child: child,
        );
      },
    );
  }
}
