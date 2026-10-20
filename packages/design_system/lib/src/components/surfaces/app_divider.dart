import 'package:flutter/cupertino.dart';

import '../../tokens/app_colors.dart';

/// 1px hairline separator adhering to Apple's design specifications.
class AppDivider extends StatelessWidget {
  const AppDivider({
    super.key,
    this.indent = 0.0,
    this.endIndent = 0.0,
    this.color,
  });

  final double indent;
  final double endIndent;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(left: indent, right: endIndent),
      height: 1.0,
      color: color ?? AppColors.separator(context),
    );
  }
}
