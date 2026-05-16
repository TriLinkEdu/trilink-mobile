import 'package:flutter/material.dart';

import '../../../../core/services/api_service.dart';

/// Teacher → Create or edit a draft assignment (`POST /assignments` or
/// `PATCH /assignments/:id`).
class AssignmentFormScreen extends StatefulWidget {
  final Map<String, dynamic>? existing;
  final List<Map<String, dynamic>> classes;
  final List<Map<String, dynamic>> terms;
  const AssignmentFormScreen({
    super.key,
    this.existing,
    this.classes = const [],
    this.terms = const [],
  });

  @override
  State<AssignmentFormScreen> createState() => _AssignmentFormScreenState();
}

class _AssignmentFormScreenState extends State<AssignmentFormScreen> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _maxScoreCtrl = TextEditingController(text: '100');

  String? _classOfferingId;
  String? _termId;
  String _submissionType = 'file'; // 'file' | 'text' | 'none'
  DateTime? _deadline;
  bool _saving = false;

  bool get _isEdit => widget.existing != null;
  String get _existingId => widget.existing?['id'] as String? ?? '';

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _titleCtrl.text = e['title']?.toString() ?? '';
      _descCtrl.text = e['description']?.toString() ?? '';
      _maxScoreCtrl.text = (e['maxScore'] ?? 100).toString();
      _classOfferingId = e['classOfferingId'] as String?;
      _termId = e['termId'] as String?;
      _submissionType = (e['submissionType'] as String?) ?? 'file';
      final dl = e['deadline'] as String?;
      if (dl != null) _deadline = DateTime.tryParse(dl);
    } else if (widget.classes.isNotEmpty) {
      _classOfferingId = widget.classes.first['id'] as String?;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _maxScoreCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _deadline ?? now.add(const Duration(days: 7)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null) return;
    if (!mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_deadline ?? now),
    );
    if (time == null) return;
    setState(() {
      _deadline = DateTime(
          date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty ||
        _classOfferingId == null ||
        _deadline == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title, class and deadline are required.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final maxScore = num.tryParse(_maxScoreCtrl.text.trim());
      if (_isEdit) {
        await ApiService().updateAssignment(_existingId, {
          'title': _titleCtrl.text.trim(),
          'description': _descCtrl.text.trim().isEmpty
              ? null
              : _descCtrl.text.trim(),
          'submissionType': _submissionType,
          'deadline': _deadline!.toUtc().toIso8601String(),
          if (maxScore != null) 'maxScore': maxScore,
          if (_termId != null) 'termId': _termId,
        });
      } else {
        await ApiService().createAssignment(
          classOfferingId: _classOfferingId!,
          title: _titleCtrl.text.trim(),
          submissionType: _submissionType,
          deadline: _deadline!.toUtc().toIso8601String(),
          description: _descCtrl.text.trim().isEmpty
              ? null
              : _descCtrl.text.trim(),
          maxScore: maxScore,
          termId: _termId,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Save failed: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit assignment' : 'New assignment'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DropdownButtonFormField<String>(
            value: _classOfferingId,
            decoration: const InputDecoration(
              labelText: 'Class',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.class_outlined),
            ),
            items: widget.classes
                .map((c) => DropdownMenuItem(
                      value: c['id'] as String?,
                      child: Text(_classLabel(c)),
                    ))
                .toList(),
            onChanged:
                _isEdit ? null : (v) => setState(() => _classOfferingId = v),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(
              labelText: 'Title',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descCtrl,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Description (optional)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _submissionType,
            decoration: const InputDecoration(
              labelText: 'Submission type',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'file', child: Text('File upload')),
              DropdownMenuItem(value: 'text', child: Text('Text answer')),
              DropdownMenuItem(value: 'none', child: Text('No submission')),
            ],
            onChanged: (v) => setState(() => _submissionType = v ?? 'file'),
          ),
          const SizedBox(height: 12),
          ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
              side: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant),
            ),
            title: Text(_deadline == null
                ? 'Pick a deadline'
                : 'Deadline: $_deadline'),
            leading: const Icon(Icons.event),
            onTap: _pickDeadline,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _maxScoreCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Max score',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.scoreboard),
            ),
          ),
          const SizedBox(height: 12),
          if (widget.terms.isNotEmpty)
            DropdownButtonFormField<String?>(
              value: _termId,
              decoration: const InputDecoration(
                labelText: 'Term (optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.event_note),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('No term')),
                ...widget.terms.map(
                  (t) => DropdownMenuItem(
                    value: t['id'] as String?,
                    child: Text(t['name'] as String? ?? 'Term'),
                  ),
                ),
              ],
              onChanged: (v) => setState(() => _termId = v),
            ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.save),
            label: Text(_saving
                ? 'Saving…'
                : _isEdit
                    ? 'Save changes'
                    : 'Create draft'),
          ),
        ],
      ),
    );
  }

  static String _classLabel(Map<String, dynamic> c) {
    final subj = c['subjectName'] ?? c['subject']?['name'] ?? '';
    final grade = c['gradeName'] ?? c['grade']?['name'] ?? '';
    final section = c['sectionName'] ?? c['section']?['name'] ?? '';
    return [subj, grade, if ((section as String).isNotEmpty) 'Sec $section']
        .where((e) => (e as String).isNotEmpty)
        .join(' • ');
  }
}
