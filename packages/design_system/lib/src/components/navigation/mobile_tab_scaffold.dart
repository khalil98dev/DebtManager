import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../../tokens/app_colors.dart';
import '../../tokens/app_radii.dart';
import '../../tokens/app_typography.dart';

class MobileTabItem {
  const MobileTabItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.builder,
    this.accentColor,
    this.badgeCount,
    this.badgeText,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
  final WidgetBuilder builder;
  final Color? accentColor;
  final int? badgeCount;
  final String? badgeText;

  String? get effectiveBadge =>
      badgeText ?? (badgeCount != null ? '$badgeCount' : null);
}

/// iOS-styled Cupertino tab scaffold wrapper with frosted glass tab bar,
/// clean semantic icon badges, live value pills, and tactile selection haptics.
class MobileTabScaffold extends StatelessWidget {
  const MobileTabScaffold({super.key, required this.tabs, this.controller});

  final List<MobileTabItem> tabs;
  final CupertinoTabController? controller;

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.maybeBrightnessOf(context) == Brightness.dark;

    return CupertinoTabScaffold(
      controller: controller,
      backgroundColor: CupertinoColors.transparent,
      tabBar: CupertinoTabBar(
        activeColor: AppColors.primaryAccent(context),
        inactiveColor: AppColors.textSecondary(context),
        backgroundColor: AppColors.surface(
          context,
        ).withValues(alpha: isDark ? 0.82 : 0.88),
        border: Border(
          top: BorderSide(color: AppColors.separator(context), width: 0.5),
        ),
        onTap: (_) => HapticFeedback.selectionClick(),
        items: tabs.map((tab) {
          final accent = tab.accentColor ?? AppColors.primaryAccent(context);
          final badge = tab.effectiveBadge;
          return BottomNavigationBarItem(
            icon: _buildTabIcon(
              context,
              icon: tab.icon,
              accent: accent,
              isActive: false,
              isDark: isDark,
              badge: badge,
            ),
            activeIcon: _buildTabIcon(
              context,
              icon: tab.activeIcon,
              accent: accent,
              isActive: true,
              isDark: isDark,
              badge: badge,
            ),
            label: tab.label,
          );
        }).toList(),
      ),
      tabBuilder: (context, index) {
        return CupertinoTabView(
          builder: (context) => tabs[index].builder(context),
        );
      },
    );
  }

  Widget _buildTabIcon(
    BuildContext context, {
    required IconData icon,
    required Color accent,
    required bool isActive,
    required bool isDark,
    String? badge,
  }) {
    final iconWidget = Container(
      width: 34,
      height: 24,
      decoration: BoxDecoration(
        color: isActive
            ? accent.withValues(alpha: isDark ? 0.22 : 0.14)
            : CupertinoColors.transparent,
        borderRadius: AppRadii.pillRadius,
      ),
      alignment: Alignment.center,
      child: Icon(
        icon,
        size: 19,
        color: isActive ? accent : AppColors.textSecondary(context),
      ),
    );

    if (badge == null) {
      return iconWidget;
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        iconWidget,
        Positioned(
          right: -8,
          top: -3,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4.5, vertical: 0.5),
            decoration: BoxDecoration(
              color: isActive ? accent : AppColors.surfaceSecondary(context),
              borderRadius: AppRadii.pillRadius,
              border: Border.all(
                color: isActive
                    ? CupertinoColors.white.withValues(alpha: 0.35)
                    : accent.withValues(alpha: 0.30),
                width: 0.7,
              ),
            ),
            child: Text(
              badge,
              style: AppTypography.caption2.copyWith(
                fontSize: 9.0,
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
                color: isActive ? CupertinoColors.white : accent,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
