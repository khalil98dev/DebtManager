import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Tooltip;

import '../../tokens/app_colors.dart';
import '../../tokens/app_durations.dart';
import '../../tokens/app_radii.dart';
import '../../tokens/app_spacing.dart';
import '../../tokens/app_typography.dart';
import '../buttons/app_icon_button.dart';
import '../surfaces/app_badge.dart';
import '../surfaces/app_modern_icon.dart';

class NavigationDestinationItem {
  const NavigationDestinationItem({
    required this.label,
    required this.icon,
    this.activeIcon,
    this.accentColor,
    this.section,
    this.badgeCount,
    this.valueLabel,
    this.badgeVariant,
    this.key,
  });

  final String label;
  final IconData icon;
  final IconData? activeIcon;
  final Color? accentColor;
  final String? section;
  final int? badgeCount;
  final String? valueLabel;
  final AppBadgeVariant? badgeVariant;
  final Key? key;

  String? get effectiveValueText =>
      valueLabel ?? (badgeCount != null ? '$badgeCount' : null);
}

/// Senior-grade macOS-style collapsible/closable sidebar navigation shell
/// with butter-smooth progressive width & opacity choreography, clean semantic
/// squircle icons, live value pills, and section categorization.
class DesktopSidebar extends StatefulWidget {
  const DesktopSidebar({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.width = 264.0,
    this.collapsedWidth = 76.0,
    this.isCollapsible = true,
    this.initiallyCollapsed = false,
    this.isCollapsed,
    this.onCollapsedChanged,
    this.header,
    this.footer,
    this.collapsedFooter,
  });

  final List<NavigationDestinationItem> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final double width;
  final double collapsedWidth;
  final bool isCollapsible;
  final bool initiallyCollapsed;
  final bool? isCollapsed;
  final ValueChanged<bool>? onCollapsedChanged;
  final Widget? header;
  final Widget? footer;
  final Widget? collapsedFooter;

  @override
  State<DesktopSidebar> createState() => _DesktopSidebarState();
}

class _DesktopSidebarState extends State<DesktopSidebar> {
  late bool _internalCollapsed;

  bool get _effectiveCollapsed => widget.isCollapsed ?? _internalCollapsed;

  @override
  void initState() {
    super.initState();
    _internalCollapsed = widget.initiallyCollapsed;
  }

