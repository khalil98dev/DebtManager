import 'package:flutter/cupertino.dart';

import '../../tokens/app_colors.dart';
import '../../tokens/app_gradients.dart';

enum AppModernIconShape { squircle, circle }

/// A modern Apple-grade icon badge with vibrant gradient or clean tonal backgrounds,
/// subtle ambient illumination, and crisp antialiasing.
class AppModernIcon extends StatelessWidget {
  const AppModernIcon({
    super.key,
    required this.icon,
    this.size = 36.0,
    this.iconSize,
    this.gradient,
    this.color,
    this.iconColor,
    this.shape = AppModernIconShape.squircle,
    this.showShadow = true,
    this.tonal = false,
  });

  final IconData icon;
  final double size;
  final double? iconSize;
  final Gradient? gradient;
  final Color? color;
  final Color? iconColor;
  final AppModernIconShape shape;
  final bool showShadow;
  final bool tonal;

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.maybeBrightnessOf(context) == Brightness.dark;
    final baseAccent = color ?? AppColors.primaryAccent(context);
    final effectiveIconSize = iconSize ?? (size * 0.50);
    final borderRadius = shape == AppModernIconShape.squircle
        ? BorderRadius.circular(size * 0.28)
        : null;

    if (tonal) {
      final tonalBg = baseAccent.withValues(alpha: isDark ? 0.16 : 0.10);
      final tonalBorder = baseAccent.withValues(alpha: isDark ? 0.28 : 0.18);
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: tonalBg,
          shape: shape == AppModernIconShape.circle
              ? BoxShape.circle
              : BoxShape.rectangle,
          borderRadius: borderRadius,
          border: Border.all(color: tonalBorder, width: 0.8),
        ),
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: effectiveIconSize,
          color: iconColor ?? baseAccent,
        ),
      );
    }

    final effectiveGradient =
        gradient ?? (color == null ? AppGradients.primary(context) : null);

    final shadowColor = effectiveGradient is LinearGradient
        ? effectiveGradient.colors.first.withValues(alpha: 0.24)
        : baseAccent.withValues(alpha: 0.22);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: effectiveGradient == null ? baseAccent : null,
        gradient: effectiveGradient,
        shape: shape == AppModernIconShape.circle
            ? BoxShape.circle
            : BoxShape.rectangle,
        borderRadius: borderRadius,
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: shadowColor,
                  blurRadius: size * 0.24,
                  offset: Offset(0, size * 0.08),
                ),
              ]
            : null,
        border: Border.all(
          color: CupertinoColors.white.withValues(alpha: 0.22),
          width: 0.8,
        ),
      ),
      alignment: Alignment.center,
      child: Icon(
        icon,
        size: effectiveIconSize,
        color: iconColor ?? CupertinoColors.white,
      ),
    );
  }
}
