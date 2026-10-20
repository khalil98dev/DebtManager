import 'package:application/application.dart';
import 'package:domain/domain.dart';
import 'package:flutter/foundation.dart';

import 'auth_state.dart';

/// ViewModel managing JWT authentication, initial account setup, and Role-Based Access Control (RBAC).
class AuthViewModel extends ChangeNotifier {
  AuthViewModel({
    required this.userRepository,
    required this.roleRepository,
    this.jwtService = const JwtService(),
    RegisterUser? registerUser,
    LoginUser? loginUser,
    CreateCustomRole? createCustomRole,
    UpdateRole? updateRole,
    UpdateUserRole? updateUserRole,
    VerifySession? verifySession,
  }) : registerUser =
           registerUser ??
           RegisterUser(
             userRepository: userRepository,
             roleRepository: roleRepository,
             jwtService: jwtService,
           ),
       loginUser =
           loginUser ??
           LoginUser(
             userRepository: userRepository,
             roleRepository: roleRepository,
             jwtService: jwtService,
           ),
       createCustomRole = createCustomRole ?? CreateCustomRole(roleRepository),
       updateRole = updateRole ?? UpdateRole(roleRepository),
       updateUserRole =
           updateUserRole ??
           UpdateUserRole(
             userRepository: userRepository,
             roleRepository: roleRepository,
           ),
       verifySession =
           verifySession ??
           VerifySession(
             userRepository: userRepository,
             roleRepository: roleRepository,
             jwtService: jwtService,
           );

  final UserRepository userRepository;
  final RoleRepository roleRepository;
  final JwtService jwtService;

  final RegisterUser registerUser;
  final LoginUser loginUser;
  final CreateCustomRole createCustomRole;
  final UpdateRole updateRole;
  final UpdateUserRole updateUserRole;
  final VerifySession verifySession;

  AuthViewState _state = const AuthViewState();
  AuthViewState get state => _state;

  AuthSession? get currentSession => _state.session;
  bool get isAuthenticated => _state.isAuthenticated;

  /// Checks if the active JWT session and role grant [permission].
  bool hasPermission(AppPermission permission) {
    final session = _state.session;
    if (session == null) return false;
    if (session.payload.isExpired()) return false;
    return session.hasPermission(permission);
  }

  /// Initializes roles and checks whether any user account exists in storage.
  /// If no users exist, defaults to [AuthFormMode.createAccount] with [AuthViewState.isFirstAccountSetup] = true.
  Future<void> initialize() async {
    try {
      await roleRepository.ensureSystemRoles();
      final roles = await roleRepository.getAll();
      final users = await userRepository.getAll();
      final isFirstAccount = users.isEmpty;

      if (_state.isAuthenticated && _state.session != null) {
        final refreshed = await verifySession.execute(
          VerifySessionQuery(jwtToken: _state.session!.jwtToken),
        );
        if (refreshed.isSuccess) {
          _state = _state.copyWith(
            status: AuthStatus.authenticated,
            session: refreshed.dataOrNull,
            isFirstAccountSetup: false,
            availableRoles: roles,
            users: users,
            clearError: true,
          );
          notifyListeners();
          return;
        }
      }

      _state = _state.copyWith(
        status: AuthStatus.unauthenticated,
        formMode: isFirstAccount
            ? AuthFormMode.createAccount
            : AuthFormMode.signIn,
        isFirstAccountSetup: isFirstAccount,
        availableRoles: roles,
        users: users,
        selectedRoleId: isFirstAccount ? Role.adminRoleId : Role.operatorRoleId,
        clearError: true,
      );
    } catch (e) {
      _state = _state.copyWith(
        status: AuthStatus.unauthenticated,
        formMode: AuthFormMode.createAccount,
        isFirstAccountSetup: true,
        availableRoles: [Role.systemAdmin(), Role.systemOperator()],
        selectedRoleId: Role.adminRoleId,
        errorMessage: 'Failed to load authentication state: $e',
      );
    }
    notifyListeners();
  }

  /// Immediately establishes an in-memory Admin session (used by legacy test fixtures).
  void bootstrapTestAdminSession() {
    final adminRole = Role.systemAdmin();
    final adminUser = User.create(
      id: UserId('usr_test_admin'),
      username: 'admin',
      displayName: 'System Administrator',
      passwordHash: PasswordHasher.hashPassword('admin123', salt: 'testsalt'),
      roleId: adminRole.id,
    );
    final token = jwtService.generateToken(user: adminUser, role: adminRole);
    final payload = jwtService.verifyToken(token)!;
    _state = _state.copyWith(
      status: AuthStatus.authenticated,
      session: AuthSession(
        user: adminUser,
        role: adminRole,
        jwtToken: token,
        payload: payload,
      ),
      isFirstAccountSetup: false,
      availableRoles: [adminRole, Role.systemOperator()],
      users: [adminUser],
      clearError: true,
    );
    notifyListeners();
  }

  void setFormMode(AuthFormMode mode) {
    if (_state.formMode == mode && _state.errorMessage == null) return;
    _state = _state.copyWith(formMode: mode, clearError: true);
    notifyListeners();
  }

  void setSelectedRoleId(RoleId roleId) {
    _state = _state.copyWith(selectedRoleId: roleId, clearError: true);
    notifyListeners();
  }

  void clearError() {
    if (_state.errorMessage == null) return;
    _state = _state.copyWith(clearError: true);
    notifyListeners();
  }

