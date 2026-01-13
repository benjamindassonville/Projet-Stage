import 'package:flutter/material.dart';
import '../core/auth/auth_state.dart';
import '../core/auth/permission_service.dart';
import '../core/supabase/supabase_client.dart';
import '../features/auth/login_page.dart';
import '../features/dashboard/dashboard_page.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  AuthState _state = AuthState.loading();

  @override
  void initState() {
    super.initState();
    _listenAuth();
  }

  void _listenAuth() {
    final supabase = SupabaseClientSingleton.client;

    supabase.auth.onAuthStateChange.listen((event) async {
      final user = supabase.auth.currentUser;

      if (user == null) {
        setState(() => _state = AuthState.unauthenticated());
        return;
      }

      final profile = await supabase
          .from('users_profiles')
          .select('role_id, is_active')
          .eq('id', user.id)
          .maybeSingle();

      if (profile == null || profile['is_active'] != true) {
        await supabase.auth.signOut();
        setState(() => _state = AuthState.unauthenticated());
        return;
      }

      final roleId = profile['role_id'] as String;

      final roleRes = await supabase
          .from('roles')
          .select('name')
          .eq('id', roleId)
          .maybeSingle();

      final roleName = roleRes?['name'] as String?;

      if (roleName == null) {
        await supabase.auth.signOut();
        setState(() => _state = AuthState.unauthenticated());
        return;
      }

      final permissions = await PermissionService.fetchPermissions(roleId);

      setState(() {
        _state = AuthState.authenticated(
          role: roleName,
          permissions: permissions,
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_state.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_state.isAuthenticated) {
      return const LoginPage();
    }

    return DashboardPage(
      role: _state.role!,
      permissions: _state.permissions,
    );
  }
}
