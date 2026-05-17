import 'package:flutter/material.dart';

import '../../../../core/services/api_service.dart';

/// Teacher → Add / update a homeroom remark (`POST /report-cards/remarks`).
///
/// Requires `studentId` and a term selection. Term list is loaded from the
/// active academic year (`GET /academic-years/:yearId/terms`).
class TeacherRemarkFormScreen extends StatefulWidget {
  final String studentId;
  final String studentName;
  const TeacherRemarkFormScreen({
    super.key,
    required this.studentId,
    required this.studentName,
  });

  @override
  State<TeacherRemarkFormScreen> createState() =>
      _TeacherRemarkFormScreenState();
}

class _TeacherRemarkFormScreenState extends State<TeacherRemarkFormScreen> {
  final _remarkCtrl = TextEditingController();
  final _conductCtrl = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  String? _error;
  List<Map<String, dynamic>> _terms = const [];
  String? _termId;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _remarkCtrl.dispose();
    _conductCtrl.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    try {
      final year = await ApiService().getActiveAcademicYear();
      final yearId =
          (year['id'] ?? (year['data'] as Map?)?['id']) as String?;
      if (yearId == null || yearId.isEmpty) {
        throw Exception('No active academic year.');
      }
      final terms = await ApiService().getAcademicYearTerms(yearId);
      if (!mounted) return;
      setState(() {
        _terms = terms.whereType<Map<String, dynamic>>().toList();
        _termId = _terms.isNotEmpty ? _terms.first['id'] as String? : null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load terms: $e';
        _loading = false;
      });
    }
  }

  Future<void> _submit() async {
    if (_termId == null || _termId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick a term first.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await ApiService().submitRemark(
        studentId: widget.studentId,
        termId: _termId!,
        remark: _remarkCtrl.text.trim().isEmpty ? null : _remarkCtrl.text.trim(),
        conductGrade:
            _conductCtrl.text.trim().isEmpty ? null : _conductCtrl.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Remark saved.')));
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
      appBar: AppBar(title: Text('Remark — ${widget.studentName}')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(_error!, textAlign: TextAlign.center),
                ))
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DropdownButtonFormField<String>(
                        value: _termId,
                        decoration: const InputDecoration(
                          labelText: 'Term',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.event_note),
                        ),
                        items: _terms
                            .map(
                              (t) => DropdownMenuItem(
                                value: t['id'] as String?,
                                child: Text(t['name'] as String? ?? 'Term'),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _termId = v),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _remarkCtrl,
                        maxLines: 6,
                        decoration: const InputDecoration(
                          labelText: 'Homeroom remark',
                          hintText:
                              'Excellent student, keep it up! Watch out for...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _conductCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Conduct grade',
                          hintText: 'A / B / C / …',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.grade_outlined),
                        ),
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: _saving ? null : _submit,
                        icon: _saving
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white),
                              )
                            : const Icon(Icons.save),
                        label: Text(_saving ? 'Saving…' : 'Save remark'),
                      ),
                    ],
                  ),
                ),
    );
  }
}
