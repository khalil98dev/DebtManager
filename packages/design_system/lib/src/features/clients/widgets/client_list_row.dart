import 'package:domain/domain.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../../../tokens/app_colors.dart';
import '../../../tokens/app_durations.dart';
import '../../../tokens/app_gradients.dart';
import '../../../tokens/app_spacing.dart';
import '../../../tokens/app_typography.dart';
import 'client_financial_pill.dart';

/// Cupertino-inspired client list row adhering to UI-Skills:
/// - Clear visual hierarchy, gradient initials avatar, phone & notes metadata.
/// - Tactile press scale (0.985) with spring bounce and selection haptics.
/// - Smooth animated chevron shift on hover/selection.
class ClientListRow extends StatefulWidget {
  const ClientListRow({
    super.key,
    required this.client,
    this.financialPosition,
    this.isSelected = false,
    this.onTap,
    this.showDivider = true,
  });

  final Client client;
  final ClientFinancialPosition? financialPosition;
  final bool isSelected;
  final VoidCallback? onTap;
  final bool showDivider;

  @override
  State<ClientListRow> createState() => _ClientListRowState();
}

class _ClientListRowState extends State<ClientListRow> {
  bool _isHovered = false;
  bool _isPressed = false;

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return '?';
    if (parts.length == 1) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final client = widget.client;
    final initials = _getInitials(client.name);
    final isInteractive = widget.onTap != null;

    final backgroundColor = widget.isSelected
        ? AppColors.selected(context)
        : _isHovered && isInteractive
        ? AppColors.hover(context)
        : CupertinoColors.transparent;

    final scale = isInteractive && _isPressed ? 0.985 : 1.0;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() {
        _isHovered = false;
        _isPressed = false;
      }),
      cursor: isInteractive
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: GestureDetector(
        onTapDown: isInteractive
            ? (_) {
                setState(() => _isPressed = true);
                HapticFeedback.selectionClick();
              }
            : null,
        onTapUp: isInteractive ? (_) => setState(() => _isPressed = false) : null,
        onTapCancel: isInteractive
            ? () => setState(() => _isPressed = false)
            : null,
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedScale(
          scale: scale,
          duration: AppDurations.motionDuration(context, AppDurations.micro),
          curve: _isPressed ? AppDurations.easeOut : AppDurations.springBounce,
          child: AnimatedContainer(
            duration: AppDurations.motionDuration(
              context,
              AppDurations.selection,
            ),
            curve: AppDurations.easeOut,
            decoration: BoxDecoration(color: backgroundColor),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            constraints: const BoxConstraints(
              minHeight: AppSpacing.desktopRowHeight,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Initials Avatar with Modern Gradient
                    AnimatedScale(
                      scale: (_isHovered || widget.isSelected) ? 1.05 : 1.0,
                      duration: AppDurations.motionDuration(
                        context,
                        AppDurations.quick,
                      ),
                      curve: AppDurations.easeOut,
                      child: Container(
                        width: 38.0,
                        height: 38.0,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppGradients.avatarFor(client.name),
                          boxShadow: [
                            BoxShadow(
                              color: AppGradients.avatarFor(client.name)
                                  .colors
                                  .first
                                  .withValues(
                                    alpha: (_isHovered || widget.isSelected)
                                        ? 0.40
                                        : 0.26,
                                  ),
                              blurRadius: (_isHovered || widget.isSelected)
                                  ? 10
                                  : 7,
                              offset: const Offset(0, 2),
                            ),
                          ],
                          border: Border.all(
                            color: CupertinoColors.white.withValues(alpha: 0.28),
                            width: 1.0,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          initials,
                          style: AppTypography.footnote.copyWith(
                            fontWeight: FontWeight.w700,
                            color: CupertinoColors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),

                    // Name & Contact Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            client.name,
                            style: AppTypography.headline.copyWith(
                              fontWeight: FontWeight.w600,
                              color: widget.isSelected
                                  ? AppColors.primaryAccent(context)
                                  : AppColors.textPrimary(context),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2.0),
                          Row(
                            children: [
                              if (client.phone != null) ...[
                                Icon(
                                  CupertinoIcons.phone,
                                  size: 12.0,
                                  color: AppColors.textSecondary(context),
                                ),
                                const SizedBox(width: AppSpacing.xxs),
                                Text(
                                  client.phone!,
                                  style: AppTypography.caption1.copyWith(
                                    color: AppColors.textSecondary(context),
                                  ),
                                ),
                              ] else ...[
                                Text(
                                  'No phone',
                                  style: AppTypography.caption1.copyWith(
                                    color: AppColors.textTertiary(context),
                                  ),
                                ),
                              ],
                              if (client.notes != null &&
                                  client.notes!.isNotEmpty) ...[
                                const SizedBox(width: AppSpacing.xs),
                                Text(
                                  '•',
                                  style: AppTypography.caption1.copyWith(
                                    color: AppColors.textTertiary(context),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Expanded(
                                  child: Text(
                                    client.notes!,
                                    style: AppTypography.caption1.copyWith(
                                      color: AppColors.textTertiary(context),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Financial summary pill (if available)
                    if (widget.financialPosition != null) ...[
                      const SizedBox(width: AppSpacing.sm),
                      ClientFinancialPill(position: widget.financialPosition),
                    ],

                    // Chevron disclosure with smooth hover slide
                    const SizedBox(width: AppSpacing.xs),
                    AnimatedSlide(
                      offset: (_isHovered || widget.isSelected)
                          ? const Offset(0.15, 0)
                          : Offset.zero,
                      duration: AppDurations.motionDuration(
                        context,
                        AppDurations.quick,
                      ),
                      curve: AppDurations.easeOut,
                      child: Icon(
                        CupertinoIcons.chevron_forward,
                        size: 14.0,
                        color: (_isHovered || widget.isSelected)
                            ? AppColors.primaryAccent(context)
                            : AppColors.textTertiary(context),
                      ),
                    ),
                  ],
                ),
                if (widget.showDivider) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    margin: const EdgeInsets.only(left: 54.0),
                    height: 0.5,
                    color: AppColors.separator(context),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
