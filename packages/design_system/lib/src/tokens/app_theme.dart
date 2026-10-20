import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_radii.dart';
import 'app_typography.dart';

/// Provides theme configurations for Cupertino and Material layers
/// ensuring a unified, Apple-inspired aesthetic.
abstract final class AppTheme {
  // --- Cupertino Theme Data ---
  static CupertinoThemeData get cupertinoLight => CupertinoThemeData(
    brightness: Brightness.light,
    primaryColor: AppColors.accentLight,
    primaryContrastingColor: CupertinoColors.white,
    barBackgroundColor: const Color(0xCCF9F9FB), // Translucent frosted header
    scaffoldBackgroundColor: AppColors.canvasLight,
    textTheme: CupertinoTextThemeData(
      primaryColor: AppColors.textPrimaryLight,
      textStyle: AppTypography.body.copyWith(color: AppColors.textPrimaryLight),
      navLargeTitleTextStyle: AppTypography.largeTitle.copyWith(
        color: AppColors.textPrimaryLight,
      ),
      navTitleTextStyle: AppTypography.headline.copyWith(
        color: AppColors.textPrimaryLight,
      ),
      actionTextStyle: AppTypography.body.copyWith(
        color: AppColors.accentLight,
        fontWeight: FontWeight.w600,
      ),
      tabLabelTextStyle: AppTypography.caption2.copyWith(
        color: AppColors.textSecondaryLight,
      ),
    ),
  );

  static CupertinoThemeData get cupertinoDark => CupertinoThemeData(
    brightness: Brightness.dark,
    primaryColor: AppColors.accentDark,
    primaryContrastingColor: CupertinoColors.black,
    barBackgroundColor: const Color(0xCC1C1C1E), // Frosted dark header
    scaffoldBackgroundColor: AppColors.canvasDark,
    textTheme: CupertinoTextThemeData(
      primaryColor: AppColors.textPrimaryDark,
      textStyle: AppTypography.body.copyWith(color: AppColors.textPrimaryDark),
      navLargeTitleTextStyle: AppTypography.largeTitle.copyWith(
        color: AppColors.textPrimaryDark,
      ),
      navTitleTextStyle: AppTypography.headline.copyWith(
        color: AppColors.textPrimaryDark,
      ),
      actionTextStyle: AppTypography.body.copyWith(
        color: AppColors.accentDark,
        fontWeight: FontWeight.w600,
      ),
      tabLabelTextStyle: AppTypography.caption2.copyWith(
        color: AppColors.textSecondaryDark,
      ),
    ),
  );

  // --- Material Theme Data (For cross-platform tooltips, text selection, and dialogs) ---
  static ThemeData materialLight = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.canvasLight,
    colorScheme: const ColorScheme.light(
      primary: AppColors.accentLight,
      surface: AppColors.surfaceLight,
      error: AppColors.destructiveLight,
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.separatorLight,
      thickness: 1,
      space: 1,
    ),
    cardTheme: CardThemeData(
      color: AppColors.surfaceLight,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadii.mdRadius,
        side: const BorderSide(color: AppColors.borderLight, width: 1),
      ),
    ),
    tooltipTheme: const TooltipThemeData(
      decoration: BoxDecoration(
        color: Color(0xE62C2C2E),
        borderRadius: AppRadii.smRadius,
      ),
      textStyle: TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    ),
  );

  static ThemeData materialDark = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.canvasDark,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.accentDark,
      surface: AppColors.surfaceDark,
      error: AppColors.destructiveDark,
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.separatorDark,
      thickness: 1,
      space: 1,
    ),
    cardTheme: CardThemeData(
      color: AppColors.surfaceDark,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadii.mdRadius,
        side: const BorderSide(color: AppColors.borderDark, width: 1),
      ),
    ),
    tooltipTheme: const TooltipThemeData(
      decoration: BoxDecoration(
        color: Color(0xE6E5E5EA),
        borderRadius: AppRadii.smRadius,
      ),
      textStyle: TextStyle(
        color: Colors.black,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    ),
  );
}
