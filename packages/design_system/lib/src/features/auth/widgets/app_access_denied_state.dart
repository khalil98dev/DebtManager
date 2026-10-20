import 'package:domain/domain.dart';
import 'package:flutter/cupertino.dart';

import '../../../components/surfaces/app_badge.dart';
import '../../../components/surfaces/app_modern_icon.dart';
import '../../../tokens/app_colors.dart';
import '../../../tokens/app_gradients.dart';
import '../../../tokens/app_radii.dart';
import '../../../tokens/app_spacing.dart';
import '../../../tokens/app_typography.dart';

/// Displays a clean RBAC access-restricted message when the current user's role
/// lacks a required [AppPermission].
class AppAccessDeniedState extends StatelessWidget {
  const AppAccessDeniedState({
    super.key,
    required this.requiredPermission,
    this.currentRoleName,
    this.title = 'Restricted Access',
  });

  final AppPermission requiredPermission;
  final String? currentRoleName;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Container(
          margin: const EdgeInsets.all(AppSpacing.lg),
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: AppColors.surface(context),
            borderRadius: AppRadii.lgRadius,
            border: Border.all(color: AppColors.border(context)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppModernIcon(
                icon: CupertinoIcons.lock_shield_fill,
                size: 52,
                iconSize: 26,
                gradient: AppGradients.warning(context),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTypography.title2.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary(context),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Your active role (${currentRoleName ?? "Operator"}) does not include the "${requiredPermission.label}" permission required to view or modify this module.',
                textAlign: TextAlign.center,
                style: AppTypography.body.copyWith(
                  color: AppColors.textSecondary(context),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                alignment: WrapAlignment.center,
                children: [
                  if (currentRoleName != null)
                    AppBadge(
                      label: 'ROLE: ${currentRoleName!.toUpperCase()}',
                      variant: AppBadgeVariant.neutral,
                    ),
                  AppBadge(
                    label: 'REQUIRES: ${requiredPermission.label.toUpperCase()}',
                    variant: AppBadgeVariant.warning,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
