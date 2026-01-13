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
  List<Map<String, dynamic>> _clients = [];

  @override
  void initState() {
    super.initState();
    _loadClients();
  }

  Future<void> _loadClients() async {
    setState(() => _loading = true);

    final res = await _supabase
        .from('clients')
        .select('id, first_name, last_name, email, phone')
        .order('last_name');

    setState(() {
      _clients = (res as List).cast<Map<String, dynamic>>();
      _loading = false;
    });
  }

  void _editClient(Map<String, dynamic> client) async {
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
    if (!widget.permissions.contains(Permission.clientRead)) {
      return const Scaffold(
        body: Center(child: Text('Accès refusé')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Clients')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _clients.isEmpty
              ? const Center(child: Text('Aucun client'))
              : ListView.separated(
                  itemCount: _clients.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final c = _clients[i];
                    return ListTile(
                      title: Text('${c['first_name']} ${c['last_name']}'),
                      subtitle: Text(
                        [c['email'], c['phone']]
                            .where((e) => e != null && e.toString().isNotEmpty)
                            .join(' • '),
                      ),
                      trailing: PermissionGuard(
                        permissions: widget.permissions,
                        requiredPermission: Permission.clientUpdate,
                        child: IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _editClient(c),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
