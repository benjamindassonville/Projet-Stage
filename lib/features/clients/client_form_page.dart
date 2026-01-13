import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/auth/permission.dart';

enum ClientFormMode { create, edit }

class ClientFormPage extends StatefulWidget {
  final Set<String> permissions;
  final ClientFormMode mode;
  final Map<String, dynamic>? existing;

  const ClientFormPage({
    super.key,
    required this.permissions,
    required this.mode,
    this.existing,
  });

  @override
  State<ClientFormPage> createState() => _ClientFormPageState();
}

class _ClientFormPageState extends State<ClientFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _supabase = Supabase.instance.client;
  bool _loading = false;

  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _email;
  late final TextEditingController _phone;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _firstName = TextEditingController(text: e?['first_name'] ?? '');
    _lastName = TextEditingController(text: e?['last_name'] ?? '');
    _email = TextEditingController(text: e?['email'] ?? '');
    _phone = TextEditingController(text: e?['phone'] ?? '');
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    final data = {
      'first_name': _firstName.text.trim(),
      'last_name': _lastName.text.trim(),
      'email': _email.text.trim().isEmpty ? null : _email.text.trim(),
      'phone': _phone.text.trim().isEmpty ? null : _phone.text.trim(),
    };

    try {
      if (widget.mode == ClientFormMode.create) {
        if (!widget.permissions.contains(Permission.clientCreate)) {
          throw Exception('Permission refusée');
        }
        await _supabase.from('clients').insert(data);
      } else {
        if (!widget.permissions.contains(Permission.clientUpdate)) {
          throw Exception('Permission refusée');
        }
        await _supabase
            .from('clients')
            .update(data)
            .eq('id', widget.existing!['id']);
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Action refusée ou erreur serveur')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.mode == ClientFormMode.create
              ? 'Ajouter un client'
              : 'Modifier un client',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _firstName,
                decoration: const InputDecoration(labelText: 'Prénom *'),
                validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _lastName,
                decoration: const InputDecoration(labelText: 'Nom *'),
                validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _email,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _phone,
                decoration: const InputDecoration(labelText: 'Téléphone'),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Enregistrer'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
