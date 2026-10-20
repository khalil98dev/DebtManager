/// Granular application permissions for Role-Based Access Control (RBAC).
enum AppPermission {
  viewDashboard(
    label: 'View Dashboard & Financials',
    description: 'Access portfolio KPIs, net balances, and financial overviews.',
    category: 'Analytics & System',
  ),
  viewClients(
    label: 'View Clients',
    description: 'Browse client directory and contact profiles.',
    category: 'Clients',
  ),
  manageClients(
    label: 'Create & Edit Clients',
    description: 'Add new client accounts and update contact records.',
    category: 'Clients',
  ),
  viewInvoices(
    label: 'View Invoices',
    description: 'Browse draft and issued invoices and line items.',
    category: 'Invoices',
  ),
  manageInvoices(
    label: 'Create & Edit Invoice Drafts',
    description: 'Create new invoice drafts and modify draft line items.',
    category: 'Invoices',
  ),
  issueInvoices(
    label: 'Issue Invoices',
    description: 'Formally issue draft invoices to record legal client debt.',
    category: 'Invoices',
  ),
  printInvoices(
    label: 'Print Invoices',
    description: 'Generate and print formatted invoice documents and receipts.',
    category: 'Invoices',
  ),
  viewPayments(
    label: 'View Payments',
    description: 'Browse recorded client payments and receipts.',
    category: 'Payments & Allocations',
  ),
  recordPayments(
    label: 'Record Payments',
    description: 'Record new incoming payments from clients.',
    category: 'Payments & Allocations',
  ),
  manageAllocations(
    label: 'Manage Payment Allocations',
    description: 'Allocate unallocated payment funds against issued invoices.',
    category: 'Payments & Allocations',
  ),
  viewSyncStatus(
    label: 'View Sync Diagnostics',
    description: 'Inspect offline sync outbox queue and replication telemetry.',
    category: 'Analytics & System',
  ),
  manageSettings(
    label: 'Manage Preferences',
    description: 'Configure theme, primary currency, and view DB diagnostics.',
    category: 'Analytics & System',
  ),
  manageUsersAndRoles(
    label: 'Manage Users & Custom Roles',
    description: 'Create user accounts, assign roles, and define custom roles.',
    category: 'Administration',
  );

  const AppPermission({
    required this.label,
    required this.description,
    required this.category,
  });

  final String label;
  final String description;
  final String category;

  /// All available permissions granted to the system Admin role.
  static Set<AppPermission> get allPermissions =>
      Set<AppPermission>.unmodifiable(AppPermission.values.toSet());

  /// Base permissions for the non-admin Operator/Cashier role:
  /// Can view operational records, print invoices, and record payments.
  static Set<AppPermission> get operatorBasePermissions =>
      Set<AppPermission>.unmodifiable(const {
        AppPermission.viewClients,
        AppPermission.viewInvoices,
        AppPermission.printInvoices,
        AppPermission.viewPayments,
        AppPermission.recordPayments,
        AppPermission.manageSettings,
      });

  /// Resolves an [AppPermission] by enum name, returning `null` if unknown.
  static AppPermission? tryFromName(String name) {
    for (final value in AppPermission.values) {
      if (value.name == name) return value;
    }
    return null;
  }
}
