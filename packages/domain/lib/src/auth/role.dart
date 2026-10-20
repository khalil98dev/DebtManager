import 'package:meta/meta.dart';

import '../common/validation_utils.dart';
import 'permission.dart';
import 'role_id.dart';

/// Represents an access-control role holding a set of [AppPermission]s.
///
/// Supports built-in system roles (`Admin` and `Operator / Cashier`) as well as
/// user-defined custom roles with granular permission sets.
@immutable
class Role {
  Role({
    required this.id,
    required String name,
    String? description,
    required Iterable<AppPermission> permissions,
    this.isSystem = false,
    required this.createdAt,
    DateTime? updatedAt,
  }) : name = ValidationUtils.validateAndTrimRequired(
         name,
         name: 'name',
         message: 'Role name cannot be empty.',
       ),
       description = ValidationUtils.normalizeOptionalString(description),
       permissions = Set<AppPermission>.unmodifiable(permissions.toSet()),
       updatedAt = updatedAt ?? createdAt {
    if (this.permissions.isEmpty) {
      throw ArgumentError.value(
        permissions,
        'permissions',
        'A role must grant at least one permission.',
      );
    }
  }

  factory Role.create({
    RoleId? id,
    required String name,
    String? description,
    required Iterable<AppPermission> permissions,
    bool isSystem = false,
    DateTime? createdAt,
  }) {
    final now = createdAt ?? DateTime.now();
    return Role(
      id: id ?? RoleId.generate(),
      name: name,
      description: description,
      permissions: permissions,
      isSystem: isSystem,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Stable identifier for the built-in Administrator role.
  static final RoleId adminRoleId = RoleId('role_admin');

  /// Stable identifier for the built-in Operator / Cashier role.
  static final RoleId operatorRoleId = RoleId('role_operator');

  /// Creates the built-in Admin role with full permissions.
  factory Role.systemAdmin({DateTime? createdAt}) {
    final epoch = createdAt ?? DateTime.utc(2026, 1, 1);
    return Role(
      id: adminRoleId,
      name: 'Admin',
      description:
          'Full access to all operations, financial analytics, and user/role administration.',
      permissions: AppPermission.allPermissions,
      isSystem: true,
      createdAt: epoch,
      updatedAt: epoch,
    );
  }

  /// Creates the built-in base Operator / Cashier role that can print invoices and record payments.
  factory Role.systemOperator({DateTime? createdAt}) {
    final epoch = createdAt ?? DateTime.utc(2026, 1, 1);
    return Role(
      id: operatorRoleId,
      name: 'Operator',
      description:
          'Base operational role: can view records, print invoices, and record payments.',
      permissions: AppPermission.operatorBasePermissions,
      isSystem: true,
      createdAt: epoch,
      updatedAt: epoch,
    );
  }

  final RoleId id;
  final String name;
  final String? description;
  final Set<AppPermission> permissions;
  final bool isSystem;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isAdmin =>
      id == adminRoleId ||
      permissions.contains(AppPermission.manageUsersAndRoles);

  bool hasPermission(AppPermission permission) =>
      permissions.contains(permission);

  Role copyWith({
    String? name,
    String? description,
    Iterable<AppPermission>? permissions,
    DateTime? updatedAt,
  }) {
    return Role(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      permissions: permissions ?? this.permissions,
      isSystem: isSystem,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Role && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Role(id: $id, name: $name, permissions: ${permissions.length}, isSystem: $isSystem)';
}
