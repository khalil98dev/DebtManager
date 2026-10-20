import 'package:flutter/widgets.dart';

/// 8-point spatial system specifications.
///
/// Ensures consistent rhythm across all views, controls, and containers.
abstract final class AppSpacing {
  /// 4px: micro spacing, icon-to-text gap, compact badge padding.
  static const double xxs = 4.0;

  /// 8px: tight spacing, gap between title and subtitle.
  static const double xs = 8.0;

  /// 12px: compact list card padding, secondary gaps.
  static const double sm = 12.0;

  /// 16px: standard horizontal screen margins, standard card padding.
  static const double md = 16.0;

  /// 24px: section spacing, gap between distinct semantic groups.
  static const double lg = 24.0;

  /// 32px: major screen headers, empty state hero offsets.
  static const double xl = 32.0;

  /// 48px: major hero banners, desktop layout sections.
  static const double xxl = 48.0;

  // --- Touch Target Sizes ---
  /// Minimum touch target size recommended by Apple Human Interface Guidelines.
  static const double minTouchTarget = 44.0;

  /// Standard desktop row / list item comfortable height.
  static const double desktopRowHeight = 52.0;

  /// Standard mobile list row comfortable height.
  static const double mobileRowHeight = 56.0;

  // --- Standard Inset Helpers ---
  static const EdgeInsets screenMobile = EdgeInsets.symmetric(
    horizontal: md,
    vertical: sm,
  );

  static const EdgeInsets screenDesktop = EdgeInsets.symmetric(
    horizontal: lg,
    vertical: lg,
  );

  static const EdgeInsets card = EdgeInsets.all(md);
  static const EdgeInsets cardCompact = EdgeInsets.all(sm);

  static const EdgeInsets button = EdgeInsets.symmetric(
    horizontal: md,
    vertical: sm,
  );

  static const EdgeInsets badge = EdgeInsets.symmetric(
    horizontal: xs,
    vertical: xxs,
  );
}
