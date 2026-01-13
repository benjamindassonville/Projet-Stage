class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final String? role;
  final Set<String> permissions;

  const AuthState({
    required this.isAuthenticated,
    required this.isLoading,
    this.role,
    this.permissions = const {},
  });

  factory AuthState.loading() =>
      const AuthState(isAuthenticated: false, isLoading: true);

  factory AuthState.unauthenticated() =>
      const AuthState(isAuthenticated: false, isLoading: false);

  factory AuthState.authenticated({
    required String role,
    required Set<String> permissions,
  }) =>
      AuthState(
        isAuthenticated: true,
        isLoading: false,
        role: role,
        permissions: permissions,
      );
}
