import 'dart:ui';
import 'package:flutter/cupertino.dart';

import '../../tokens/app_colors.dart';
import '../../tokens/app_durations.dart';
import '../../tokens/app_radii.dart';
import '../../tokens/app_spacing.dart';

/// Presents a dialog with a frosted glass backdrop blur and smooth spring scale/fade animation.
Future<T?> showAppBlurredDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  String barrierLabel = 'Dismiss',
  double blurSigma = 16.0,
  Duration duration = AppDurations.modal,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: barrierLabel,
    barrierColor: CupertinoColors.black.withValues(alpha: 0.35),
    transitionDuration: AppDurations.motionDuration(context, duration),
    pageBuilder: (dialogContext, animation, secondaryAnimation) {
      return builder(dialogContext);
    },
    transitionBuilder: (dialogContext, animation, secondaryAnimation, child) {
      if (AppDurations.isReducedMotion(dialogContext)) {
        return child;
      }

      final curved = CurvedAnimation(
        parent: animation,
        curve: AppDurations.smoothEaseOut,
        reverseCurve: AppDurations.easeIn,
      );

      return AnimatedBuilder(
        animation: curved,
        builder: (context, _) {
          return BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: blurSigma * curved.value,
              sigmaY: blurSigma * curved.value,
            ),
            child: FadeTransition(
              opacity: curved,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.94, end: 1.0).animate(curved),
                child: child,
              ),
            ),
          );
        },
      );
    },
  );
}

/// A frosted glass card container for dialog content, featuring glassmorphism,
/// subtle ambient illumination border, and deep soft shadows.
class AppBlurredDialogContainer extends StatelessWidget {
  const AppBlurredDialogContainer({
    super.key,
    required this.child,
    this.maxWidth = 640.0,
    this.maxHeight = 760.0,
    this.margin = const EdgeInsets.all(AppSpacing.lg),
  });

  final Widget child;
  final double maxWidth;
  final double maxHeight;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.maybeBrightnessOf(context) == Brightness.dark;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: maxHeight),
        child: Container(
          margin: margin,
          decoration: BoxDecoration(
            borderRadius: AppRadii.lgRadius,
            boxShadow: const [
              BoxShadow(
                color: Color(0x38000000),
                blurRadius: 36.0,
                offset: Offset(0, 14.0),
              ),
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 10.0,
                offset: Offset(0, 3.0),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: AppRadii.lgRadius,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface(
                    context,
                  ).withValues(alpha: isDark ? 0.90 : 0.94),
                  borderRadius: AppRadii.lgRadius,
                  border: Border.all(
                    color: isDark
                        ? CupertinoColors.white.withValues(alpha: 0.16)
                        : CupertinoColors.black.withValues(alpha: 0.10),
                    width: 1.0,
                  ),
                ),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
