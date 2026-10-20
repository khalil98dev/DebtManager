import 'package:domain/domain.dart';
import 'package:flutter/cupertino.dart';

import '../../../components/buttons/app_button.dart';
import '../../../components/buttons/app_icon_button.dart';
import '../../../components/feedback/app_blurred_dialog.dart';
import '../../../components/feedback/app_empty_state.dart';
import '../../../components/inputs/app_search_field.dart';
import '../../../components/surfaces/app_badge.dart';
import '../../../components/surfaces/app_modern_icon.dart';
import '../../../tokens/app_colors.dart';
import '../../../tokens/app_durations.dart';
import '../../../tokens/app_gradients.dart';
import '../../../tokens/app_radii.dart';
import '../../../tokens/app_spacing.dart';
import '../../../tokens/app_typography.dart';

/// Desktop-ready, responsive modal dialog for selecting a client.
///
/// Features:
/// - Frosted glass blurred background with scale/fade transition.
/// - Integrated search field with instant filtering by name, phone, and notes.
/// - Rich client list rows with gradient initials avatar, contact info, and checkmark.
/// - Full desktop mouse support: hover states, pointer cursor, and immediate 1-click selection.
/// - Keyboard shortcuts support: Esc to dismiss, Enter on single search result.
class ClientSelectDialog extends StatefulWidget {
  const ClientSelectDialog({
    super.key,
    required this.clients,
    this.selectedClient,
    this.title = 'Select Client',
    this.subtitle = 'Choose a client to associate with this record',
    this.onCreateClient,
  });

  final List<Client> clients;
  final Client? selectedClient;
  final String title;
  final String subtitle;
  final Future<Client?> Function()? onCreateClient;

  /// Shows the [ClientSelectDialog] with frosted glass backdrop blur.
  static Future<Client?> show({
    required BuildContext context,
    required List<Client> clients,
    Client? selectedClient,
    String title = 'Select Client',
    String subtitle = 'Choose a client to associate with this record',
    Future<Client?> Function()? onCreateClient,
  }) {
    return showAppBlurredDialog<Client>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => ClientSelectDialog(
        clients: clients,
        selectedClient: selectedClient,
        title: title,
        subtitle: subtitle,
        onCreateClient: onCreateClient,
      ),
    );
  }

  @override
  State<ClientSelectDialog> createState() => _ClientSelectDialogState();
}

class _ClientSelectDialogState extends State<ClientSelectDialog> {
  late final TextEditingController _searchController;
  late final FocusNode _searchFocusNode;
  late List<Client> _clients;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchFocusNode = FocusNode();
    _clients = List.of(widget.clients);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleCreateClient() async {
    final created = await widget.onCreateClient!();
    if (created != null && mounted) {
      setState(() {
        _clients.insert(0, created);
      });
      _selectAndPop(created);
    }
  }

