import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/auth/permission.dart';
import '../../widgets/permission_guard.dart';

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
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              // AuthGate gère automatiquement la redirection
            },
            tooltip: 'Se déconnecter',
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Bienvenue, ${user?.email ?? 'utilisateur'}',
            style: const TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 6),
          Text('Rôle: $role'),
          const SizedBox(height: 16),

          // ---- Section Clients ----
          const Text('Clients', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),

          PermissionGuard(
            permissions: permissions,
            requiredPermission: Permission.clientRead,
            child: ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Voir les clients'),
              subtitle: const Text('Accès lecture aux fiches clients'),
              onTap: () {
                // Étape suivante: page clients
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Page clients (à venir)')),
                );
              },
            ),
          ),

          PermissionGuard(
            permissions: permissions,
            requiredPermission: Permission.clientCreate,
            child: ListTile(
              leading: const Icon(Icons.person_add),
              title: const Text('Ajouter un client'),
              subtitle: const Text('Créer une nouvelle fiche client'),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Formulaire client (à venir)')),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // ---- Section Interventions ----
          const Text('Interventions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),

          PermissionGuard(
            permissions: permissions,
            requiredPermission: Permission.interventionRead,
            child: ListTile(
              leading: const Icon(Icons.build),
              title: const Text('Voir les interventions'),
              subtitle: const Text('Liste et détails des interventions'),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Page interventions (à venir)')),
                );
              },
            ),
          ),

          PermissionGuard(
            permissions: permissions,
            requiredPermission: Permission.interventionCreate,
            child: ListTile(
              leading: const Icon(Icons.add_circle_outline),
              title: const Text('Créer une intervention'),
              subtitle: const Text('Planifier une nouvelle intervention'),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Formulaire intervention (à venir)')),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // ---- Section Administration ----
          const Text('Administration', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),

          PermissionGuard(
            permissions: permissions,
            requiredPermission: Permission.roleManage,
            child: ListTile(
              leading: const Icon(Icons.admin_panel_settings),
              title: const Text('Gérer les rôles & permissions'),
              subtitle: const Text('Administration des droits'),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Administration rôles (à venir)')),
                );
              },
            ),
          ),

          PermissionGuard(
            permissions: permissions,
            requiredPermission: Permission.userManage,
            child: ListTile(
              leading: const Icon(Icons.manage_accounts),
              title: const Text('Gérer les utilisateurs'),
              subtitle: const Text('Création et gestion des comptes'),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Administration utilisateurs (à venir)')),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // ---- Export CSV ----
          const Text('Données', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),

          PermissionGuard(
            permissions: permissions,
            requiredPermission: Permission.dataExport,
            child: ListTile(
              leading: const Icon(Icons.download),
              title: const Text('Exporter les données CSV'),
              subtitle: const Text('Export clients / interventions'),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Export CSV (à venir)')),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
