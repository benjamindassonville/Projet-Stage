import '../supabase/supabase_client.dart';

class PermissionService {
  static Future<Set<String>> fetchPermissions(String roleId) async {
    final supabase = SupabaseClientSingleton.client;

    final res = await supabase
        .from('roles_permissions')
        .select('permissions!inner(name)')
        .eq('role_id', roleId);

    return (res as List)
        .map((e) => e['permissions']?['name'] as String?)
        .whereType<String>()
        .toSet();
  }
}
