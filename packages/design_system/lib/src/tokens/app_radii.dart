import 'package:flutter/widgets.dart';

/// Corner radius tokens reflecting Apple's continuous rounded styling.
abstract final class AppRadii {
  /// 6px: micro tags, compact chips.
  static const double xs = 6.0;

  /// 10px: text fields, buttons, search bars.
  static const double sm = 10.0;

  /// 14px: standard cards, list group containers.
  static const double md = 14.0;

  /// 18px: modal sheets, desktop popovers, dialogs.
  static const double lg = 18.0;

  /// 999px: fully rounded pills and status badges.
  static const double pill = 999.0;

  // --- Precomputed BorderRadius Constants ---
  static const BorderRadius xsRadius = BorderRadius.all(Radius.circular(xs));
  static const BorderRadius smRadius = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdRadius = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgRadius = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius pillRadius = BorderRadius.all(
    Radius.circular(pill),
  );
}
