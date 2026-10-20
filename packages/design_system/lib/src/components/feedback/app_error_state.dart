import 'package:flutter/cupertino.dart';

import '../../tokens/app_colors.dart';
import '../../tokens/app_spacing.dart';
import '../../tokens/app_typography.dart';
import '../buttons/app_button.dart';

/// Error state component displaying human-readable failure and retry action.
class AppErrorState extends StatelessWidget {
  const AppErrorState({
    super.key,
    String? message,
    String? description,
    this.title = 'Unable to Load Data',
    this.onRetry,
    this.retryLabel = 'Try Again',
  }) : message = (message ?? description ?? 'An unexpected error occurred');

  final String title;
  final String message;
  final VoidCallback? onRetry;
  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 72.0,
              height: 72.0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.destructiveContainer(context),
              ),
              child: Icon(
                CupertinoIcons.exclamationmark_triangle,
                size: 34.0,
                color: AppColors.destructive(context),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTypography.title3.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary(context),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: AppTypography.subheadline.copyWith(
                  color: AppColors.textSecondary(context),
                ),
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                text: retryLabel,
                onPressed: onRetry,
                icon: const Icon(CupertinoIcons.refresh),
                variant: AppButtonVariant.secondary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
