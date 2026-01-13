import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/auth/permission.dart';
import '../../widgets/permission_guard.dart';
import '../interventions/intervention_form_page.dart';

enum PlanningMode { day, week }

class PlanningPage extends StatefulWidget {
  final Set<String> permissions;

  const PlanningPage({
    super.key,
    required this.permissions,
  });

  @override
  State<PlanningPage> createState() => _PlanningPageState();
}

class _PlanningPageState extends State<PlanningPage> {
  final _supabase = Supabase.instance.client;

  PlanningMode _mode = PlanningMode.day;
  DateTime _anchorDate = DateTime.now();

  bool _loading = true;
  String? _error;

  // Map<yyyy-mm-dd, List<interventions>>
  final Map<String, List<Map<String, dynamic>>> _grouped = {};

  @override
  void initState() {
    super.initState();
    _anchorDate = DateTime(_anchorDate.year, _anchorDate.month, _anchorDate.day);
    _load();
  }

  // -------------------------
  // Dates helpers
  // -------------------------
  DateTime _startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);
  DateTime _endExclusive(DateTime d) => _startOfDay(d).add(const Duration(days: 1));

  DateTime _mondayOfWeek(DateTime d) {
    final day = DateTime(d.year, d.month, d.day);
    final diff = day.weekday - DateTime.monday; // monday=0
    return day.subtract(Duration(days: diff));
  }

  String _dateKey(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  DateTime _parseDayKey(String dayKey) {
    final parts = dayKey.split('-');
    return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
  }

  // -------------------------
  // Format helpers
  // -------------------------
  String _formatDate(DateTime d) {
    final day = d.day.toString().padLeft(2, '0');
    final m = d.month.toString().padLeft(2, '0');
    final y = d.year.toString().padLeft(4, '0');
    return '$day/$m/$y';
  }

  String _formatTime(DateTime d) {
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _labelStatus(String status) {
    switch (status) {
      case 'prevue':
        return 'Prévue';
      case 'en_cours':
        return 'En cours';
      case 'terminee':
        return 'Terminée';
      default:
        return status.isEmpty ? '—' : status;
    }
  }

  // -------------------------
  // Safe parsing (Supabase types can vary)
  // -------------------------
  DateTime? _scheduledAtOf(Map<String, dynamic> it) {
    final raw = it['scheduled_at'];

    if (raw is DateTime) return raw.toLocal();

    if (raw is String && raw.isNotEmpty) {
      final parsed = DateTime.tryParse(raw);
      return parsed?.toLocal();
    }

    return null;
  }

  int _durationMinutesOf(Map<String, dynamic> it) {
    final raw = it['duration_minutes'];

    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    if (raw is String) return int.tryParse(raw) ?? 60;

    return 60;
  }

  String _clientNameOf(Map<String, dynamic> it) {
    final client = it['client'];
    if (client is Map) {
      final first = (client['first_name'] ?? '').toString().trim();
      final last = (client['last_name'] ?? '').toString().trim();
      final full = ('$first $last').trim();
      return full.isEmpty ? '—' : full;
    }
    return '—';
  }

  DateTime _endAt(DateTime start, int durationMinutes) {
    return start.add(Duration(minutes: durationMinutes));
  }

  String _formatDuration(int minutes) {
    if (minutes < 60) return '${minutes}min';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '${h}h' : '${h}h${m.toString().padLeft(2, '0')}';
  }

  // -------------------------
  // UI small components
  // -------------------------
  Widget _pill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.grey.shade300),
        color: Colors.white,
      ),
      child: Text(text, style: const TextStyle(fontSize: 12)),
    );
  }

  // ✅ Badge horaire lisible (remplace CircleAvatar)
  Widget _timeBadge(String text) {
    return Container(
      width: 56,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
        color: Colors.white,
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  // -------------------------
  // Week label "du ... au ..."
  // -------------------------
  String _weekHeaderLabel() {
    final monday = _mondayOfWeek(_anchorDate);
    final sunday = monday.add(const Duration(days: 6));
    return 'Semaine du ${_formatDate(monday)} au ${_formatDate(sunday)}';
  }

  // -------------------------
  // Navigation date
  // -------------------------
  Future<void> _pickAnchorDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _anchorDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) return;

    setState(() => _anchorDate = DateTime(picked.year, picked.month, picked.day));
    await _load();
  }

  Future<void> _prev() async {
    setState(() {
      _anchorDate = _anchorDate.subtract(Duration(days: _mode == PlanningMode.day ? 1 : 7));
    });
    await _load();
  }

  Future<void> _next() async {
    setState(() {
      _anchorDate = _anchorDate.add(Duration(days: _mode == PlanningMode.day ? 1 : 7));
    });
    await _load();
  }

  // -------------------------
  // Data load
  // -------------------------
  Future<void> _load() async {
    if (!widget.permissions.contains(Permission.interventionRead)) {
      setState(() {
        _loading = false;
        _error = "Accès refusé (intervention:read requis).";
        _grouped.clear();
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _grouped.clear();
    });

    try {
      late DateTime start;
      late DateTime end;

      if (_mode == PlanningMode.day) {
        start = _startOfDay(_anchorDate);
        end = _endExclusive(_anchorDate);
      } else {
        final monday = _mondayOfWeek(_anchorDate);
        start = _startOfDay(monday);
        end = _endExclusive(monday.add(const Duration(days: 6)));
      }

      final res = await _supabase
          .from('interventions')
          .select('id, client_id, scheduled_at, duration_minutes, type, status, notes, client:clients(first_name, last_name)')
          .gte('scheduled_at', start.toIso8601String())
          .lt('scheduled_at', end.toIso8601String())
          .order('scheduled_at', ascending: true);

      final items = (res as List).cast<Map<String, dynamic>>();

      for (final it in items) {
        final dt = _scheduledAtOf(it);
        if (dt == null) continue;

        final key = _dateKey(dt);
        _grouped.putIfAbsent(key, () => []);
        _grouped[key]!.add(it);
      }

      // tri des jours + tri des interventions
      final sortedKeys = _grouped.keys.toList()..sort();
      final sortedMap = <String, List<Map<String, dynamic>>>{};

      for (final k in sortedKeys) {
        final list = _grouped[k]!;
        list.sort((a, b) {
          final da = _scheduledAtOf(a);
          final db = _scheduledAtOf(b);
          if (da == null && db == null) return 0;
          if (da == null) return 1;
          if (db == null) return -1;
          return da.compareTo(db);
        });
        sortedMap[k] = list;
      }

      _grouped
        ..clear()
        ..addAll(sortedMap);
    } on PostgrestException catch (e) {
      setState(() => _error = "Erreur Supabase: ${e.message}");
    } catch (_) {
      setState(() => _error = "Impossible de charger le planning.");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // -------------------------
  // Edit
  // -------------------------
  Future<void> _openEdit(Map<String, dynamic> it) async {
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

    if (updated == true) {
      await _load();
    }
  }

  // -------------------------
  // UI components
  // -------------------------
  Widget _buildHeaderCard() {
    final headerText = _mode == PlanningMode.week ? _weekHeaderLabel() : _formatDate(_anchorDate);

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            IconButton(
              onPressed: _prev,
              icon: const Icon(Icons.chevron_left),
              tooltip: 'Précédent',
            ),
            Expanded(
              child: Center(
                child: Text(
                  headerText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            IconButton(
              onPressed: _next,
              icon: const Icon(Icons.chevron_right),
              tooltip: 'Suivant',
            ),
            const SizedBox(width: 8),
            SegmentedButton<PlanningMode>(
              segments: const [
                ButtonSegment(value: PlanningMode.day, label: Text('Jour')),
                ButtonSegment(value: PlanningMode.week, label: Text('Semaine')),
              ],
              selected: {_mode},
              onSelectionChanged: (s) async {
                setState(() => _mode = s.first);
                await _load();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayCard(String dayKey, List<Map<String, dynamic>> list) {
    final d = _parseDayKey(dayKey);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _formatDate(d),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...list.map(_buildInterventionTile),
          ],
        ),
      ),
    );
  }

  Widget _buildInterventionTile(Map<String, dynamic> it) {
    final start = _scheduledAtOf(it);
    final duration = _durationMinutesOf(it);

    final type = (it['type'] ?? '').toString().trim();
    final statusLabel = _labelStatus((it['status'] ?? '').toString().trim());
    final clientName = _clientNameOf(it);

    final startLabel = start == null ? '--:--' : _formatTime(start);
    final endLabel = start == null ? '--:--' : _formatTime(_endAt(start, duration));
    final durationLabel = _formatDuration(duration);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: _timeBadge(startLabel),
      title: Text(type.isEmpty ? 'Intervention' : type),
      subtitle: Text('$clientName • $startLabel → $endLabel'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _pill(durationLabel),
          const SizedBox(width: 8),
          _pill(statusLabel),
          const SizedBox(width: 6),
          PermissionGuard(
            permissions: widget.permissions,
            requiredPermission: Permission.interventionUpdate,
            child: IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Modifier',
              onPressed: () => _openEdit(it),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------
  // Build
  // -------------------------
  @override
  Widget build(BuildContext context) {
    final title = _mode == PlanningMode.day ? 'Planning (Jour)' : 'Planning (Semaine)';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            tooltip: 'Choisir une date',
            onPressed: _pickAnchorDate,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Rafraîchir',
            onPressed: _load,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            _buildHeaderCard(),
            const SizedBox(height: 10),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(child: Text(_error!))
                      : _grouped.isEmpty
                          ? const Center(child: Text("Aucune intervention sur la période."))
                          : ListView(
                              children: _grouped.entries
                                  .map((e) => _buildDayCard(e.key, e.value))
                                  .toList(),
                            ),
            ),
          ],
        ),
      ),
    );
  }
}
