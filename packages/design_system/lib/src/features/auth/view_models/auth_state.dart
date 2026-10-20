import 'package:domain/domain.dart';
import 'package:flutter/foundation.dart';

enum AuthStatus {
  initializing,
  unauthenticated,
  authenticating,
  authenticated,
  error,
}

enum AuthFormMode {
  signIn,
  createAccount,
}

@immutable
class AuthViewState {
  const AuthViewState({
    this.status = AuthStatus.initializing,
    this.formMode = AuthFormMode.signIn,
    this.isFirstAccountSetup = false,
    this.session,
    this.availableRoles = const [],
    this.users = const [],
    this.selectedRoleId,
    this.errorMessage,
  });

  final AuthStatus status;
  final AuthFormMode formMode;
  final bool isFirstAccountSetup;
  final AuthSession? session;
  final List<Role> availableRoles;
  final List<User> users;
  final RoleId? selectedRoleId;
  final String? errorMessage;

  bool get isInitializing => status == AuthStatus.initializing;
  bool get isAuthenticating => status == AuthStatus.authenticating;
  bool get isAuthenticated =>
      status == AuthStatus.authenticated &&
      session != null &&
      !session!.payload.isExpired();

  User? get currentUser => session?.user;
  Role? get currentRole => session?.role;
  String? get jwtToken => session?.jwtToken;

  AuthViewState copyWith({
    AuthStatus? status,
    AuthFormMode? formMode,
    bool? isFirstAccountSetup,
    AuthSession? session,
    bool clearSession = false,
    List<Role>? availableRoles,
    List<User>? users,
    RoleId? selectedRoleId,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AuthViewState(
      status: status ?? this.status,
      formMode: formMode ?? this.formMode,
      isFirstAccountSetup: isFirstAccountSetup ?? this.isFirstAccountSetup,
      session: clearSession ? null : (session ?? this.session),
      availableRoles: availableRoles ?? this.availableRoles,
      users: users ?? this.users,
      selectedRoleId: selectedRoleId ?? this.selectedRoleId,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
