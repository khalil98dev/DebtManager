import 'package:application/application.dart';
import 'package:domain/domain.dart';
import 'package:flutter/cupertino.dart';

import '../../../components/buttons/app_button.dart';
import '../../../components/buttons/app_icon_button.dart';
import '../../../components/feedback/app_blurred_dialog.dart';
import '../../../components/inputs/app_text_field.dart';
import '../../../components/surfaces/app_modern_icon.dart';
import '../../../tokens/app_colors.dart';
import '../../../tokens/app_radii.dart';
import '../../../tokens/app_spacing.dart';
import '../../../tokens/app_typography.dart';
import '../view_models/client_form_view_model.dart';

/// Modal dialog for creating or editing client records with frosted glass blur backdrop.
class ClientFormDialog extends StatefulWidget {
  const ClientFormDialog({
    super.key,
    required this.createClient,
    required this.updateClient,
    this.initialClient,
  });

  final CreateClient createClient;
  final UpdateClient updateClient;
  final Client? initialClient;

  static Future<Client?> show(
    BuildContext context, {
    required CreateClient createClient,
    required UpdateClient updateClient,
    Client? initialClient,
  }) {
    return showAppBlurredDialog<Client>(
      context: context,
      barrierDismissible: true,
      builder: (context) => ClientFormDialog(
        createClient: createClient,
        updateClient: updateClient,
        initialClient: initialClient,
      ),
    );
  }

  @override
  State<ClientFormDialog> createState() => _ClientFormDialogState();
}

class _ClientFormDialogState extends State<ClientFormDialog> {
  late final ClientFormViewModel _viewModel;
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _viewModel = ClientFormViewModel(
      createClient: widget.createClient,
      updateClient: widget.updateClient,
      initialClient: widget.initialClient,
    );

    _nameController = TextEditingController(text: _viewModel.state.name);
    _phoneController = TextEditingController(text: _viewModel.state.phone);
    _notesController = TextEditingController(text: _viewModel.state.notes);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppBlurredDialogContainer(
      maxWidth: 500,
      child: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          final state = _viewModel.state;

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Dialog Header
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: [
                    AppModernIcon(
                      icon: state.isEditing
                          ? CupertinoIcons.pencil
                          : CupertinoIcons.person_badge_plus,
                      size: 40,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            state.isEditing ? 'Edit Client' : 'New Client',
                            style: AppTypography.headline.copyWith(
                              fontSize: 18,
                              color: AppColors.textPrimary(context),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            state.isEditing
                                ? 'Update contact and billing details'
                                : 'Add a new client to manage debts and invoices',
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

              // Dialog Form Fields
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppTextField(
                      controller: _nameController,
                      label: 'Full Name / Company',
                      placeholder: 'e.g. Acme Corporation',
                      errorText: state.nameError,
                      onChanged: _viewModel.onNameChanged,
                      autofocus: true,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      controller: _phoneController,
                      label: 'Phone Number (Optional)',
                      placeholder: 'e.g. +213 550 12 34 56',
                      keyboardType: TextInputType.phone,
                      onChanged: _viewModel.onPhoneChanged,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      controller: _notesController,
                      label: 'Internal Notes (Optional)',
                      placeholder: 'Billing terms, contract details, etc.',
                      maxLines: 3,
                      onChanged: _viewModel.onNotesChanged,
                    ),
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
                        child: Text(
                          state.errorMessage!,
                          style: AppTypography.caption1.copyWith(
                            color: AppColors.destructive(context),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              Container(height: 1, color: AppColors.separator(context)),

              // Dialog Action Buttons
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
                      text: state.isEditing ? 'Save Changes' : 'Create Client',
                      variant: AppButtonVariant.primary,
                      isLoading: state.isSubmitting,
                      onPressed: () async {
                        final saved = await _viewModel.submit();
                        if (saved != null && context.mounted) {
                          Navigator.of(context).pop(saved);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
