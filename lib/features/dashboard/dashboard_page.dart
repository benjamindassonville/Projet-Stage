import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/auth/permission.dart';
import '../../widgets/permission_guard.dart';
import '../clients/client_list_page.dart';

class DashboardPage extends StatelessWidget {
  final String role;
  final Set<String> permissions;

  const DashboardPage({
    super.key,
    required this.role,
    required this.permissions,
  });

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tableau de bord'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Se déconnecter',
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              // AuthGate gère automatiquement la redirection
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ---- Infos utilisateur ----
          Text(
            'Bienvenue, ${user?.email ?? 'utilisateur'}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text('Rôle : $role'),
          const SizedBox(height: 20),

          // =====================================================
          // CLIENTS
          // =====================================================
          const Text(
            'Clients',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          PermissionGuard(
            permissions: permissions,
            requiredPermission: Permission.clientRead,
            child: Card(
              child: ListTile(
                leading: const Icon(Icons.people),
                title: const Text('Voir les clients'),
                subtitle: const Text('Liste et fiches clients'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ClientListPage(
                        permissions: permissions,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          PermissionGuard(
            permissions: permissions,
            requiredPermission: Permission.clientCreate,
            child: Card(
              child: ListTile(
                leading: const Icon(Icons.person_add),
                title: const Text('Ajouter un client'),
                subtitle: const Text('Créer une nouvelle fiche client'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ClientListPage(
                        permissions: permissions,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 20),

          // =====================================================
          // INTERVENTIONS (préparation 5.2)
          // =====================================================
          const Text(
            'Interventions',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          PermissionGuard(
            permissions: permissions,
            requiredPermission: Permission.interventionRead,
            child: Card(
              child: ListTile(
                leading: const Icon(Icons.build),
                title: const Text('Voir les interventions'),
                subtitle: const Text('Liste et planning des interventions'),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Module interventions (étape 5.2)'),
                    ),
                  );
                },
              ),
            ),
          ),

          PermissionGuard(
            permissions: permissions,
            requiredPermission: Permission.interventionCreate,
            child: Card(
              child: ListTile(
                leading: const Icon(Icons.add_circle_outline),
                title: const Text('Créer une intervention'),
                subtitle: const Text('Planifier une nouvelle intervention'),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Création intervention (étape 5.2)'),
                    ),
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 20),

          // =====================================================
          // ADMINISTRATION
          // =====================================================
          const Text(
            'Administration',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          PermissionGuard(
            permissions: permissions,
            requiredPermission: Permission.roleManage,
            child: Card(
              child: ListTile(
                leading: const Icon(Icons.admin_panel_settings),
                title: const Text('Gérer les rôles & permissions'),
                subtitle: const Text('Administration des accès'),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Administration rôles (à venir)'),
                    ),
                  );
                },
              ),
            ),
          ),

          PermissionGuard(
            permissions: permissions,
            requiredPermission: Permission.userManage,
            child: Card(
              child: ListTile(
                leading: const Icon(Icons.manage_accounts),
                title: const Text('Gérer les utilisateurs'),
                subtitle: const Text('Création et gestion des comptes'),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Administration utilisateurs (à venir)'),
                    ),
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 20),

          // =====================================================
          // DONNÉES
          // =====================================================
          const Text(
            'Données',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          PermissionGuard(
            permissions: permissions,
            requiredPermission: Permission.dataExport,
            child: Card(
              child: ListTile(
                leading: const Icon(Icons.download),
                title: const Text('Exporter les données (CSV)'),
                subtitle: const Text('Clients et interventions'),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Export CSV (à venir)'),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
