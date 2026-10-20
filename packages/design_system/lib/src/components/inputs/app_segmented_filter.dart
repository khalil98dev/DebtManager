import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../../tokens/app_colors.dart';
import '../../tokens/app_radii.dart';
import '../../tokens/app_typography.dart';

/// Clean sliding segmented filter control for status or category selection,
/// encased in an Apple macOS/iOS-style subtle container.
class AppSegmentedFilter<T extends Object> extends StatelessWidget {
  AppSegmentedFilter({
    super.key,
    T? selected,
    T? value,
    Map<T, String>? options,
    Map<T, String>? segments,
    ValueChanged<T>? onSelected,
    ValueChanged<T>? onChanged,
  }) : selected = (selected ?? value)!,
       options = (options ?? segments)!,
       onSelected = (onSelected ?? onChanged)!;

  final T selected;
  final Map<T, String> options;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.maybeBrightnessOf(context) == Brightness.dark;

    final containerBg = isDark
        ? const Color(0xFF1C1C1E)
        : const Color(0xFFE5E5EA);

    return Container(
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(
        color: containerBg,
        borderRadius: AppRadii.smRadius,
        border: Border.all(
          color: AppColors.border(context).withValues(alpha: 0.5),
          width: 0.8,
        ),
      ),
      child: CupertinoSlidingSegmentedControl<T>(
        groupValue: selected,
        backgroundColor: CupertinoColors.transparent,
        thumbColor: AppColors.surface(context),
        children: {
          for (final entry in options.entries)
            entry.key: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              child: Text(
                entry.value,
                style: AppTypography.footnote.copyWith(
                  fontWeight: selected == entry.key
                      ? FontWeight.w600
                      : FontWeight.w500,
                  color: selected == entry.key
                      ? AppColors.textPrimary(context)
                      : AppColors.textSecondary(context),
                ),
              ),
            ),
        },
        onValueChanged: (val) {
          if (val != null) {
            HapticFeedback.selectionClick();
            onSelected(val);
          }
        },
      ),
    );
  }
}
