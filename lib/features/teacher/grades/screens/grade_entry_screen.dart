import 'package:flutter/material.dart';

import '../../../../core/services/api_service.dart';

/// Bulk grade-entry screen.
///
/// On create, loads the class roster from `GET /enrollments/class/:id/students`
/// and submits via `POST /grades/bulk`.
/// On edit (an existing group is provided), pre-populates the grid with the
/// previous entries and submits via `POST /grades/bulk` (which upserts).
class GradeEntryScreen extends StatefulWidget {
  final String classOfferingId;
  final String termId;
  final String? termLabel;
  final Map<String, dynamic>? existingGroup;
  const GradeEntryScreen({
    super.key,
    required this.classOfferingId,
    required this.termId,
    this.termLabel,
    this.existingGroup,
  });

  @override
  State<GradeEntryScreen> createState() => _GradeEntryScreenState();
}

class _GradeEntryScreenState extends State<GradeEntryScreen> {
  static const Set<String> _allowedTypes = {
    'exam',
    'assignment',
    'quiz',
    'project',
    'other',
  };

  bool _loading = true;
  bool _saving = false;
  String? _error;

  final _titleCtrl = TextEditingController();
  final _maxScoreCtrl = TextEditingController(text: '100');
  final _noteCtrl = TextEditingController();
  String _type = 'assignment';

  // studentId -> { name, scoreCtrl }
  final Map<String, _Row> _rows = {};

  bool get _isEdit => widget.existingGroup != null;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _maxScoreCtrl.dispose();
    _noteCtrl.dispose();
    for (final r in _rows.values) {
      r.scoreCtrl.dispose();
    }
    super.dispose();
  }

  Future<void> _bootstrap() async {
    try {
      final res = await ApiService().getClassStudents(widget.classOfferingId);
      final students = ((res['students'] as List?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .toList();
      for (final s in students) {
        final id = s['studentId'] as String? ?? s['id'] as String? ?? '';
        if (id.isEmpty) continue;
        _rows[id] = _Row(
          name: '${s['firstName'] ?? ''} ${s['lastName'] ?? ''}'.trim(),
          scoreCtrl: TextEditingController(),
        );
      }

      final eg = widget.existingGroup;
      if (eg != null) {
        _titleCtrl.text = eg['title']?.toString() ?? '';
        _maxScoreCtrl.text = (eg['maxScore'] ?? 100).toString();
        _type = _normalizeType((eg['type'] as String?) ?? 'assignment');
        for (final e in (eg['entries'] as List? ?? const [])) {
          if (e is! Map) continue;
          final sid = e['studentId'] as String?;
          if (sid == null) continue;
          final row = _rows[sid];
          if (row != null && e['score'] != null) {
            row.scoreCtrl.text = e['score'].toString();
          }
        }
      }

      if (!mounted) return;
      setState(() => _loading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load roster: $e';
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    final maxScore = num.tryParse(_maxScoreCtrl.text.trim());
    if (title.isEmpty || maxScore == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title and max score are required.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final entries = _rows.entries.map((kv) {
        final v = kv.value.scoreCtrl.text.trim();
        return <String, dynamic>{
          'studentId': kv.key,
          'score': v.isEmpty ? null : num.tryParse(v),
        };
      }).toList();
      await ApiService().createGradesBulk(
        classOfferingId: widget.classOfferingId,
        title: title,
        type: _normalizeType(_type),
        maxScore: maxScore,
        entries: entries,
        note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
        termId: widget.termId,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Save failed: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit assessment' : 'New assessment'),
        actions: [
          TextButton.icon(
            onPressed: _saving || _loading ? null : _save,
            icon: const Icon(Icons.save, color: Colors.white),
            label: Text(
              _saving ? 'Saving…' : 'Save',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(_error!, textAlign: TextAlign.center),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(12),
              children: [
                TextField(
                  controller: _titleCtrl,
                  enabled: !_isEdit,
                  decoration: const InputDecoration(
                    labelText: 'Title (e.g. "Quiz 1")',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _type,
                        decoration: const InputDecoration(
                          labelText: 'Type',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'assignment',
                            child: Text('Assignment'),
                          ),
                          DropdownMenuItem(value: 'quiz', child: Text('Quiz')),
                          DropdownMenuItem(value: 'exam', child: Text('Exam')),
                          DropdownMenuItem(
                            value: 'project',
                            child: Text('Project'),
                          ),
                          DropdownMenuItem(
                            value: 'other',
                            child: Text('Other'),
                          ),
                        ],
                        onChanged: _isEdit
                            ? null
                            : (v) => setState(() => _type = _normalizeType(v)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _maxScoreCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Max score',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _noteCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Note (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Term',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  child: Text(
                    widget.termLabel ?? widget.termId,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                const SizedBox(height: 16),
                Text('Scores', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                ..._rows.entries.map((kv) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(child: Text(kv.value.name)),
                        SizedBox(
                          width: 90,
                          child: TextField(
                            controller: kv.value.scoreCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            textAlign: TextAlign.right,
                            decoration: const InputDecoration(
                              isDense: true,
                              border: OutlineInputBorder(),
                              hintText: '—',
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
    );
  }

  String _normalizeType(String? raw) {
    final value = (raw ?? '').trim().toLowerCase();
    if (_allowedTypes.contains(value)) return value;
    return 'other';
  }
}

class _Row {
  final String name;
  final TextEditingController scoreCtrl;
  _Row({required this.name, required this.scoreCtrl});
}
