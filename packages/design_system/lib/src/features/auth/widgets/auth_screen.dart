import 'package:domain/domain.dart';
import 'package:flutter/cupertino.dart';

import '../../../components/buttons/app_button.dart';
import '../../../components/inputs/app_segmented_filter.dart';
import '../../../components/inputs/app_text_field.dart';
import '../../../components/surfaces/app_atmospheric_background.dart';
import '../../../components/surfaces/app_badge.dart';
import '../../../components/surfaces/app_modern_icon.dart';
import '../../../tokens/app_colors.dart';
import '../../../tokens/app_gradients.dart';
import '../../../tokens/app_radii.dart';
import '../../../tokens/app_spacing.dart';
import '../../../tokens/app_typography.dart';
import '../view_models/auth_state.dart';
import '../view_models/auth_view_model.dart';

/// Responsive Login and Initial Account Creation Screen ("Create Account in the start").
///
/// Features:
/// - Automatically boots into First-Account Admin Setup when no users exist in SQLite.
/// - Supports switching between "Sign In" and "Create Account" with Role selection.
/// - Issues and validates signed HS256 JWT tokens with role permissions.
class AuthScreen extends StatefulWidget {
  const AuthScreen({
    super.key,
    required this.authViewModel,
  });

  final AuthViewModel authViewModel;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _displayNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _displayNameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit(AuthViewState state) async {
    if (state.formMode == AuthFormMode.createAccount) {
      await widget.authViewModel.register(
        username: _usernameController.text,
        displayName: _displayNameController.text,
        password: _passwordController.text,
        roleId: state.isFirstAccountSetup
            ? Role.adminRoleId
            : state.selectedRoleId,
      );
    } else {
      await widget.authViewModel.login(
        username: _usernameController.text,
        password: _passwordController.text,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.canvas(context),
      child: AppAtmosphericBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: ListenableBuilder(
                listenable: widget.authViewModel,
                builder: (context, _) {
                  final state = widget.authViewModel.state;
                  final isCreate = state.formMode == AuthFormMode.createAccount;
                  final isFirstSetup = state.isFirstAccountSetup;

                  return ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      decoration: BoxDecoration(
                        color: AppColors.surface(context),
                        borderRadius: AppRadii.lgRadius,
                        border: Border.all(color: AppColors.border(context)),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x0F000000),
                            blurRadius: 24,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Brand Icon & Security Pill
                          Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: AppSpacing.xs,
                            runSpacing: AppSpacing.xs,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12.0),
                                child: Image.asset(
                                  'assets/icons/app_icon.png',
                                  package: 'design_system',
                                  width: 48.0,
                                  height: 48.0,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      AppModernIcon(
                                        icon: isFirstSetup
                                            ? CupertinoIcons
                                                  .shield_lefthalf_fill
                                            : CupertinoIcons.lock_shield_fill,
                                        size: 48,
                                        iconSize: 24,
                                        gradient: AppGradients.primary(context),
                                      ),
                                ),
                              ),
                              AppBadge(
                                label: isFirstSetup
                                    ? 'FIRST RUN · ADMIN SETUP'
                                    : 'JWT + RBAC SECURED',
                                variant: isFirstSetup
                                    ? AppBadgeVariant.accent
                                    : AppBadgeVariant.success,
                              ),
                            ],
                          ),

                          const SizedBox(height: AppSpacing.lg),

                          // Headline & Subtitle
                          Text(
                            isFirstSetup
                                ? 'Create Admin Account'
                                : (isCreate
                                      ? 'Create New Account'
                                      : 'Sign In to Debt Manager'),
                            style: AppTypography.title1.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary(context),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            isFirstSetup
                                ? 'Welcome! Create the first account to initialize the workspace with full Admin privileges and JWT security.'
                                : (isCreate
                                      ? 'Register an account and select an access control role.'
                                      : 'Enter your credentials to receive a signed JWT session token.'),
                            style: AppTypography.subheadline.copyWith(
                              color: AppColors.textSecondary(context),
                            ),
                          ),

                          // Mode Switcher when accounts already exist
                          if (!isFirstSetup) ...[
                            const SizedBox(height: AppSpacing.lg),
                            SizedBox(
                              width: double.infinity,
                              child: AppSegmentedFilter<AuthFormMode>(
                                value: state.formMode,
                                segments: const {
                                  AuthFormMode.signIn: 'Sign In',
                                  AuthFormMode.createAccount: 'Create Account',
                                },
                                onChanged: widget.authViewModel.setFormMode,
                              ),
                            ),
                          ],

                          const SizedBox(height: AppSpacing.lg),

                          // Single-column form inputs (UI-Skills standard)
                          if (isCreate) ...[
                            AppTextField(
                              key: const ValueKey('auth_display_name_field'),
                              controller: _displayNameController,
                              label: 'Full Name',
                              placeholder: 'e.g. Khalil Admin',
                              isRequired: true,
                              onChanged: (_) =>
                                  widget.authViewModel.clearError(),
                            ),
                            const SizedBox(height: AppSpacing.md),
                          ],

                          AppTextField(
                            key: const ValueKey('auth_username_field'),
                            controller: _usernameController,
                            label: 'Username',
                            placeholder: 'e.g. admin',
                            isRequired: true,
                            onChanged: (_) => widget.authViewModel.clearError(),
                          ),

                          const SizedBox(height: AppSpacing.md),

                          AppTextField(
                            key: const ValueKey('auth_password_field'),
                            controller: _passwordController,
                            label: 'Password',
                            placeholder: isCreate
                                ? 'At least 6 characters'
                                : 'Enter your password',
                            obscureText: _obscurePassword,
                            isRequired: true,
                            onChanged: (_) => widget.authViewModel.clearError(),
                            onSubmitted: (_) => _handleSubmit(state),
                            suffix: Padding(
                              padding: const EdgeInsets.only(
                                right: AppSpacing.xs,
                              ),
                              child: CupertinoButton(
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(28, 28),
                                onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                                child: Icon(
                                  _obscurePassword
                                      ? CupertinoIcons.eye
                                      : CupertinoIcons.eye_slash,
                                  size: 16,
                                  color: AppColors.textTertiary(context),
                                ),
                              ),
                            ),
                          ),

                          // Role Selection on Sign Up (when not first-account bootstrap)
                          if (isCreate && !isFirstSetup) ...[
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              'Account Role',
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
                                for (final role in state.availableRoles)
                                  AppButton(
                                    text: role.name,
                                    size: AppButtonSize.compact,
                                    variant:
                                        (state.selectedRoleId ??
                                                Role.operatorRoleId) ==
                                            role.id
                                        ? AppButtonVariant.primary
                                        : AppButtonVariant.secondary,
                                    onPressed: () => widget.authViewModel
                                        .setSelectedRoleId(role.id),
                                  ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            _buildSelectedRoleHint(context, state),
                          ] else if (isFirstSetup) ...[
                            const SizedBox(height: AppSpacing.md),
                            Container(
                              padding: const EdgeInsets.all(AppSpacing.sm),
                              decoration: BoxDecoration(
                                color: AppColors.primaryAccent(
                                  context,
                                ).withValues(alpha: 0.08),
                                borderRadius: AppRadii.smRadius,
                                border: Border.all(
                                  color: AppColors.primaryAccent(
                                    context,
                                  ).withValues(alpha: 0.25),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    CupertinoIcons.checkmark_shield_fill,
                                    size: 16,
                                    color: AppColors.primaryAccent(context),
                                  ),
                                  const SizedBox(width: AppSpacing.xs),
                                  Expanded(
                                    child: Text(
                                      'Role: Admin (Full Access + Custom Role & User Management)',
                                      style: AppTypography.caption1.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primaryAccent(context),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          // Inline Error Banner
                          if (state.errorMessage != null) ...[
                            const SizedBox(height: AppSpacing.md),
                            Container(
                              padding: const EdgeInsets.all(AppSpacing.sm),
                              decoration: BoxDecoration(
                                color: AppColors.destructive(
                                  context,
                                ).withValues(alpha: 0.1),
                                borderRadius: AppRadii.smRadius,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    CupertinoIcons.exclamationmark_triangle_fill,
                                    size: 16,
                                    color: AppColors.destructive(context),
                                  ),
                                  const SizedBox(width: AppSpacing.xs),
                                  Expanded(
                                    child: Text(
                                      state.errorMessage!,
                                      style: AppTypography.caption1.copyWith(
                                        color: AppColors.destructive(context),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: AppSpacing.xl),

                          // Primary Commit CTA
                          SizedBox(
                            width: double.infinity,
                            child: AppButton(
                              key: const ValueKey('auth_submit_button'),
                              text: isFirstSetup
                                  ? 'Create Admin Account & Start'
                                  : (isCreate ? 'Create Account' : 'Sign In'),
                              icon: Icon(
                                isCreate
                                    ? CupertinoIcons.person_badge_plus_fill
                                    : CupertinoIcons.lock_open_fill,
                                size: 15,
                              ),
                              variant: AppButtonVariant.primary,
                              isLoading: state.isAuthenticating,
                              onPressed: state.isAuthenticating
                                  ? null
                                  : () => _handleSubmit(state),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedRoleHint(BuildContext context, AuthViewState state) {
    final targetId = state.selectedRoleId ?? Role.operatorRoleId;
    final selectedRole = state.availableRoles
        .where((r) => r.id == targetId)
        .firstOrNull;
    final description =
        selectedRole?.description ??
        'Can view records, print invoices, and record payments.';

    return Text(
      description,
      style: AppTypography.caption2.copyWith(
        color: AppColors.textSecondary(context),
      ),
    );
  }
}
