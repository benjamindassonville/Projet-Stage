import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/auth/permission.dart';

enum InterventionFormMode { create, edit }

class InterventionFormPage extends StatefulWidget {
  final Set<String> permissions;
  final InterventionFormMode mode;
  final Map<String, dynamic>? existing;

  const InterventionFormPage({
    super.key,
    required this.permissions,
    required this.mode,
    this.existing,
  });

  @override
  State<InterventionFormPage> createState() => _InterventionFormPageState();
}

class _InterventionFormPageState extends State<InterventionFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _supabase = Supabase.instance.client;

  bool _loading = false;

  late final TextEditingController _typeCtrl;
  late final TextEditingController _notesCtrl;

  DateTime? _scheduledAt; // date+heure
  TimeOfDay? _time;
  String? _clientId;
  String _status = 'prevue';

  int _durationMinutes = 60;

  List<Map<String, dynamic>> _clients = [];

  final List<int> _durationChoices = const [15, 30, 45, 60, 90, 120, 180, 240, 300, 360, 480];

  @override
  void initState() {
    super.initState();

    final existing = widget.existing;

    _typeCtrl = TextEditingController(text: (existing?['type'] ?? '') as String);
    _notesCtrl = TextEditingController(text: (existing?['notes'] ?? '') as String);

    final existingClientId = existing?['client_id'];
    if (existingClientId is String && existingClientId.isNotEmpty) {
      _clientId = existingClientId;
    }

    final existingStatus = existing?['status'];
    if (existingStatus is String && existingStatus.isNotEmpty) {
      _status = existingStatus;
    }

    final existingDuration = existing?['duration_minutes'];
    if (existingDuration is int) {
      _durationMinutes = existingDuration;
    } else if (existingDuration is String) {
      final parsed = int.tryParse(existingDuration);
      if (parsed != null) _durationMinutes = parsed;
    }

    final rawDate = existing?['scheduled_at'];
    if (rawDate is String && rawDate.isNotEmpty) {
      final parsed = DateTime.tryParse(rawDate);
      if (parsed != null) {
        _scheduledAt = parsed;
        _time = TimeOfDay(hour: parsed.hour, minute: parsed.minute);
      }
    }

    _loadClients();
  }

  @override
  void dispose() {
    _typeCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadClients() async {
    final res = await _supabase
        .from('clients')
        .select('id, first_name, last_name')
        .order('last_name');

    setState(() {
      _clients = (res as List).cast<Map<String, dynamic>>();
    });
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
    );
  }

  DateTime _combine(DateTime date, TimeOfDay time) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _pickDate() async {
    final initial = _scheduledAt ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(initial.year, initial.month, initial.day),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) return;

    final t = _time ?? const TimeOfDay(hour: 9, minute: 0);

    setState(() {
      _time = t;
      _scheduledAt = _combine(picked, t);
    });
  }

  Future<void> _pickTime() async {
    if (_scheduledAt == null) {
      _showError("Choisis d'abord une date.");
      return;
    }

    final initialTime = _time ?? const TimeOfDay(hour: 9, minute: 0);
    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    if (picked == null) return;

    final currentDate = _scheduledAt!;
    setState(() {
      _time = picked;
      _scheduledAt = _combine(currentDate, picked);
    });
  }

  String _dateLabel() {
    if (_scheduledAt == null) return 'Choisir une date *';
    final d = _scheduledAt!.toLocal().toString().split(' ').first;
    return 'Date : $d';
  }

  String _timeLabel() {
    if (_time == null) return 'Choisir une heure *';
    final h = _time!.hour.toString().padLeft(2, '0');
    final m = _time!.minute.toString().padLeft(2, '0');
    return 'Heure : $h:$m';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_clientId == null) {
      _showError("Client obligatoire.");
      return;
    }
    if (_scheduledAt == null) {
      _showError("Date et heure obligatoires.");
      return;
    }

    if (widget.mode == InterventionFormMode.create &&
        !widget.permissions.contains(Permission.interventionCreate)) {
      _showError("Accès refusé (intervention:create).");
      return;
    }
    if (widget.mode == InterventionFormMode.edit &&
        !widget.permissions.contains(Permission.interventionUpdate)) {
      _showError("Accès refusé (intervention:update).");
      return;
    }

    final user = _supabase.auth.currentUser;
    if (user == null) {
      _showError("Session invalide. Reconnecte-toi.");
      return;
    }

    setState(() => _loading = true);

    final data = {
      'client_id': _clientId,
      'user_id': user.id,
      'scheduled_at': _scheduledAt!.toIso8601String(),
      'type': _typeCtrl.text.trim(),
      'status': _status,
      'notes': _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      'duration_minutes': _durationMinutes,
    };

    try {
      if (widget.mode == InterventionFormMode.create) {
        await _supabase.from('interventions').insert(data);
      } else {
        final id = widget.existing?['id'];
        if (id is! String || id.isEmpty) {
          _showError("Intervention introuvable.");
          return;
        }
        await _supabase.from('interventions').update(data).eq('id', id);
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } on PostgrestException catch (e) {
      _showError("Erreur Supabase: ${e.message}");
    } catch (_) {
      _showError("Erreur ou accès refusé.");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _durationLabel(int minutes) {
    if (minutes < 60) return '$minutes min';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '${h}h' : '${h}h${m.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.mode == InterventionFormMode.create
        ? 'Ajouter une intervention'
        : 'Modifier une intervention';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _typeCtrl,
                decoration: const InputDecoration(labelText: 'Type *'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
              ),
              const SizedBox(height: 10),

              DropdownButtonFormField<String>(
                initialValue: _clientId,
                decoration: const InputDecoration(labelText: 'Client *'),
                items: _clients
                    .map(
                      (c) => DropdownMenuItem<String>(
                        value: c['id'] as String,
                        child: Text('${c['first_name']} ${c['last_name']}'),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _clientId = v),
              ),
              const SizedBox(height: 10),

              DropdownButtonFormField<String>(
                initialValue: _status,
                decoration: const InputDecoration(labelText: 'Statut *'),
                items: const [
                  DropdownMenuItem(value: 'prevue', child: Text('Prévue')),
                  DropdownMenuItem(value: 'en_cours', child: Text('En cours')),
                  DropdownMenuItem(value: 'terminee', child: Text('Terminée')),
                ],
                onChanged: (v) => setState(() => _status = v ?? 'prevue'),
              ),
              const SizedBox(height: 10),

              DropdownButtonFormField<int>(
                initialValue: _durationMinutes,
                decoration: const InputDecoration(labelText: 'Durée *'),
                items: _durationChoices
                    .map((m) => DropdownMenuItem<int>(
                          value: m,
                          child: Text(_durationLabel(m)),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _durationMinutes = v ?? 60),
              ),
              const SizedBox(height: 10),

              Card(
                child: ListTile(
                  title: Text(_dateLabel()),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: _pickDate,
                ),
              ),
              Card(
                child: ListTile(
                  title: Text(_timeLabel()),
                  trailing: const Icon(Icons.access_time),
                  onTap: _pickTime,
                ),
              ),

              const SizedBox(height: 10),

              TextFormField(
                controller: _notesCtrl,
                decoration: const InputDecoration(labelText: 'Notes'),
                maxLines: 3,
              ),

              const SizedBox(height: 24),

              SizedBox(
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
