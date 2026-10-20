/// Shared design system, Apple-inspired Cupertino components,
/// design tokens, and presentation components.
library;

// Tokens
export 'src/tokens/app_colors.dart';
export 'src/tokens/app_durations.dart';
export 'src/tokens/app_gradients.dart';
export 'src/tokens/app_radii.dart';
export 'src/tokens/app_spacing.dart';
export 'src/tokens/app_theme.dart';
export 'src/tokens/app_typography.dart';

// Components - Buttons
export 'src/components/buttons/app_button.dart';
export 'src/components/buttons/app_icon_button.dart';

// Components - Inputs
export 'src/components/inputs/app_money_field.dart';
export 'src/components/inputs/app_search_field.dart';
export 'src/components/inputs/app_segmented_filter.dart';
export 'src/components/inputs/app_text_field.dart';

// Components - Surfaces
export 'src/components/surfaces/app_atmospheric_background.dart';
export 'src/components/surfaces/app_badge.dart';
export 'src/components/surfaces/app_card.dart';
export 'src/components/surfaces/app_divider.dart';
export 'src/components/surfaces/app_metric_card.dart';
export 'src/components/surfaces/app_modern_icon.dart';
export 'src/components/surfaces/app_money_display.dart';

// Components - Feedback
export 'src/components/feedback/app_blurred_dialog.dart';
export 'src/components/feedback/app_confirmation_dialog.dart';
export 'src/components/feedback/app_empty_state.dart';
export 'src/components/feedback/app_error_state.dart';
export 'src/components/feedback/app_skeleton.dart';

// Components - Navigation
export 'src/components/navigation/app_page_header.dart';
export 'src/components/navigation/app_page_route.dart';
export 'src/components/navigation/desktop_sidebar.dart';
export 'src/components/navigation/mobile_tab_scaffold.dart';

// Components - Animation & Transitions
export 'src/components/animation/animated_content_switcher.dart';
export 'src/components/animation/animated_indexed_stack.dart';
export 'src/components/animation/animated_selection_container.dart';
export 'src/components/animation/app_expandable_section.dart';
export 'src/components/animation/app_staggered_item.dart';

// Responsive
export 'src/responsive/responsive_layout.dart';

// Features - Dashboard
export 'src/features/dashboard/view_models/dashboard_state.dart';
export 'src/features/dashboard/view_models/dashboard_view_model.dart';

// Features - Clients Presentation
export 'src/features/clients/view_models/client_detail_state.dart';
export 'src/features/clients/view_models/client_detail_view_model.dart';
export 'src/features/clients/view_models/client_form_state.dart';
export 'src/features/clients/view_models/client_form_view_model.dart';
export 'src/features/clients/view_models/client_list_state.dart';
export 'src/features/clients/view_models/client_list_view_model.dart';
export 'src/features/clients/widgets/client_financial_pill.dart';
export 'src/features/clients/widgets/client_form_dialog.dart';
export 'src/features/clients/widgets/client_list_row.dart';
export 'src/features/clients/widgets/client_select_dialog.dart';

// Features - Invoices Presentation
export 'src/features/invoices/view_models/invoice_detail_state.dart';
export 'src/features/invoices/view_models/invoice_detail_view_model.dart';
export 'src/features/invoices/view_models/invoice_form_state.dart';
export 'src/features/invoices/view_models/invoice_form_view_model.dart';
export 'src/features/invoices/view_models/invoice_list_state.dart';
export 'src/features/invoices/view_models/invoice_list_view_model.dart';
export 'src/features/invoices/widgets/invoice_form_dialog.dart';
export 'src/features/invoices/widgets/invoice_print_preview_dialog.dart';

// Features - Authentication & Role-Based Access Control (RBAC)
export 'src/features/auth/view_models/auth_state.dart';
export 'src/features/auth/view_models/auth_view_model.dart';
export 'src/features/auth/widgets/app_access_denied_state.dart';
export 'src/features/auth/widgets/auth_screen.dart';
export 'src/features/auth/widgets/custom_role_form_dialog.dart';
export 'src/features/auth/widgets/rbac_management_panel.dart';

// Features - Payments Presentation
export 'src/features/payments/view_models/payment_detail_state.dart';
export 'src/features/payments/view_models/payment_detail_view_model.dart';
export 'src/features/payments/view_models/payment_form_state.dart';
export 'src/features/payments/view_models/payment_form_view_model.dart';
export 'src/features/payments/view_models/payment_list_state.dart';
export 'src/features/payments/view_models/payment_list_view_model.dart';
export 'src/features/payments/widgets/payment_form_dialog.dart';

// Features - Allocations Presentation
export 'src/features/allocations/view_models/allocation_workflow_state.dart';
export 'src/features/allocations/view_models/allocation_workflow_view_model.dart';
export 'src/features/allocations/widgets/allocation_dialog.dart';

// Features - Financial Overview
export 'src/features/financial/view_models/financial_overview_state.dart';
export 'src/features/financial/view_models/financial_overview_view_model.dart';

// Features - Sync Status Diagnostics
export 'src/features/sync_status/view_models/sync_status_state.dart';
export 'src/features/sync_status/view_models/sync_status_view_model.dart';

// Features - Settings & Preferences
export 'src/features/settings/view_models/settings_state.dart';
export 'src/features/settings/view_models/settings_view_model.dart';

// Dependency Injection & Scoping
export 'src/di/app_dependencies.dart';
export 'src/di/app_scope.dart';

// Flutter types
export 'package:flutter/material.dart' show ThemeMode;
