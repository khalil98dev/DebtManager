import 'package:flutter/cupertino.dart';

import '../../tokens/app_colors.dart';
import '../../tokens/app_spacing.dart';
import '../../tokens/app_typography.dart';
import '../surfaces/app_badge.dart';

/// Top header presenting page title, item counts, and action controls.
class AppPageHeader extends StatelessWidget {
  const AppPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.badgeCount,
    this.actions,
    this.bottom,
    this.padding = const EdgeInsets.only(
      left: AppSpacing.lg,
      right: AppSpacing.lg,
      top: AppSpacing.lg,
      bottom: AppSpacing.md,
    ),
  });

  final String title;
  final String? subtitle;
  final int? badgeCount;
  final Widget? actions;
  final Widget? bottom;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: AppTypography.title1.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary(context),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (badgeCount != null) ...[
                      const SizedBox(width: AppSpacing.sm),
                      AppBadge(
                        label: '$badgeCount',
                        variant: AppBadgeVariant.neutral,
                      ),
                    ],
                  ],
                ),
              ),
              if (actions != null) ...[
                const SizedBox(width: AppSpacing.md),
                actions!,
              ],
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: AppSpacing.xxs),
            Text(
              subtitle!,
              style: AppTypography.subheadline.copyWith(
                color: AppColors.textSecondary(context),
              ),
            ),
          ],
          if (bottom != null) ...[
            const SizedBox(height: AppSpacing.md),
            bottom!,
          ],
        ],
      ),
    );
  }
}
