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
  final _supabase = Supabase.instance.client;

  final _formKey = GlobalKey<FormState>();
  bool _loading = false;

  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  late final TextEditingController _address;

  @override
  void initState() {
    super.initState();

    final e = widget.existing;

    _firstName = TextEditingController(text: (e?['first_name'] ?? '') as String);
    _lastName = TextEditingController(text: (e?['last_name'] ?? '') as String);
    _email = TextEditingController(text: (e?['email'] ?? '') as String);
    _phone = TextEditingController(text: (e?['phone'] ?? '') as String);
    _address = TextEditingController(text: (e?['address'] ?? '') as String);
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _phone.dispose();
    _address.dispose();
    super.dispose();
  }

  bool get _canCreate => widget.permissions.contains(Permission.clientCreate);
  bool get _canUpdate => widget.permissions.contains(Permission.clientUpdate);

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // Garde-fou permissions côté UI
    if (widget.mode == ClientFormMode.create && !_canCreate) {
      _snack("Accès refusé (client:create requis).", error: true);
      return;
    }
    if (widget.mode == ClientFormMode.edit && !_canUpdate) {
      _snack("Accès refusé (client:update requis).", error: true);
      return;
    }

    setState(() => _loading = true);

    try {
      final payload = {
        'first_name': _firstName.text.trim(),
        'last_name': _lastName.text.trim(),
        'email': _email.text.trim().isEmpty ? null : _email.text.trim(),
        'phone': _phone.text.trim().isEmpty ? null : _phone.text.trim(),
        'address': _address.text.trim().isEmpty ? null : _address.text.trim(),
      };

      if (widget.mode == ClientFormMode.create) {
        await _supabase.from('clients').insert(payload);
        if (!mounted) return;
        _snack("Client créé.");
        Navigator.pop(context, true);
      } else {
        final id = widget.existing?['id'] as String?;
        if (id == null) {
          _snack("Client introuvable.", error: true);
          return;
        }
        await _supabase.from('clients').update(payload).eq('id', id);
        if (!mounted) return;
        _snack("Client mis à jour.");
        Navigator.pop(context, true);
      }
    } catch (e) {
      _snack("Échec (permission/RLS ou connexion).", error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? Colors.redAccent : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.mode == ClientFormMode.create ? "Ajouter un client" : "Modifier un client";

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _firstName,
                decoration: const InputDecoration(labelText: "Prénom *"),
                validator: (v) => (v == null || v.trim().isEmpty) ? "Prénom requis" : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _lastName,
                decoration: const InputDecoration(labelText: "Nom *"),
                validator: (v) => (v == null || v.trim().isEmpty) ? "Nom requis" : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _email,
                decoration: const InputDecoration(labelText: "Email"),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _phone,
                decoration: const InputDecoration(labelText: "Téléphone"),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _address,
                decoration: const InputDecoration(labelText: "Adresse"),
                maxLines: 2,
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Enregistrer"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
