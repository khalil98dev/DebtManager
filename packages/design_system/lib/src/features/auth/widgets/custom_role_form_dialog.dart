import 'package:domain/domain.dart';
import 'package:flutter/cupertino.dart';

import '../../../components/buttons/app_button.dart';
import '../../../components/buttons/app_icon_button.dart';
import '../../../components/feedback/app_blurred_dialog.dart';
import '../../../components/inputs/app_text_field.dart';
import '../../../components/surfaces/app_badge.dart';
import '../../../components/surfaces/app_modern_icon.dart';
import '../../../tokens/app_colors.dart';
import '../../../tokens/app_radii.dart';
import '../../../tokens/app_spacing.dart';
import '../../../tokens/app_typography.dart';
import '../view_models/auth_view_model.dart';

/// Modal dialog for creating or editing a custom [Role] with custom [AppPermission]s.
class CustomRoleFormDialog extends StatefulWidget {
  const CustomRoleFormDialog({
    super.key,
    required this.authViewModel,
    this.initialRole,
  });

  final AuthViewModel authViewModel;
  final Role? initialRole;

  static Future<Role?> show(
    BuildContext context, {
    required AuthViewModel authViewModel,
    Role? initialRole,
  }) {
    return showAppBlurredDialog<Role>(
      context: context,
      barrierDismissible: true,
      builder: (context) => CustomRoleFormDialog(
        authViewModel: authViewModel,
        initialRole: initialRole,
      ),
    );
  }

  @override
  State<CustomRoleFormDialog> createState() => _CustomRoleFormDialogState();
}

