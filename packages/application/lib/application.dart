/// Pure Dart application layer for the offline-first debt management application.
library;

export 'src/common/result.dart';

// Repositories & Unit of Work
export 'src/repositories/client_repository.dart';
export 'src/repositories/invoice_repository.dart';
export 'src/repositories/payment_allocation_repository.dart';
export 'src/repositories/payment_repository.dart';
export 'src/repositories/repository.dart';
export 'src/repositories/role_repository.dart';
export 'src/repositories/unit_of_work.dart';
export 'src/repositories/user_repository.dart';

// Authentication & RBAC
export 'src/auth/commands/create_custom_role.dart';
export 'src/auth/commands/create_custom_role_command.dart';
export 'src/auth/commands/login_user.dart';
export 'src/auth/commands/login_user_command.dart';
export 'src/auth/commands/register_user.dart';
export 'src/auth/commands/register_user_command.dart';
export 'src/auth/commands/update_role.dart';
export 'src/auth/commands/update_role_command.dart';
export 'src/auth/commands/update_user_role.dart';
export 'src/auth/commands/update_user_role_command.dart';
export 'src/auth/queries/verify_session.dart';
export 'src/auth/queries/verify_session_query.dart';

// Clients
export 'src/clients/commands/create_client.dart';
export 'src/clients/commands/create_client_command.dart';
export 'src/clients/commands/update_client.dart';
export 'src/clients/commands/update_client_command.dart';
export 'src/clients/queries/get_client_by_id.dart';
export 'src/clients/queries/get_client_by_id_query.dart';

// Invoices
export 'src/invoices/commands/create_invoice.dart';
export 'src/invoices/commands/create_invoice_command.dart';
export 'src/invoices/commands/issue_invoice.dart';
export 'src/invoices/commands/issue_invoice_command.dart';
export 'src/invoices/commands/update_invoice_draft.dart';
export 'src/invoices/commands/update_invoice_draft_command.dart';
export 'src/invoices/queries/get_invoice_by_id.dart';
export 'src/invoices/queries/get_invoice_by_id_query.dart';

// Payments
export 'src/payments/commands/record_payment.dart';
export 'src/payments/commands/record_payment_command.dart';
export 'src/payments/queries/get_payment_by_id.dart';
export 'src/payments/queries/get_payment_by_id_query.dart';

// Payment Allocations
export 'src/payment_allocations/commands/allocate_payment.dart';
export 'src/payment_allocations/commands/allocate_payment_command.dart';
export 'src/payment_allocations/queries/get_payment_allocation_by_id.dart';
export 'src/payment_allocations/queries/get_payment_allocation_by_id_query.dart';

// Financial
export 'src/financial/models/dashboard_summary.dart';
export 'src/financial/queries/get_client_financial_position.dart';
export 'src/financial/queries/get_client_financial_position_query.dart';
export 'src/financial/queries/get_dashboard_summary.dart';
export 'src/financial/queries/get_dashboard_summary_query.dart';
