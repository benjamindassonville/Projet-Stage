import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/auth/permission.dart';
import '../../widgets/permission_guard.dart';
import 'intervention_form_page.dart';

class InterventionListPage extends StatefulWidget {
  final Set<String> permissions;

  const InterventionListPage({super.key, required this.permissions});

  @override
  State<InterventionListPage> createState() => _InterventionListPageState();
}

class _InterventionListPageState extends State<InterventionListPage> {
  final _supabase = Supabase.instance.client;

  bool _loading = true;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    final res = await _supabase
        .from('interventions')
        .select('id, client_id, scheduled_at, type, status, notes, client:clients(first_name, last_name)')
        .order('scheduled_at', ascending: true);

    setState(() {
      _items = (res as List).cast<Map<String, dynamic>>();
      _loading = false;
    });
  }

  void _edit(Map<String, dynamic> it) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => InterventionFormPage(
          permissions: widget.permissions,
          mode: InterventionFormMode.edit,
          existing: it,
        ),
      ),
    );
    if (updated == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.permissions.contains(Permission.interventionRead)) {
      return const Scaffold(body: Center(child: Text('Accès refusé')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Interventions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? const Center(child: Text('Aucune intervention'))
              : ListView.separated(
                  itemCount: _items.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final it = _items[i];

                    final client = it['client'];
                    final clientName = client is Map
                        ? '${client['first_name']} ${client['last_name']}'
                        : '—';

                    final when = (it['scheduled_at'] ?? '') as String;
                    final type = (it['type'] ?? '') as String;
                    final status = (it['status'] ?? '') as String;

                    return ListTile(
                      title: Text(type.isEmpty ? 'Intervention' : type),
                      subtitle: Text('$clientName • $when • $status'),
                      trailing: PermissionGuard(
                        permissions: widget.permissions,
                        requiredPermission: Permission.interventionUpdate,
                        child: IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _edit(it),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
