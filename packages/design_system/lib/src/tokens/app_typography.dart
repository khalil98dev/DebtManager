import 'package:flutter/widgets.dart';

/// San Francisco typography specifications adhering to Apple Human Interface Guidelines.
/// Includes support for tabular figures for clean vertical alignment of monetary values.
abstract final class AppTypography {
  // --- Scale Styles ---
  static const TextStyle largeTitle = TextStyle(
    fontSize: 34.0,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.37,
    height: 1.2,
  );

  static const TextStyle title1 = TextStyle(
    fontSize: 28.0,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.36,
    height: 1.22,
  );

  static const TextStyle title2 = TextStyle(
    fontSize: 22.0,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.35,
    height: 1.27,
  );

  static const TextStyle title3 = TextStyle(
    fontSize: 20.0,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.38,
    height: 1.3,
  );

  static const TextStyle headline = TextStyle(
    fontSize: 17.0,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.41,
    height: 1.3,
  );

  static const TextStyle body = TextStyle(
    fontSize: 17.0,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.41,
    height: 1.35,
  );

  static const TextStyle callout = TextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.32,
    height: 1.35,
  );

  static const TextStyle subheadline = TextStyle(
    fontSize: 15.0,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.24,
    height: 1.33,
  );

  static const TextStyle footnote = TextStyle(
    fontSize: 13.0,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.08,
    height: 1.38,
  );

  static const TextStyle caption1 = TextStyle(
    fontSize: 12.0,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.0,
    height: 1.33,
  );

  static const TextStyle caption2 = TextStyle(
    fontSize: 11.0,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.06,
    height: 1.27,
  );

  // --- Financial & Numerical Typography ---
  /// Applies tabular figures to ensure numbers align vertically in tables and list rows.
  static TextStyle tabular(TextStyle base) {
    return base.copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
  }
}
