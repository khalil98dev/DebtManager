import 'package:meta/meta.dart';

import '../common/validation_utils.dart';
import 'role_id.dart';
import 'user_id.dart';

/// Represents an authenticated user account with an assigned [RoleId].
@immutable
class User {
  User({
    required this.id,
    required String username,
    required String displayName,
    required String passwordHash,
    required this.roleId,
    this.isActive = true,
    required this.createdAt,
    DateTime? updatedAt,
  }) : username = ValidationUtils.validateAndTrimRequired(
         username,
         name: 'username',
         message: 'Username cannot be empty.',
       ).toLowerCase(),
       displayName = ValidationUtils.validateAndTrimRequired(
         displayName,
         name: 'displayName',
         message: 'Display name cannot be empty.',
       ),
       passwordHash = ValidationUtils.validateAndTrimRequired(
         passwordHash,
         name: 'passwordHash',
         message: 'Password hash cannot be empty.',
       ),
       updatedAt = updatedAt ?? createdAt;

  factory User.create({
    UserId? id,
    required String username,
    required String displayName,
    required String passwordHash,
    required RoleId roleId,
    bool isActive = true,
    DateTime? createdAt,
  }) {
    final now = createdAt ?? DateTime.now();
    return User(
      id: id ?? UserId.generate(),
      username: username,
      displayName: displayName,
      passwordHash: passwordHash,
      roleId: roleId,
      isActive: isActive,
      createdAt: now,
      updatedAt: now,
    );
  }

  final UserId id;
  final String username;
  final String displayName;
  final String passwordHash;
  final RoleId roleId;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  User changeRole(RoleId newRoleId, {DateTime? updatedAt}) {
    return User(
      id: id,
      username: username,
      displayName: displayName,
      passwordHash: passwordHash,
      roleId: newRoleId,
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  User copyWith({
    String? displayName,
    String? passwordHash,
    RoleId? roleId,
    bool? isActive,
    DateTime? updatedAt,
  }) {
    return User(
      id: id,
      username: username,
      displayName: displayName ?? this.displayName,
      passwordHash: passwordHash ?? this.passwordHash,
      roleId: roleId ?? this.roleId,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is User && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'User(id: $id, username: $username, displayName: $displayName, roleId: $roleId, isActive: $isActive)';
}