  void _toggleCollapsed() {
    final next = !_effectiveCollapsed;
    if (widget.isCollapsed == null) {
      setState(() => _internalCollapsed = next);
    }
    widget.onCollapsedChanged?.call(next);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.maybeBrightnessOf(context) == Brightness.dark;
    final collapsed = _effectiveCollapsed;
    final targetWidth = collapsed ? widget.collapsedWidth : widget.width;

    return AnimatedContainer(
      duration: AppDurations.motionDuration(context, AppDurations.expand),
      curve: AppDurations.standardCurve,
      width: targetWidth,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: AppColors.sidebar(context),
        border: Border(
          right: BorderSide(
            color: AppColors.separator(context).withValues(alpha: 0.5),
            width: 1.0,
          ),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final currentW = constraints.maxWidth;
          // Threshold at 148px: above 148px we smoothly fade expanded content;
          // below 148px we smoothly present the compact icon rail.
          const threshold = 148.0;
          final isCompact = currentW < threshold;
          final expandSpan = (widget.width - threshold).clamp(1.0, 500.0);
          final collapseSpan = (threshold - widget.collapsedWidth).clamp(
            1.0,
            500.0,
          );
          final expandOpacity = ((currentW - threshold) / expandSpan).clamp(
            0.0,
            1.0,
          );
          final compactOpacity = ((threshold - currentW) / collapseSpan).clamp(
            0.0,
            1.0,
          );

          return SafeArea(
            left: false,
            right: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header: Company branding, app identity & Collapse/Expand toggle
                if (widget.header != null && !isCompact)
                  Opacity(
                    opacity: expandOpacity,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.md,
                      ),
                      child: widget.header!,
                    ),
                  )
                else
                  _buildHeader(
                    context,
                    isDark: isDark,
                    isCompact: isCompact,
                    expandOpacity: expandOpacity,
                    compactOpacity: compactOpacity,
                  ),

                // Navigation Items List
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.symmetric(
                      horizontal: isCompact ? AppSpacing.xs : AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    itemCount: widget.destinations.length,
                    itemBuilder: (context, index) {
                      final destination = widget.destinations[index];
                      final isSelected = index == widget.selectedIndex;

                      final currentSection = destination.section;
                      final prevSection = index > 0
                          ? widget.destinations[index - 1].section
                          : null;
                      final showSectionHeader =
                          currentSection != null &&
                          currentSection != prevSection;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (showSectionHeader) ...[
                            if (index > 0)
                              SizedBox(
                                height: isCompact
                                    ? AppSpacing.sm
                                    : AppSpacing.md,
                              ),
                            if (isCompact)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm,
                                  vertical: AppSpacing.xxs,
                                ),
                                child: Container(
                                  height: 1.0,
                                  color: AppColors.separator(
                                    context,
                                  ).withValues(alpha: 0.55),
                                ),
                              )
                            else
                              Opacity(
                                opacity: expandOpacity,
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                    left: AppSpacing.sm,
                                    right: AppSpacing.sm,
                                    bottom: AppSpacing.xxs + 2,
                                    top: AppSpacing.xxs,
                                  ),
                                  child: Text(
                                    currentSection.toUpperCase(),
                                    style: AppTypography.caption2.copyWith(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.1,
                                      color: AppColors.textTertiary(context),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                          ],
                          Padding(
                            padding: const EdgeInsets.only(bottom: 3.5),
                            child: _SidebarItem(
                              destination: destination,
                              isSelected: isSelected,
                              isCompact: isCompact,
                              expandOpacity: expandOpacity,
                              compactOpacity: compactOpacity,
                              onTap: () => widget.onDestinationSelected(index),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),

                // Footer: telemetry status & environment stats
                _buildFooter(
                  context,
                  isCompact: isCompact,
                  expandOpacity: expandOpacity,
                  compactOpacity: compactOpacity,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context, {
    required bool isDark,
    required bool isCompact,
    required double expandOpacity,
    required double compactOpacity,
  }) {
    if (isCompact) {
      return Opacity(
        opacity: compactOpacity,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs,
            vertical: AppSpacing.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10.0),
                child: Image.asset(
                  'assets/icons/app_icon.png',
                  package: 'design_system',
                  width: 36.0,
                  height: 36.0,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const AppModernIcon(
                        icon: CupertinoIcons.creditcard_fill,
                        size: 36.0,
                        iconSize: 18.0,
                      ),
                ),
              ),
              if (widget.isCollapsible) ...[
                const SizedBox(height: AppSpacing.xs),
                AppIconButton(
                  key: const ValueKey('sidebar_toggle_button'),
                  icon: CupertinoIcons.sidebar_left,
                  size: 32.0,
                  iconSize: 16.0,
                  isCircle: false,
                  tooltip: 'Expand Sidebar',
                  onPressed: _toggleCollapsed,
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.surface(
            context,
          ).withValues(alpha: isDark ? 0.4 : 0.6),
          borderRadius: AppRadii.mdRadius,
          border: Border.all(
            color: AppColors.border(context).withValues(alpha: 0.4),
            width: 0.8,
          ),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(9.0),
              child: Image.asset(
                'assets/icons/app_icon.png',
                package: 'design_system',
                width: 36.0,
                height: 36.0,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const AppModernIcon(
                      icon: CupertinoIcons.creditcard_fill,
                      size: 36.0,
                      iconSize: 18.0,
                    ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Opacity(
                opacity: expandOpacity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Debt Manager',
                      style: AppTypography.headline.copyWith(
                        fontSize: 15.0,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                        color: AppColors.textPrimary(context),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 1.0),
                    Text(
                      'Ledger & Receivables',
                      style: AppTypography.caption2.copyWith(
                        fontSize: 11.0,
                        color: AppColors.textTertiary(context),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            if (widget.isCollapsible) ...[
              const SizedBox(width: AppSpacing.xxs),
              AppIconButton(
                key: const ValueKey('sidebar_toggle_button'),
                icon: CupertinoIcons.sidebar_left,
                size: 28.0,
                iconSize: 15.0,
                isCircle: false,
                tooltip: 'Collapse Sidebar',
                onPressed: _toggleCollapsed,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(
    BuildContext context, {
    required bool isCompact,
    required double expandOpacity,
    required double compactOpacity,
  }) {
    if (isCompact) {
      if (widget.collapsedFooter != null) {
        return Opacity(
          opacity: compactOpacity,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xs,
              vertical: AppSpacing.md,
            ),
            child: widget.collapsedFooter!,
          ),
        );
      }
      return Opacity(
        opacity: compactOpacity,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs,
            vertical: AppSpacing.md,
          ),
          child: Tooltip(
            message: 'Local SQLite · Synced',
            child: Center(
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.surfaceSecondary(
                    context,
                  ).withValues(alpha: 0.6),
                  borderRadius: AppRadii.smRadius,
                  border: Border.all(
                    color: AppColors.border(context).withValues(alpha: 0.5),
                    width: 0.8,
                  ),
                ),
                alignment: Alignment.center,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.success(context),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.success(context).withValues(alpha: 0.6),
                        blurRadius: 5.0,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    if (widget.footer != null) {
      return Opacity(
        opacity: expandOpacity,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: widget.footer!,
        ),
      );
    }

    return Opacity(
      opacity: expandOpacity,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm + 2,
            vertical: AppSpacing.xs + 2,
          ),
          decoration: BoxDecoration(
            color: AppColors.surfaceSecondary(context).withValues(alpha: 0.6),
            borderRadius: AppRadii.smRadius,
            border: Border.all(
              color: AppColors.border(context).withValues(alpha: 0.5),
              width: 0.8,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.success(context),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.success(context).withValues(alpha: 0.6),
                      blurRadius: 5.0,
                    ),
                    BoxShadow(
                      color: AppColors.success(context).withValues(alpha: 0.25),
                      spreadRadius: 2.5,
                      blurRadius: 6.0,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs + 2),
              Expanded(
                child: Text(
                  'Local SQLite · Synced',
                  style: AppTypography.caption2.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary(context),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                CupertinoIcons.checkmark_alt,
                size: 13.0,
                color: AppColors.success(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarItem extends StatefulWidget {
  const _SidebarItem({
    required this.destination,
    required this.isSelected,
    required this.isCompact,
    required this.expandOpacity,
    required this.compactOpacity,
    required this.onTap,
  });

  final NavigationDestinationItem destination;
  final bool isSelected;
  final bool isCompact;
  final double expandOpacity;
  final double compactOpacity;
  final VoidCallback onTap;

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.maybeBrightnessOf(context) == Brightness.dark;
    final effectiveAccent =
        widget.destination.accentColor ?? AppColors.primaryAccent(context);

    final effectiveTextColor = widget.isSelected
        ? AppColors.textPrimary(context)
        : (_isHovered
              ? AppColors.textPrimary(context)
              : AppColors.textSecondary(context));

    final effectiveIconData = widget.isSelected
        ? (widget.destination.activeIcon ?? widget.destination.icon)
        : widget.destination.icon;

    final rowGradient = widget.isSelected
        ? LinearGradient(
            colors: [
              effectiveAccent.withValues(alpha: isDark ? 0.20 : 0.13),
              effectiveAccent.withValues(alpha: isDark ? 0.07 : 0.03),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          )
        : null;

    final rowBackgroundColor = widget.isSelected
        ? null
        : (_isHovered ? AppColors.hover(context) : CupertinoColors.transparent);

    final rowBorder = widget.isSelected
        ? Border.all(
            color: effectiveAccent.withValues(alpha: 0.28),
            width: 0.8,
          )
        : (_isHovered
              ? Border.all(
                  color: AppColors.border(context).withValues(alpha: 0.5),
                  width: 0.8,
                )
              : Border.all(color: CupertinoColors.transparent, width: 0.8));

    final scale = _isPressed ? 0.98 : (_isHovered ? 1.01 : 1.0);
    final valueText = widget.destination.effectiveValueText;

    final iconBadge = _buildCleanIconContainer(
      context,
      icon: effectiveIconData,
      accent: effectiveAccent,
      isSelected: widget.isSelected,
      isHovered: _isHovered,
      isDark: isDark,
      size: widget.isCompact ? 32.0 : 28.0,
    );

    Widget content;
    if (widget.isCompact) {
      content = Center(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            iconBadge,
            if (valueText != null)
              Positioned(
                right: -5,
                top: -4,
                child: Opacity(
                  opacity: widget.compactOpacity,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4.5,
                      vertical: 1.0,
                    ),
                    decoration: BoxDecoration(
                      color: widget.isSelected
                          ? effectiveAccent
                          : AppColors.surface(context),
                      borderRadius: AppRadii.pillRadius,
                      border: Border.all(
                        color: widget.isSelected
                            ? CupertinoColors.white.withValues(alpha: 0.35)
                            : effectiveAccent.withValues(alpha: 0.35),
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      valueText,
                      style: AppTypography.caption2.copyWith(
                        fontSize: 9.0,
                        fontWeight: FontWeight.w700,
                        fontFeatures: const [FontFeature.tabularFigures()],
                        color: widget.isSelected
                            ? CupertinoColors.white
                            : effectiveAccent,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    } else {
      content = Row(
        children: [
          if (widget.isSelected) ...[
            Container(
              width: 3.5,
              height: 18.0,
              decoration: BoxDecoration(
                color: effectiveAccent,
                borderRadius: AppRadii.pillRadius,
                boxShadow: [
                  BoxShadow(
                    color: effectiveAccent.withValues(alpha: 0.45),
                    blurRadius: 4.0,
                    offset: const Offset(1, 0),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
          ],
          iconBadge,
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Opacity(
              opacity: widget.expandOpacity,
              child: Text(
                widget.destination.label,
                style: AppTypography.subheadline.copyWith(
                  fontSize: 13.5,
                  fontWeight: widget.isSelected
                      ? FontWeight.w600
                      : FontWeight.w500,
                  color: effectiveTextColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          if (valueText != null) ...[
            const SizedBox(width: AppSpacing.xxs),
            Opacity(
              opacity: widget.expandOpacity,
              child: _buildValuePill(
                context,
                text: valueText,
                accent: effectiveAccent,
                isSelected: widget.isSelected,
                isDark: isDark,
              ),
            ),
          ],
        ],
      );
    }

    Widget itemWidget = MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() {
        _isHovered = false;
        _isPressed = false;
      }),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        key: widget.destination.key,
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedScale(
          scale: scale,
          duration: AppDurations.motionDuration(context, AppDurations.micro),
          curve: AppDurations.easeOut,
          child: AnimatedContainer(
            duration: AppDurations.motionDuration(
              context,
              AppDurations.selection,
            ),
            curve: AppDurations.easeOut,
            height: 42.0,
            padding: EdgeInsets.symmetric(
              horizontal: widget.isCompact ? AppSpacing.xxs : AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: rowBackgroundColor,
              gradient: rowGradient,
              borderRadius: AppRadii.smRadius,
              border: rowBorder,
            ),
            child: content,
          ),
        ),
      ),
    );

    if (widget.isCompact) {
      final tooltipLabel = valueText != null
          ? '${widget.destination.label} ($valueText)'
          : widget.destination.label;
      itemWidget = Tooltip(message: tooltipLabel, child: itemWidget);
    }

    return itemWidget;
  }

  Widget _buildCleanIconContainer(
    BuildContext context, {
    required IconData icon,
    required Color accent,
    required bool isSelected,
    required bool isHovered,
    required bool isDark,
    required double size,
  }) {
    final bgGradient = isSelected
        ? LinearGradient(
            colors: [accent, accent.withValues(alpha: 0.80)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : null;

    final bgColor = isSelected
        ? null
        : accent.withValues(
            alpha: isHovered ? 0.18 : (isDark ? 0.15 : 0.10),
          );

    final borderColor = isSelected
        ? CupertinoColors.white.withValues(alpha: 0.28)
        : accent.withValues(alpha: isHovered ? 0.32 : 0.18);

    final iconColor = isSelected ? CupertinoColors.white : accent;

    return AnimatedContainer(
      duration: AppDurations.motionDuration(context, AppDurations.quick),
      curve: AppDurations.easeOut,
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColor,
        gradient: bgGradient,
        borderRadius: BorderRadius.circular(size * 0.28),
        border: Border.all(color: borderColor, width: 0.8),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: accent.withValues(alpha: 0.28),
                  blurRadius: 6.0,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: size * 0.52, color: iconColor),
    );
  }

  Widget _buildValuePill(
    BuildContext context, {
    required String text,
    required Color accent,
    required bool isSelected,
    required bool isDark,
  }) {
    final bgColor = isSelected
        ? accent.withValues(alpha: isDark ? 0.26 : 0.16)
        : AppColors.surfaceSecondary(context).withValues(alpha: 0.85);
    final borderColor = isSelected
        ? accent.withValues(alpha: 0.35)
        : AppColors.border(context).withValues(alpha: 0.55);
    final textColor = isSelected ? accent : AppColors.textSecondary(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7.0, vertical: 2.0),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: AppRadii.pillRadius,
        border: Border.all(color: borderColor, width: 0.8),
      ),
      child: Text(
        text,
        style: AppTypography.caption2.copyWith(
          fontSize: 11.0,
          fontWeight: FontWeight.w600,
          fontFeatures: const [FontFeature.tabularFigures()],
          color: textColor,
        ),
      ),
    );
  }
}
