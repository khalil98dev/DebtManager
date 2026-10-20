import 'package:domain/domain.dart';
import 'package:flutter/cupertino.dart';

import '../../tokens/app_colors.dart';
import '../../tokens/app_typography.dart';

/// Semantic, tabular-figured money display component.
class AppMoneyDisplay extends StatelessWidget {
  const AppMoneyDisplay({
    super.key,
    required this.money,
    this.style,
    this.semanticColor = false,
    this.isDebt = false,
  });

  final Money money;
  final TextStyle? style;
  final bool semanticColor;
  final bool isDebt;

  @override
  Widget build(BuildContext context) {
    Color? color;
    if (semanticColor) {
      if (money.isZero) {
        color = AppColors.textSecondary(context);
      } else if (isDebt) {
        color = AppColors.destructive(context);
      } else {
        color = AppColors.success(context);
      }
    }

    final defaultStyle = style ?? AppTypography.body;
    return Text(
      money.format(),
      style: defaultStyle.copyWith(
        fontFeatures: const [FontFeature.tabularFigures()],
        color: color ?? defaultStyle.color ?? AppColors.textPrimary(context),
      ),
    );
  }
}
