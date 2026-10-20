import 'package:domain/domain.dart';
import 'package:flutter/cupertino.dart';

import '../../tokens/app_colors.dart';
import '../../tokens/app_spacing.dart';
import '../../tokens/app_typography.dart';
import 'app_badge.dart';
import 'app_card.dart';
import 'app_modern_icon.dart';

/// Senior-grade financial metric card.
///
/// Displays a high-contrast metric value formatted with tabular figures,
/// descriptive title, optional badge, and context subtitle.
class AppMetricCard extends StatelessWidget {
  const AppMetricCard({
    super.key,
    required this.title,
    this.value,
    this.money,
    this.subtitle,
    this.badgeLabel,
    this.badgeVariant = AppBadgeVariant.neutral,
    this.icon,
    this.gradient,
    this.onTap,
  }) : assert(
         value != null || money != null,
         'Either value or money must be provided',
       );

  final String title;
  final String? value;
  final Money? money;
  final String? subtitle;
  final String? badgeLabel;
  final AppBadgeVariant badgeVariant;
  final IconData? icon;
  final Gradient? gradient;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final displayValue = value ?? money?.format() ?? '';
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                AppModernIcon(
                  icon: icon!,
                  size: 28,
                  iconSize: 14,
                  showShadow: false,
                  gradient: gradient,
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.footnote.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary(context),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (badgeLabel != null)
                AppBadge(label: badgeLabel!, variant: badgeVariant),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            displayValue,
            style: AppTypography.title2.copyWith(
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
              color: AppColors.textPrimary(context),
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: AppSpacing.xxs),
            Text(
              subtitle!,
              style: AppTypography.caption1.copyWith(
                color: AppColors.textTertiary(context),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
