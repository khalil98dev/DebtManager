import 'package:domain/domain.dart';
import 'package:flutter/cupertino.dart';

import '../../../components/buttons/app_button.dart';
import '../../../components/buttons/app_icon_button.dart';
import '../../../components/feedback/app_blurred_dialog.dart';
import '../../../components/inputs/app_text_field.dart';
import '../../../components/surfaces/app_badge.dart';
import '../../../components/surfaces/app_modern_icon.dart';
import '../../../tokens/app_colors.dart';
import '../../../tokens/app_gradients.dart';
import '../../../tokens/app_radii.dart';
import '../../../tokens/app_spacing.dart';
import '../../../tokens/app_typography.dart';
import '../view_models/auth_view_model.dart';
import 'custom_role_form_dialog.dart';

/// Displays active JWT session details, sign-out controls, and (for Admins)
/// Role-Based Access Control (RBAC) custom role and user management.
class RbacManagementPanel extends StatefulWidget {
  const RbacManagementPanel({
    super.key,
    required this.authViewModel,
  });

  final AuthViewModel authViewModel;

  @override
  State<RbacManagementPanel> createState() => _RbacManagementPanelState();
}

class _RbacManagementPanelState extends State<RbacManagementPanel> {
  bool _showJwtDetails = false;

  @override
  void initState() {
    super.initState();
    widget.authViewModel.refreshDirectory();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.authViewModel,
      builder: (context, _) {
        final state = widget.authViewModel.state;
        final session = state.session;
        final canManageRbac =
            session == null ||
            session.hasPermission(AppPermission.manageUsersAndRoles);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Active JWT Session Card
            _buildJwtSessionCard(context, session),

            if (canManageRbac) ...[
              const SizedBox(height: AppSpacing.lg),
              // 2. Roles & Custom Permissions Manager
              _buildRolesCard(context, state.availableRoles),

              const SizedBox(height: AppSpacing.lg),
              // 3. User Accounts & Role Assignment
              _buildUsersCard(context, state.users, state.availableRoles),
            ],
          ],
        );
      },
    );
  }

  Widget _buildJwtSessionCard(BuildContext context, AuthSession? session) {
    final userName = session?.user.displayName ?? 'Authenticated Session';
    final usernameHandle = session != null ? '@${session.user.username}' : '';
    final roleName = session?.role.name ?? 'Admin';
    final isAdmin = session?.isAdmin ?? true;
    final permissions =
        session?.role.permissions ?? AppPermission.allPermissions;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: AppRadii.lgRadius,
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                AppModernIcon(
                  icon: isAdmin
                      ? CupertinoIcons.shield_lefthalf_fill
                      : CupertinoIcons.person_crop_circle_fill_badge_checkmark,
                  size: 42,
                  gradient: isAdmin
                      ? AppGradients.primary(context)
                      : AppGradients.success(context),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            userName,
                            style: AppTypography.headline.copyWith(
                              fontSize: 16,
                              color: AppColors.textPrimary(context),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          AppBadge(
                            label: roleName.toUpperCase(),
                            variant: isAdmin
                                ? AppBadgeVariant.accent
                                : AppBadgeVariant.success,
                          ),
                          const AppBadge(
                            label: 'JWT VERIFIED',
                            variant: AppBadgeVariant.neutral,
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$usernameHandle · ${permissions.length} active permissions granted',
                        style: AppTypography.caption1.copyWith(
                          color: AppColors.textSecondary(context),
                        ),
                      ),
                    ],
                  ),
                ),
                if (session != null) ...[
                  AppButton(
                    text: _showJwtDetails ? 'Hide JWT' : 'Inspect JWT',
                    size: AppButtonSize.compact,
                    variant: AppButtonVariant.plain,
                    onPressed: () =>
                        setState(() => _showJwtDetails = !_showJwtDetails),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  AppButton(
                    text: 'Sign Out',
                    icon: const Icon(
                      CupertinoIcons.square_arrow_right,
                      size: 14,
                    ),
                    size: AppButtonSize.compact,
                    variant: AppButtonVariant.destructive,
                    onPressed: widget.authViewModel.logout,
                  ),
                ],
              ],
            ),
          ),
          if (_showJwtDetails && session != null) ...[
            Container(height: 1, color: AppColors.separator(context)),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SIGNED HS256 JWT TOKEN',
                    style: AppTypography.caption2.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textTertiary(context),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.canvas(context),
                      borderRadius: AppRadii.smRadius,
                      border: Border.all(color: AppColors.border(context)),
                    ),
                    child: Text(
                      session.jwtToken,
                      style: AppTypography.caption2.copyWith(
                        fontFamily: 'monospace',
                        color: AppColors.textSecondary(context),
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: [
                      for (final perm in permissions)
                        AppBadge(
                          label: perm.label,
                          variant: AppBadgeVariant.neutral,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRolesCard(BuildContext context, List<Role> roles) {
    final effectiveRoles = roles.isEmpty
        ? [Role.systemAdmin(), Role.systemOperator()]
        : roles;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: AppRadii.lgRadius,
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Roles & Custom Permissions (RBAC)',
                        style: AppTypography.headline.copyWith(
                          fontSize: 16,
                          color: AppColors.textPrimary(context),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        'Admin has full access; Operator can print invoices & record payments; create custom roles as needed.',
                        style: AppTypography.caption1.copyWith(
                          color: AppColors.textSecondary(context),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                AppButton(
                  text: 'New Custom Role',
                  icon: const Icon(CupertinoIcons.plus, size: 14),
                  size: AppButtonSize.compact,
                  variant: AppButtonVariant.primary,
                  onPressed: () {
                    CustomRoleFormDialog.show(
                      context,
                      authViewModel: widget.authViewModel,
                    );
                  },
                ),
              ],
            ),
          ),
          Container(height: 1, color: AppColors.separator(context)),
          for (var i = 0; i < effectiveRoles.length; i++) ...[
            _buildRoleRow(context, effectiveRoles[i]),
            if (i < effectiveRoles.length - 1)
              Container(height: 1, color: AppColors.separator(context)),
          ],
        ],
      ),
    );
  }

  Widget _buildRoleRow(BuildContext context, Role role) {
    final isSystemAdmin = role.id == Role.adminRoleId;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      role.name,
                      style: AppTypography.body.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary(context),
                      ),
                    ),
                    AppBadge(
                      label: role.isSystem ? 'SYSTEM ROLE' : 'CUSTOM ROLE',
                      variant: role.isSystem
                          ? AppBadgeVariant.neutral
                          : AppBadgeVariant.accent,
                    ),
                    AppBadge(
                      label: '${role.permissions.length} PERMISSIONS',
                      variant: AppBadgeVariant.success,
                    ),
                  ],
                ),
                if (role.description != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    role.description!,
                    style: AppTypography.caption1.copyWith(
                      color: AppColors.textSecondary(context),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (!isSystemAdmin) ...[
            AppButton(
              text: 'Edit Permissions',
              size: AppButtonSize.compact,
              variant: AppButtonVariant.secondary,
              onPressed: () {
                CustomRoleFormDialog.show(
                  context,
                  authViewModel: widget.authViewModel,
                  initialRole: role,
                );
              },
            ),
            if (!role.isSystem) ...[
              const SizedBox(width: AppSpacing.xs),
              AppIconButton(
                icon: CupertinoIcons.trash,
                size: 30,
                iconSize: 14,
                color: AppColors.destructive(context),
                tooltip: 'Delete custom role',
                onPressed: () =>
                    widget.authViewModel.removeCustomRole(role.id),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildUsersCard(
    BuildContext context,
    List<User> users,
    List<Role> roles,
  ) {
    final rolesById = {for (final r in roles) r.id: r};

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: AppRadii.lgRadius,
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'User Accounts (${users.length})',
                        style: AppTypography.headline.copyWith(
                          fontSize: 16,
                          color: AppColors.textPrimary(context),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        'Create team member accounts and assign built-in or custom RBAC roles',
                        style: AppTypography.caption1.copyWith(
                          color: AppColors.textSecondary(context),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                AppButton(
                  text: 'Add User Account',
                  icon: const Icon(
                    CupertinoIcons.person_badge_plus_fill,
                    size: 14,
                  ),
                  size: AppButtonSize.compact,
                  variant: AppButtonVariant.secondary,
                  onPressed: () => _showCreateUserDialog(context, roles),
                ),
              ],
            ),
          ),
          Container(height: 1, color: AppColors.separator(context)),
          if (users.isEmpty)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text(
                'No persisted user accounts yet.',
                style: AppTypography.caption1.copyWith(
                  color: AppColors.textTertiary(context),
                ),
              ),
            )
          else
            for (var i = 0; i < users.length; i++) ...[
              _buildUserRow(context, users[i], rolesById[users[i].roleId], roles),
              if (i < users.length - 1)
                Container(height: 1, color: AppColors.separator(context)),
            ],
        ],
      ),
    );
  }

  Widget _buildUserRow(
    BuildContext context,
    User user,
    Role? assignedRole,
    List<Role> availableRoles,
  ) {
    final roleName = assignedRole?.name ?? 'Operator';

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: 2,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      user.displayName,
                      style: AppTypography.body.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary(context),
                      ),
                    ),
                    Text(
                      '@${user.username}',
                      style: AppTypography.caption1.copyWith(
                        color: AppColors.textSecondary(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Assigned Role: $roleName',
                  style: AppTypography.caption2.copyWith(
                    color: AppColors.textTertiary(context),
                  ),
                ),
              ],
            ),
          ),
          Wrap(
            spacing: AppSpacing.xs,
            children: [
              for (final role in availableRoles)
                AppButton(
                  text: role.name,
                  size: AppButtonSize.compact,
                  variant: user.roleId == role.id
                      ? AppButtonVariant.primary
                      : AppButtonVariant.secondary,
                  onPressed: user.roleId == role.id
                      ? null
                      : () => widget.authViewModel.assignUserRole(
                          userId: user.id,
                          roleId: role.id,
                        ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showCreateUserDialog(
    BuildContext context,
    List<Role> roles,
  ) async {
    final effectiveRoles = roles.isEmpty
        ? [Role.systemAdmin(), Role.systemOperator()]
        : roles;
    await showAppBlurredDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => _CreateManagedUserDialog(
        authViewModel: widget.authViewModel,
        roles: effectiveRoles,
      ),
    );
  }
}

class _CreateManagedUserDialog extends StatefulWidget {
  const _CreateManagedUserDialog({
    required this.authViewModel,
    required this.roles,
  });

  final AuthViewModel authViewModel;
  final List<Role> roles;

  @override
  State<_CreateManagedUserDialog> createState() =>
      _CreateManagedUserDialogState();
}

class _CreateManagedUserDialogState extends State<_CreateManagedUserDialog> {
  final _displayNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  late RoleId _selectedRoleId;
  String? _errorMessage;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedRoleId = Role.operatorRoleId;
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });
    final res = await widget.authViewModel.createManagedUser(
      username: _usernameController.text,
      displayName: _displayNameController.text,
      password: _passwordController.text,
      roleId: _selectedRoleId,
    );
    if (!mounted) return;
    if (res.isSuccess) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _isSaving = false;
        _errorMessage = res.failureOrNull?.message ?? 'Failed to create user.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBlurredDialogContainer(
      maxWidth: 480,
      maxHeight: 540,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                const AppModernIcon(
                  icon: CupertinoIcons.person_badge_plus_fill,
                  size: 38,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    'Add User Account',
                    style: AppTypography.headline.copyWith(
                      fontSize: 18,
                      color: AppColors.textPrimary(context),
                    ),
                  ),
                ),
                AppIconButton(
                  icon: CupertinoIcons.xmark,
                  size: 30,
                  iconSize: 15,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          Container(height: 1, color: AppColors.separator(context)),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                AppTextField(
                  controller: _displayNameController,
                  label: 'Full Name',
                  placeholder: 'e.g. Sarah Connor',
                  isRequired: true,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: _usernameController,
                  label: 'Username',
                  placeholder: 'e.g. sarah',
                  isRequired: true,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: _passwordController,
                  label: 'Password',
                  placeholder: 'Minimum 6 characters',
                  obscureText: true,
                  isRequired: true,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Assign Role',
                  style: AppTypography.subheadline.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary(context),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    for (final role in widget.roles)
                      AppButton(
                        text: role.name,
                        size: AppButtonSize.compact,
                        variant: _selectedRoleId == role.id
                            ? AppButtonVariant.primary
                            : AppButtonVariant.secondary,
                        onPressed: () =>
                            setState(() => _selectedRoleId = role.id),
                      ),
                  ],
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    _errorMessage!,
                    style: AppTypography.caption1.copyWith(
                      color: AppColors.destructive(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(height: 1, color: AppColors.separator(context)),
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
                  text: 'Create User',
                  variant: AppButtonVariant.primary,
                  isLoading: _isSaving,
                  onPressed: _isSaving ? null : _submit,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