class _CustomRoleFormDialogState extends State<CustomRoleFormDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late Set<AppPermission> _selectedPermissions;
  String? _errorMessage;
  bool _isSaving = false;

  bool get _isEditing => widget.initialRole != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.initialRole?.name ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.initialRole?.description ?? '',
    );
    _selectedPermissions = Set<AppPermission>.from(
      widget.initialRole?.permissions ?? AppPermission.operatorBasePermissions,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _togglePermission(AppPermission permission) {
    setState(() {
      if (_selectedPermissions.contains(permission)) {
        _selectedPermissions.remove(permission);
      } else {
        _selectedPermissions.add(permission);
      }
      _errorMessage = null;
    });
  }

  void _applyPreset(Set<AppPermission> preset) {
    setState(() {
      _selectedPermissions = Set<AppPermission>.from(preset);
      _errorMessage = null;
    });
  }

  Future<void> _handleSave() async {
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final result = _isEditing
        ? await widget.authViewModel.editRole(
            roleId: widget.initialRole!.id,
            name: _nameController.text,
            description: _descriptionController.text,
            permissions: _selectedPermissions,
          )
        : await widget.authViewModel.addCustomRole(
            name: _nameController.text,
            description: _descriptionController.text,
            permissions: _selectedPermissions,
          );

    if (!mounted) return;
    if (result.isSuccess) {
      Navigator.of(context).pop(result.dataOrNull);
    } else {
      setState(() {
        _isSaving = false;
        _errorMessage =
            result.failureOrNull?.message ?? 'Failed to save custom role.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = <String, List<AppPermission>>{};
    for (final perm in AppPermission.values) {
      categories.putIfAbsent(perm.category, () => []).add(perm);
    }

    return AppBlurredDialogContainer(
      maxWidth: 640,
      maxHeight: 780,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                const AppModernIcon(
                  icon: CupertinoIcons.shield_lefthalf_fill,
                  size: 40,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isEditing ? 'Edit Role Permissions' : 'New Custom Role',
                        style: AppTypography.headline.copyWith(
                          fontSize: 18,
                          color: AppColors.textPrimary(context),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        'Configure granular RBAC permissions encoded into JWT sessions.',
                        style: AppTypography.caption1.copyWith(
                          color: AppColors.textSecondary(context),
                        ),
                      ),
                    ],
                  ),
                ),
                AppIconButton(
                  icon: CupertinoIcons.xmark,
                  tooltip: 'Close',
                  size: 32,
                  iconSize: 16,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          Container(height: 1, color: AppColors.separator(context)),

          // Body
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                AppTextField(
                  controller: _nameController,
                  label: 'Role Name',
                  placeholder: 'e.g. Cashier, Accountant, Sales Agent',
                  isRequired: true,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: _descriptionController,
                  label: 'Role Description (Optional)',
                  placeholder:
                      'Describe what members of this role are authorized to do',
                ),
                const SizedBox(height: AppSpacing.lg),

                // Quick Presets Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Permissions (${_selectedPermissions.length} selected)',
                      style: AppTypography.headline.copyWith(
                        fontSize: 15,
                        color: AppColors.textPrimary(context),
                      ),
                    ),
                    Wrap(
                      spacing: AppSpacing.xs,
                      children: [
                        AppButton(
                          text: 'Base (Print & Payment)',
                          size: AppButtonSize.compact,
                          variant: AppButtonVariant.secondary,
                          onPressed: () => _applyPreset(
                            AppPermission.operatorBasePermissions,
                          ),
                        ),
                        AppButton(
                          text: 'Select All',
                          size: AppButtonSize.compact,
                          variant: AppButtonVariant.plain,
                          onPressed: () =>
                              _applyPreset(AppPermission.allPermissions),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),

                // Grouped Permission Checkboxes
                for (final entry in categories.entries) ...[
                  Padding(
                    padding: const EdgeInsets.only(
                      top: AppSpacing.sm,
                      bottom: AppSpacing.xs,
                    ),
                    child: Text(
                      entry.key.toUpperCase(),
                      style: AppTypography.caption2.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: AppColors.textTertiary(context),
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSecondary(context),
                      borderRadius: AppRadii.mdRadius,
                      border: Border.all(color: AppColors.border(context)),
                    ),
                    child: Column(
                      children: [
                        for (var i = 0; i < entry.value.length; i++) ...[
                          _buildPermissionRow(context, entry.value[i]),
                          if (i < entry.value.length - 1)
                            Container(
                              height: 1,
                              color: AppColors.separator(context),
                            ),
                        ],
                      ],
                    ),
                  ),
                ],

                if (_errorMessage != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.destructive(
                        context,
                      ).withValues(alpha: 0.1),
                      borderRadius: AppRadii.smRadius,
                    ),
                    child: Text(
                      _errorMessage!,
                      style: AppTypography.caption1.copyWith(
                        color: AppColors.destructive(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          Container(height: 1, color: AppColors.separator(context)),

          // Actions
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                AppButton(
                  text: 'Cancel',
                  variant: AppButtonVariant.plain,
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: AppSpacing.sm),
                AppButton(
                  text: _isEditing ? 'Save Role Changes' : 'Create Custom Role',
                  icon: const Icon(
                    CupertinoIcons.checkmark_shield_fill,
                    size: 14,
                  ),
                  variant: AppButtonVariant.primary,
                  isLoading: _isSaving,
                  onPressed: _isSaving ? null : _handleSave,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionRow(BuildContext context, AppPermission perm) {
    final isSelected = _selectedPermissions.contains(perm);
    final isBaseHighlight =
        perm == AppPermission.printInvoices ||
        perm == AppPermission.recordPayments;

    return GestureDetector(
      onTap: () => _togglePermission(perm),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? CupertinoIcons.checkmark_square_fill
                  : CupertinoIcons.square,
              size: 20,
              color: isSelected
                  ? AppColors.primaryAccent(context)
                  : AppColors.textTertiary(context),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          perm.label,
                          style: AppTypography.body.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary(context),
                          ),
                        ),
                      ),
                      if (isBaseHighlight) ...[
                        const SizedBox(width: AppSpacing.xs),
                        const AppBadge(
                          label: 'BASE',
                          variant: AppBadgeVariant.success,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    perm.description,
                    style: AppTypography.caption2.copyWith(
                      color: AppColors.textSecondary(context),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
