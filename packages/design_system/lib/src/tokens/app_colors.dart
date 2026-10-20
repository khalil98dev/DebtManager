import 'package:flutter/cupertino.dart';

/// Design tokens for colors based on Apple Human Interface Guidelines
/// and the 60-30-10 color restraint rule.
///
/// Designed to provide crisp, high-contrast readability in both Light and Dark modes.
abstract final class AppColors {
  // --- Brand & Primary Accent ---
  static const Color accentLight = Color(0xFF007AFF); // Apple System Blue
  static const Color accentDark = Color(0xFF0A84FF);

  // --- Financial Semantic Statuses ---
  // Emerald Green for paid amounts, positive balance, and client credit
  static const Color successLight = Color(0xFF34C759);
  static const Color successDark = Color(0xFF30D158);
  static const Color successContainerLight = Color(0x1A34C759);
  static const Color successContainerDark = Color(0x2630D158);

  // Crimson Red for overdue invoices, outstanding debt, and destructive actions
  static const Color destructiveLight = Color(0xFFFF3B30);
  static const Color destructiveDark = Color(0xFFFF453A);
  static const Color destructiveContainerLight = Color(0x1AFF3B30);
  static const Color destructiveContainerDark = Color(0x26FF453A);

  // Amber for pending invoices or warnings
  static const Color warningLight = Color(0xFFFF9500);
  static const Color warningDark = Color(0xFFFF9F0A);
  static const Color warningContainerLight = Color(0x1AFF9500);
  static const Color warningContainerDark = Color(0x26FF9F0A);

  // Neutral / Info
  static const Color infoLight = Color(0xFF5856D6);
  static const Color infoDark = Color(0xFF5E5CE6);
  static const Color infoContainerLight = Color(0x1A5856D6);
  static const Color infoContainerDark = Color(0x265E5CE6);

  // --- Dynamic Palette Helpers ---
  static Color primaryAccent(BuildContext context) =>
      _isDark(context) ? accentDark : accentLight;

  static Color success(BuildContext context) =>
      _isDark(context) ? successDark : successLight;

  static Color successContainer(BuildContext context) =>
      _isDark(context) ? successContainerDark : successContainerLight;

  static Color destructive(BuildContext context) =>
      _isDark(context) ? destructiveDark : destructiveLight;

  static Color destructiveContainer(BuildContext context) =>
      _isDark(context) ? destructiveContainerDark : destructiveContainerLight;

  static Color warning(BuildContext context) =>
      _isDark(context) ? warningDark : warningLight;

  static Color warningContainer(BuildContext context) =>
      _isDark(context) ? warningContainerDark : warningContainerLight;

  // --- Surfaces & Canvases ---
  // Canvas background (under grouped lists)
  static const Color canvasLight = Color(0xFFF2F2F7); // iOS Grouped Canvas
  static const Color canvasDark = Color(0xFF000000);

  // Card / Row / Grouped Surface (elevated from canvas)
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1C1C1E); // iOS Elevated Card

  // Secondary elevated surface (e.g. modals, flyouts, nested cards)
  static const Color surfaceSecondaryLight = Color(0xFFF9F9FB);
  static const Color surfaceSecondaryDark = Color(0xFF2C2C2E);

  // macOS / Desktop sidebar surface
  static const Color sidebarLight = Color(0xFFF6F6F6);
  static const Color sidebarDark = Color(0xFF1E1E1E);

  static Color canvas(BuildContext context) =>
      _isDark(context) ? canvasDark : canvasLight;

  static Color surface(BuildContext context) =>
      _isDark(context) ? surfaceDark : surfaceLight;

  static Color surfaceSecondary(BuildContext context) =>
      _isDark(context) ? surfaceSecondaryDark : surfaceSecondaryLight;

  static Color sidebar(BuildContext context) =>
      _isDark(context) ? sidebarDark : sidebarLight;

  // --- Typography Hierarchy ---
  static const Color textPrimaryLight = Color(0xFF000000);
  static const Color textPrimaryDark = Color(0xFFFFFFFF);

  static const Color textSecondaryLight = Color(0x993C3C43); // 60% opacity
  static const Color textSecondaryDark = Color(0x99EBEBF5);

  static const Color textTertiaryLight = Color(0x4D3C3C43); // 30% opacity
  static const Color textTertiaryDark = Color(0x4DEBEBF5);

  static const Color textQuaternaryLight = Color(0x293C3C43); // 16% opacity
  static const Color textQuaternaryDark = Color(0x29EBEBF5);

  static Color textPrimary(BuildContext context) =>
      _isDark(context) ? textPrimaryDark : textPrimaryLight;

  static Color textSecondary(BuildContext context) =>
      _isDark(context) ? textSecondaryDark : textSecondaryLight;

  static Color textTertiary(BuildContext context) =>
      _isDark(context) ? textTertiaryDark : textTertiaryLight;

  static Color textQuaternary(BuildContext context) =>
      _isDark(context) ? textQuaternaryDark : textQuaternaryLight;

  // --- Separators & Hairline Borders ---
  static const Color separatorLight = Color(0x333C3C43); // ~20%
  static const Color separatorDark = Color(0x40545458);

  static const Color borderLight = Color(0x1F000000); // 12% subtle border
  static const Color borderDark = Color(0x26FFFFFF); // 15% subtle border

  static Color separator(BuildContext context) =>
      _isDark(context) ? separatorDark : separatorLight;

  static Color border(BuildContext context) =>
      _isDark(context) ? borderDark : borderLight;

  // --- Interactive States: Hover & Selection ---
  static const Color hoverLight = Color(0x0A000000); // 4%
  static const Color hoverDark = Color(0x12FFFFFF); // 7%

  static const Color selectedLight = Color(0x1A007AFF); // 10%
  static const Color selectedDark = Color(0x2B0A84FF); // 17%

  static Color hover(BuildContext context) =>
      _isDark(context) ? hoverDark : hoverLight;

  static Color selected(BuildContext context) =>
      _isDark(context) ? selectedDark : selectedLight;

  // --- Utilities ---
  static bool _isDark(BuildContext context) {
    final brightness =
        CupertinoTheme.maybeBrightnessOf(context) ??
        MediaQuery.maybePlatformBrightnessOf(context) ??
        Brightness.light;
    return brightness == Brightness.dark;
  }
}
