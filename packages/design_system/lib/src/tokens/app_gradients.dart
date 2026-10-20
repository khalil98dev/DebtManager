import 'package:flutter/cupertino.dart';

/// Design tokens for modern gradients, glassmorphism surfaces, and button fills.
abstract final class AppGradients {
  // --- Brand & Action Gradients ---
  static const LinearGradient primaryLight = LinearGradient(
    colors: [Color(0xFF007AFF), Color(0xFF0051D4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient primaryDark = LinearGradient(
    colors: [Color(0xFF0A84FF), Color(0xFF0062E0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient indigoViolet = LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cyanBlue = LinearGradient(
    colors: [Color(0xFF06B6D4), Color(0xFF0284C7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // --- Semantic Financial Gradients ---
  static const LinearGradient successLight = LinearGradient(
    colors: [Color(0xFF34C759), Color(0xFF248A3D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successDark = LinearGradient(
    colors: [Color(0xFF30D158), Color(0xFF208B3A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient destructiveLight = LinearGradient(
    colors: [Color(0xFFFF3B30), Color(0xFFD70015)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient destructiveDark = LinearGradient(
    colors: [Color(0xFFFF453A), Color(0xFFFF2D55)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warningLight = LinearGradient(
    colors: [Color(0xFFFF9500), Color(0xFFD97706)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warningDark = LinearGradient(
    colors: [Color(0xFFFF9F0A), Color(0xFFEA580C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // --- Glass & Surface Gradients ---
  static const LinearGradient glassLight = LinearGradient(
    colors: [Color(0xF2FFFFFF), Color(0xE6F8FAFC)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient glassDark = LinearGradient(
    colors: [Color(0xF0242730), Color(0xE6181A20)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient cardBorderHighlight = LinearGradient(
    colors: [Color(0x33FFFFFF), Color(0x05FFFFFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // --- Dynamic Theme Helpers ---
  static LinearGradient primary(BuildContext context) =>
      _isDark(context) ? primaryDark : primaryLight;

  static LinearGradient success(BuildContext context) =>
      _isDark(context) ? successDark : successLight;

  static LinearGradient destructive(BuildContext context) =>
      _isDark(context) ? destructiveDark : destructiveLight;

  static LinearGradient warning(BuildContext context) =>
      _isDark(context) ? warningDark : warningLight;

  static LinearGradient glassSurface(BuildContext context) =>
      _isDark(context) ? glassDark : glassLight;

  static LinearGradient metricSurface(
    BuildContext context, {
    Color? tintColor,
  }) {
    final isDark = _isDark(context);
    if (tintColor != null) {
      return LinearGradient(
        colors: [
          tintColor.withValues(alpha: isDark ? 0.16 : 0.08),
          tintColor.withValues(alpha: isDark ? 0.05 : 0.02),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
    return LinearGradient(
      colors: [
        isDark ? const Color(0xFF1E2024) : const Color(0xFFFFFFFF),
        isDark ? const Color(0xFF16181C) : const Color(0xFFF9FAFB),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  // --- Deterministic Palette for Initials / Avatars / Badges ---
  static const List<LinearGradient> avatarPalette = [
    LinearGradient(
      colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)], // Blue
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    LinearGradient(
      colors: [Color(0xFF10B981), Color(0xFF047857)], // Emerald
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    LinearGradient(
      colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)], // Purple
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    LinearGradient(
      colors: [Color(0xFFF59E0B), Color(0xFFD97706)], // Amber
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    LinearGradient(
      colors: [Color(0xFFEC4899), Color(0xFFBE185D)], // Rose
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    LinearGradient(
      colors: [Color(0xFF06B6D4), Color(0xFF0E7490)], // Cyan
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ];

  static LinearGradient avatarFor(String seed) {
    if (seed.isEmpty) return avatarPalette.first;
    final code = seed.codeUnits.fold(0, (acc, c) => acc + c);
    return avatarPalette[code % avatarPalette.length];
  }

  static bool _isDark(BuildContext context) {
    final brightness =
        CupertinoTheme.maybeBrightnessOf(context) ??
        MediaQuery.maybePlatformBrightnessOf(context) ??
        Brightness.light;
    return brightness == Brightness.dark;
  }
}
