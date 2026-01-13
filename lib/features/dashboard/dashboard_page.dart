import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/auth/permission.dart';
import '../../widgets/permission_guard.dart';

import '../clients/client_list_page.dart';
import '../clients/client_form_page.dart';

import '../interventions/intervention_list_page.dart';
import '../interventions/intervention_form_page.dart';

import '../planning/planning_page.dart';

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
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Bienvenue, ${user?.email ?? 'utilisateur'}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text('Rôle : $role'),
          const SizedBox(height: 24),

          // =========================
          // PLANNING
          // =========================
          const Text('Planning', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),

          PermissionGuard(
            permissions: permissions,
            requiredPermission: Permission.interventionRead,
            child: Card(
              child: ListTile(
                leading: const Icon(Icons.event_note),
                title: const Text('Mon planning'),
                subtitle: const Text('Vue jour / semaine'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PlanningPage(permissions: permissions),
                    ),
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 24),

          // =========================
          // CLIENTS
          // =========================
          const Text('Clients', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),

          PermissionGuard(
            permissions: permissions,
            requiredPermission: Permission.clientRead,
            child: Card(
              child: ListTile(
                leading: const Icon(Icons.people),
                title: const Text('Voir les clients'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ClientListPage(permissions: permissions),
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
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ClientFormPage(
                        permissions: permissions,
                        mode: ClientFormMode.create,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 24),

          // =========================
          // INTERVENTIONS
          // =========================
          const Text('Interventions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),

          PermissionGuard(
            permissions: permissions,
            requiredPermission: Permission.interventionRead,
            child: Card(
              child: ListTile(
                leading: const Icon(Icons.build),
                title: const Text('Voir les interventions'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => InterventionListPage(permissions: permissions),
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
                title: const Text('Ajouter une intervention'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => InterventionFormPage(
                        permissions: permissions,
                        mode: InterventionFormMode.create,
                      ),
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