  List<Client> get _filteredClients {
    if (_searchQuery.isEmpty) return _clients;
    return _clients.where((client) {
      final nameMatches = client.name.toLowerCase().contains(_searchQuery);
      final phoneMatches =
          client.phone?.toLowerCase().contains(_searchQuery) ?? false;
      final notesMatches =
          client.notes?.toLowerCase().contains(_searchQuery) ?? false;
      return nameMatches || phoneMatches || notesMatches;
    }).toList();
  }

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return '?';
    if (parts.length == 1) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  void _selectAndPop(Client client) {
    Navigator.of(context).pop(client);
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredClients;

    return AppBlurredDialogContainer(
      maxWidth: 480.0,
      maxHeight: 560.0,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.separator(context)),
              ),
            ),
            child: Row(
              children: [
                AppModernIcon(
                  icon: CupertinoIcons.person_2_fill,
                  size: 34.0,
                  iconSize: 18.0,
                  gradient: AppGradients.primary(context),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: AppTypography.headline.copyWith(
                          color: AppColors.textPrimary(context),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2.0),
                      Text(
                        widget.subtitle,
                        style: AppTypography.caption1.copyWith(
                          color: AppColors.textSecondary(context),
                        ),
                      ),
                    ],
                  ),
                ),
                AppBadge(
                  label: '${widget.clients.length}',
                  variant: AppBadgeVariant.neutral,
                ),
                const SizedBox(width: AppSpacing.xs),
                AppIconButton(
                  icon: CupertinoIcons.xmark,
                  size: 32.0,
                  iconSize: 14.0,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // Search Field & Quick Add
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                Expanded(
                  child: AppSearchField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    placeholder: 'Search client by name or phone...',
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.trim().toLowerCase();
                      });
                    },
                    onSubmitted: (value) {
                      if (filtered.length == 1) {
                        _selectAndPop(filtered.first);
                      }
                    },
                  ),
                ),
                if (widget.onCreateClient != null) ...[
                  const SizedBox(width: AppSpacing.sm),
                  AppButton(
                    text: 'New',
                    icon: const Icon(CupertinoIcons.plus, size: 13),
                    size: AppButtonSize.compact,
                    onPressed: _handleCreateClient,
                  ),
                ],
              ],
            ),
          ),

          // Divider
          Container(height: 1.0, color: AppColors.separator(context)),

          // Scrollable Client List
          Expanded(
            child: _clients.isEmpty
                ? Center(
                    child: AppEmptyState(
                      icon: CupertinoIcons.person_crop_circle_badge_exclam,
                      title: 'No Clients Available',
                      description:
                          'Please add a client before selecting one for records.',
                      actionLabel: widget.onCreateClient != null
                          ? 'Create Client'
                          : null,
                      onAction: widget.onCreateClient != null
                          ? _handleCreateClient
                          : null,
                    ),
                  )
                : filtered.isEmpty
                ? Center(
                    child: AppEmptyState(
                      icon: CupertinoIcons.search,
                      title: 'No Clients Found',
                      description:
                          'No clients match "$_searchQuery". Try a different search.',
                    ),
                  )
                : CupertinoScrollbar(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.xs,
                      ),
                      itemCount: filtered.length,
                      separatorBuilder: (context, index) => Container(
                        margin: const EdgeInsets.only(left: 64.0),
                        height: 0.5,
                        color: AppColors.separator(context),
                      ),
                      itemBuilder: (context, index) {
                        final client = filtered[index];
                        final isSelected =
                            widget.selectedClient?.id == client.id;
                        return _ClientItemTile(
                          client: client,
                          isSelected: isSelected,
                          initials: _getInitials(client.name),
                          onTap: () => _selectAndPop(client),
                        );
                      },
                    ),
                  ),
          ),

          // Footer
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: AppColors.surfaceSecondary(context).withValues(alpha: 0.5),
              border: Border(
                top: BorderSide(color: AppColors.separator(context)),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Click a client to select immediately',
                    style: AppTypography.caption2.copyWith(
                      color: AppColors.textTertiary(context),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                AppButton(
                  text: 'Cancel',
                  size: AppButtonSize.compact,
                  variant: AppButtonVariant.plain,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ClientItemTile extends StatefulWidget {
  const _ClientItemTile({
    required this.client,
    required this.isSelected,
    required this.initials,
    required this.onTap,
  });

  final Client client;
  final bool isSelected;
  final String initials;
  final VoidCallback onTap;

  @override
  State<_ClientItemTile> createState() => _ClientItemTileState();
}

class _ClientItemTileState extends State<_ClientItemTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final client = widget.client;
    final isSelected = widget.isSelected;

    final backgroundColor = isSelected
        ? AppColors.selected(context)
        : _isHovered
        ? AppColors.hover(context)
        : AppColors.surface(context);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: AppDurations.quick,
          curve: AppDurations.smoothEaseOut,
          color: backgroundColor,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              // Initials Avatar with Gradient
              Container(
                width: 38.0,
                height: 38.0,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppGradients.avatarFor(client.name),
                  boxShadow: [
                    BoxShadow(
                      color: AppGradients.avatarFor(
                        client.name,
                      ).colors.first.withValues(alpha: 0.28),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  border: Border.all(
                    color: CupertinoColors.white.withValues(alpha: 0.3),
                    width: 1.0,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  widget.initials,
                  style: AppTypography.footnote.copyWith(
                    fontWeight: FontWeight.w700,
                    color: CupertinoColors.white,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),

              // Client details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            client.name,
                            style: AppTypography.body.copyWith(
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              color: isSelected
                                  ? AppColors.primaryAccent(context)
                                  : AppColors.textPrimary(context),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isSelected) ...[
                          const SizedBox(width: AppSpacing.xs),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryAccent(
                                context,
                              ).withValues(alpha: 0.12),
                              borderRadius: AppRadii.pillRadius,
                            ),
                            child: Text(
                              'Selected',
                              style: AppTypography.caption2.copyWith(
                                color: AppColors.primaryAccent(context),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2.0),
                    Row(
                      children: [
                        if (client.phone != null &&
                            client.phone!.isNotEmpty) ...[
                          Icon(
                            CupertinoIcons.phone,
                            size: 11.0,
                            color: AppColors.textSecondary(context),
                          ),
                          const SizedBox(width: 4.0),
                          Text(
                            client.phone!,
                            style: AppTypography.caption1.copyWith(
                              color: AppColors.textSecondary(context),
                            ),
                          ),
                        ] else ...[
                          Text(
                            'No phone number',
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

              // Selection indicator
              const SizedBox(width: AppSpacing.sm),
              if (isSelected)
                Icon(
                  CupertinoIcons.checkmark_circle_fill,
                  color: AppColors.primaryAccent(context),
                  size: 20.0,
                )
              else if (_isHovered)
                Icon(
                  CupertinoIcons.checkmark_circle,
                  color: AppColors.textTertiary(context),
                  size: 20.0,
                )
              else
                const SizedBox(width: 20.0),
            ],
          ),
        ),
      ),
    );
  }
}
