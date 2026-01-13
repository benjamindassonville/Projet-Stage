import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/auth/permission.dart';
import '../../widgets/permission_guard.dart';
import 'client_form_page.dart';

class ClientListPage extends StatefulWidget {
  final Set<String> permissions;

  const ClientListPage({
    super.key,
    required this.permissions,
  });

  @override
  State<ClientListPage> createState() => _ClientListPageState();
}

class _ClientListPageState extends State<ClientListPage> {
  final _supabase = Supabase.instance.client;

  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _clients = [];

  @override
  void initState() {
    super.initState();
    _loadClients();
  }

  Future<void> _loadClients() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await _supabase
          .from('clients')
          .select('id, first_name, last_name, email, phone, address, created_at')
          .order('created_at', ascending: false);

      setState(() {
        _clients = (res as List).cast<Map<String, dynamic>>();
      });
    } catch (e) {
      setState(() => _error = "Impossible de charger les clients (RLS ou connexion).");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _deleteClient(String clientId) async {
    try {
      await _supabase.from('clients').delete().eq('id', clientId);
      await _loadClients();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Client supprimé.")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Suppression refusée (permission/RLS)."),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _confirmDelete(Map<String, dynamic> client) async {
    final id = client['id'] as String;
    final name = "${client['first_name']} ${client['last_name']}";

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirmer la suppression"),
        content: Text("Supprimer le client : $name ?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Annuler")),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text("Supprimer")),
        ],
      ),
    );

    if (ok == true) {
      await _deleteClient(id);
    }
  }

  void _openCreate() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ClientFormPage(
          permissions: widget.permissions,
          mode: ClientFormMode.create,
        ),
      ),
    );
    if (created == true) _loadClients();
  }

  void _openEdit(Map<String, dynamic> client) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ClientFormPage(
          permissions: widget.permissions,
          mode: ClientFormMode.edit,
          existing: client,
        ),
      ),
    );
    if (updated == true) _loadClients();
  }

  @override
  Widget build(BuildContext context) {
    // Protection écran : si pas client:read → écran inutilisable.
    if (!widget.permissions.contains(Permission.clientRead)) {
      return Scaffold(
        appBar: AppBar(title: const Text("Clients")),
        body: const Center(child: Text("Accès refusé (client:read requis).")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Clients"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadClients,
            tooltip: "Rafraîchir",
          ),
          PermissionGuard(
            permissions: widget.permissions,
            requiredPermission: Permission.clientCreate,
            child: IconButton(
              icon: const Icon(Icons.add),
              onPressed: _openCreate,
              tooltip: "Ajouter un client",
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _clients.isEmpty
                  ? const Center(child: Text("Aucun client."))
                  : ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: _clients.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final c = _clients[i];
                        final name = "${c['first_name']} ${c['last_name']}";
                        final email = (c['email'] ?? '') as String;
                        final phone = (c['phone'] ?? '') as String;

                        return ListTile(
                          title: Text(name),
                          subtitle: Text(
                            [email, phone].where((x) => x.toString().trim().isNotEmpty).join(" • "),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              PermissionGuard(
                                permissions: widget.permissions,
                                requiredPermission: Permission.clientUpdate,
                                child: IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () => _openEdit(c),
                                  tooltip: "Modifier",
                                ),
                              ),
                              PermissionGuard(
                                permissions: widget.permissions,
                                requiredPermission: Permission.clientDelete,
                                child: IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () => _confirmDelete(c),
                                  tooltip: "Supprimer",
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
    );
  }
}