  /// Authenticates an existing user and issues a signed JWT token.
  Future<bool> login({
    required String username,
    required String password,
  }) async {
    _state = _state.copyWith(
      status: AuthStatus.authenticating,
      clearError: true,
    );
    notifyListeners();

    final result = await loginUser.execute(
      LoginUserCommand(username: username, password: password),
    );

    if (result.isSuccess) {
      final roles = await roleRepository.getAll();
      final users = await userRepository.getAll();
      _state = _state.copyWith(
        status: AuthStatus.authenticated,
        session: result.dataOrNull,
        isFirstAccountSetup: false,
        selectedRoleId: Role.operatorRoleId,
        availableRoles: roles,
        users: users,
        clearError: true,
      );
      notifyListeners();
      return true;
    } else {
      _state = _state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: result.failureOrNull?.message ?? 'Login failed.',
      );
      notifyListeners();
      return false;
    }
  }

  /// Registers a new user account and immediately signs them in with a signed JWT token.
  Future<bool> register({
    required String username,
    required String displayName,
    required String password,
    RoleId? roleId,
  }) async {
    _state = _state.copyWith(
      status: AuthStatus.authenticating,
      clearError: true,
    );
    notifyListeners();

    final result = await registerUser.execute(
      RegisterUserCommand(
        username: username,
        displayName: displayName,
        password: password,
        roleId: roleId ?? _state.selectedRoleId,
      ),
    );

    if (result.isSuccess) {
      final roles = await roleRepository.getAll();
      final users = await userRepository.getAll();
      _state = _state.copyWith(
        status: AuthStatus.authenticated,
        session: result.dataOrNull,
        isFirstAccountSetup: false,
        selectedRoleId: Role.operatorRoleId,
        availableRoles: roles,
        users: users,
        clearError: true,
      );
      notifyListeners();
      return true;
    } else {
      _state = _state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage:
            result.failureOrNull?.message ?? 'Account creation failed.',
      );
      notifyListeners();
      return false;
    }
  }

  /// Signs out the current user and clears the active JWT session.
  void logout() {
    _state = _state.copyWith(
      status: AuthStatus.unauthenticated,
      formMode: _state.isFirstAccountSetup
          ? AuthFormMode.createAccount
          : AuthFormMode.signIn,
      selectedRoleId: _state.isFirstAccountSetup
          ? Role.adminRoleId
          : Role.operatorRoleId,
      clearSession: true,
      clearError: true,
    );
    notifyListeners();
  }

  /// Reloads all roles and users and refreshes the active JWT session if needed.
  Future<void> refreshDirectory() async {
    await roleRepository.ensureSystemRoles();
    final roles = await roleRepository.getAll();
    final users = await userRepository.getAll();

    AuthSession? updatedSession = _state.session;
    if (updatedSession != null) {
      final verified = await verifySession.execute(
        VerifySessionQuery(jwtToken: updatedSession.jwtToken),
      );
      if (verified.isSuccess) {
        updatedSession = verified.dataOrNull;
      }
    }

    _state = _state.copyWith(
      availableRoles: roles,
      users: users,
      session: updatedSession,
      isFirstAccountSetup: users.isEmpty,
    );
    notifyListeners();
  }

  /// Creates a custom role with custom [AppPermission]s.
  Future<Result<Role>> addCustomRole({
    required String name,
    String? description,
    required Set<AppPermission> permissions,
  }) async {
    final result = await createCustomRole.execute(
      CreateCustomRoleCommand(
        name: name,
        description: description,
        permissions: permissions,
      ),
    );
    if (result.isSuccess) {
      await refreshDirectory();
    }
    return result;
  }

  /// Updates an existing custom role's permissions.
  Future<Result<Role>> editRole({
    required RoleId roleId,
    required String name,
    String? description,
    required Set<AppPermission> permissions,
  }) async {
    final result = await updateRole.execute(
      UpdateRoleCommand(
        roleId: roleId,
        name: name,
        description: description,
        permissions: permissions,
      ),
    );
    if (result.isSuccess) {
      await refreshDirectory();
    }
    return result;
  }

  /// Deletes a non-system custom role.
  Future<void> removeCustomRole(RoleId roleId) async {
    await roleRepository.delete(roleId);
    await refreshDirectory();
  }

  /// Creates a user account without switching the current Admin's active session.
  Future<Result<User>> createManagedUser({
    required String username,
    required String displayName,
    required String password,
    required RoleId roleId,
  }) async {
    final trimmedUsername = username.trim().toLowerCase();
    final trimmedDisplay = displayName.trim();
    if (trimmedUsername.length < 3) {
      return const Result.failure(
        ValidationFailure(
          message: 'Username must be at least 3 characters long.',
        ),
      );
    }
    if (trimmedDisplay.isEmpty) {
      return const Result.failure(
        ValidationFailure(message: 'Full name cannot be empty.'),
      );
    }
    if (password.length < 6) {
      return const Result.failure(
        ValidationFailure(
          message: 'Password must be at least 6 characters long.',
        ),
      );
    }

    final existing = await userRepository.getByUsername(trimmedUsername);
    if (existing != null) {
      return Result.failure(
        ConflictFailure(
          message: 'Username "$trimmedUsername" is already taken.',
        ),
      );
    }

    final user = User.create(
      username: trimmedUsername,
      displayName: trimmedDisplay,
      passwordHash: PasswordHasher.hashPassword(password),
      roleId: roleId,
    );
    await userRepository.add(user);
    await refreshDirectory();
    return Result.success(user);
  }

  /// Assigns a new role to an existing user and refreshes the active JWT if self-updated.
  Future<Result<User>> assignUserRole({
    required UserId userId,
    required RoleId roleId,
  }) async {
    final result = await updateUserRole.execute(
      UpdateUserRoleCommand(userId: userId, roleId: roleId),
    );
    if (result.isSuccess) {
      await refreshDirectory();
    }
    return result;
  }
}
