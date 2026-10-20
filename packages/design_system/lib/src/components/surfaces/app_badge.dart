import 'package:flutter/cupertino.dart';

import '../../tokens/app_colors.dart';
import '../../tokens/app_radii.dart';
import '../../tokens/app_spacing.dart';
import '../../tokens/app_typography.dart';

enum AppBadgeVariant { success, destructive, warning, accent, neutral }

/// A compact, semantic pill badge for financial status and counts.
class AppBadge extends StatelessWidget {
  const AppBadge({
    super.key,
    required this.label,
    this.variant = AppBadgeVariant.neutral,
    this.icon,
    this.showDot = false,
  });

  final String label;
  final AppBadgeVariant variant;
  final IconData? icon;
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    final style = _resolveColors(context);

    return Container(
      padding: AppSpacing.badge,
      decoration: BoxDecoration(
        color: style.backgroundColor,
        borderRadius: AppRadii.pillRadius,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (showDot) ...[
            Container(
              width: 6.0,
              height: 6.0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: style.textColor,
              ),
            ),
            const SizedBox(width: AppSpacing.xxs),
          ] else if (icon != null) ...[
            Icon(icon, size: 11.0, color: style.textColor),
            const SizedBox(width: AppSpacing.xxs),
          ],
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption2.copyWith(
                fontWeight: FontWeight.w600,
                color: style.textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  _BadgeStyle _resolveColors(BuildContext context) {
    final isDark = CupertinoTheme.maybeBrightnessOf(context) == Brightness.dark;

    switch (variant) {
      case AppBadgeVariant.success:
        return _BadgeStyle(
          backgroundColor: AppColors.successContainer(context),
          textColor: isDark ? AppColors.successDark : AppColors.successLight,
        );
      case AppBadgeVariant.destructive:
        return _BadgeStyle(
          backgroundColor: AppColors.destructiveContainer(context),
          textColor: isDark
              ? AppColors.destructiveDark
              : AppColors.destructiveLight,
        );
      case AppBadgeVariant.warning:
        return _BadgeStyle(
          backgroundColor: AppColors.warningContainer(context),
          textColor: isDark ? AppColors.warningDark : AppColors.warningLight,
        );
      case AppBadgeVariant.accent:
        return _BadgeStyle(
          backgroundColor: isDark
              ? const Color(0x330A84FF)
              : const Color(0x1F007AFF),
          textColor: AppColors.primaryAccent(context),
        );
      case AppBadgeVariant.neutral:
        return _BadgeStyle(
          backgroundColor: isDark
              ? const Color(0x26FFFFFF)
              : const Color(0x14000000),
          textColor: AppColors.textSecondary(context),
        );
    }
  }
}

class _BadgeStyle {
  const _BadgeStyle({required this.backgroundColor, required this.textColor});

  final Color backgroundColor;
  final Color textColor;
}
