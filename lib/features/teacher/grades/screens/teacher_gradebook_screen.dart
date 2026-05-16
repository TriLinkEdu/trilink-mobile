import 'package:flutter/material.dart';

import '../../../../core/services/api_service.dart';
import '../../../../core/routes/route_names.dart';

/// Teacher → Gradebook for a class (`GET /grades/class/:id`) with write
/// actions (release, delete, edit) layered on top.
class TeacherGradebookScreen extends StatefulWidget {
  const TeacherGradebookScreen({super.key});

  @override
  State<TeacherGradebookScreen> createState() => _TeacherGradebookScreenState();
}

class _TeacherGradebookScreenState extends State<TeacherGradebookScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _classes = const [];
  List<Map<String, dynamic>> _terms = const [];
  String? _classOfferingId;
  String? _termId;
  Map<String, dynamic> _gradebook = const {'groups': []};

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      final year = await ApiService().getActiveAcademicYear();
      final yearId =
          (year['id'] ?? (year['data'] as Map?)?['id']) as String? ?? '';
      final results = await Future.wait([
        ApiService().getMyClassOfferings(yearId),
        ApiService().getAcademicYearTerms(yearId),
      ]);
      _classes = results[0].whereType<Map<String, dynamic>>().toList();
      _terms = results[1].whereType<Map<String, dynamic>>().toList();
      _classOfferingId = _classes.isNotEmpty ? _classes.first['id'] as String? : null;
      _termId = _terms.isNotEmpty ? _terms.first['id'] as String? : null;
      await _loadGradebook();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load: $e';
        _loading = false;
      });
    }
  }

  Future<void> _loadGradebook() async {
    if (_classOfferingId == null) {
      setState(() {
        _gradebook = {'groups': []};
        _loading = false;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await ApiService().getClassGrades(
        _classOfferingId!,
        termId: _termId,
      );
      if (!mounted) return;
      setState(() {
        _gradebook = res;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load gradebook: $e';
        _loading = false;
      });
    }
  }

  Future<void> _release(Map<String, dynamic> group) async {
    try {
      await ApiService().releaseGradesGroup(
        classOfferingId: _classOfferingId!,
        title: group['title'] as String,
      );
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Released.')));
      _loadGradebook();
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Release failed: $e')));
    }
  }

  Future<void> _deleteGroup(Map<String, dynamic> group) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete assessment?'),
        content: Text(
            'Delete every entry of "${group['title']}"? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton.tonal(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ApiService().deleteGradesGroup(
        classOfferingId: _classOfferingId!,
        title: group['title'] as String,
      );
      _loadGradebook();
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Delete failed: $e')));
    }
  }

  Future<void> _addOrEditAssessment({Map<String, dynamic>? existingGroup}) async {
    if (_classOfferingId == null || _termId == null) return;
    final saved = await Navigator.pushNamed(
      context,
      RouteNames.teacherGradebookEntry,
      arguments: <String, dynamic>{
        'classOfferingId': _classOfferingId,
        'termId': _termId,
        'termLabel': _termLabel(
          _terms.firstWhere((t) => t['id'] == _termId, orElse: () => const <String, dynamic>{}),
        ),
        if (existingGroup != null) 'existingGroup': existingGroup,
      },
    );
    if (saved == true) _loadGradebook();
  }

  @override
  Widget build(BuildContext context) {
    final groups = ((_gradebook['groups'] as List?) ?? const [])
        .whereType<Map<String, dynamic>>()
        .toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gradebook'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _loadGradebook,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: (_classOfferingId == null || _termId == null)
            ? null
            : () => _addOrEditAssessment(),
        icon: const Icon(Icons.add),
        label: const Text('Assessment'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  value: _termId,
                  decoration: const InputDecoration(
                    labelText: 'Term',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: _terms
                      .map((t) => DropdownMenuItem(
                            value: t['id'] as String?,
                            child: Text(
                              _termLabel(t),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ))
                      .toList(),
                  onChanged: _terms.isEmpty
                      ? null
                      : (v) {
                          if (v == _termId) return;
                          setState(() => _termId = v);
                          _loadGradebook();
                        },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _classOfferingId,
                  decoration: const InputDecoration(
                    labelText: 'Class',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: _classes
                      .map((c) => DropdownMenuItem(
                            value: c['id'] as String?,
                            child: Text(_classLabel(c),
                                overflow: TextOverflow.ellipsis),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v == _classOfferingId) return;
                    setState(() => _classOfferingId = v);
                    _loadGradebook();
                  },
                ),
                if (!_loading && _terms.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'No terms found for the active academic year.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(_error!, textAlign: TextAlign.center),
                      ))
                    : groups.isEmpty
                        ? const Center(
                            child: Text('No assessments yet for this class.'),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadGradebook,
                            child: ListView(
                              padding: const EdgeInsets.all(12),
                              children: groups
                                  .map((g) => _GroupCard(
                                        group: g,
                                        onRelease: () => _release(g),
                                        onDelete: () => _deleteGroup(g),
                                        onEdit: () => _addOrEditAssessment(
                                            existingGroup: g),
                                      ))
                                  .toList(),
                            ),
                          ),
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

  static String _termLabel(Map<String, dynamic> term) {
    final name = term['name']?.toString() ?? 'Term';
    final start = term['startDate']?.toString();
    final end = term['endDate']?.toString();
    if (start != null && start.isNotEmpty && end != null && end.isNotEmpty) {
      return '$name • $start to $end';
    }
    return name;
  }
}

class _GroupCard extends StatelessWidget {
  final Map<String, dynamic> group;
  final VoidCallback onRelease;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  const _GroupCard({
    required this.group,
    required this.onRelease,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final entries = ((group['entries'] as List?) ?? const [])
        .whereType<Map<String, dynamic>>()
        .toList();
    final released = group['releasedAt'] != null;
    return Card(
      child: ExpansionTile(
        title: Text(
          group['title']?.toString() ?? '(untitled)',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
            'Type: ${group['type'] ?? '-'}  •  Max ${group['maxScore'] ?? '-'}  •  ${released ? 'Released' : 'Draft'}'),
        children: [
          ...entries.map(
            (e) => ListTile(
              dense: true,
              title: Text('${e['firstName'] ?? ''} ${e['lastName'] ?? ''}'),
              trailing: Text(
                e['score'] == null ? '—' : '${e['score']}/${e['maxScore']}',
                style: const TextStyle(fontFeatures: [FontFeature.tabularFigures()]),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Wrap(
              spacing: 8,
              children: [
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit scores'),
                ),
                if (!released)
                  FilledButton.tonalIcon(
                    onPressed: onRelease,
                    icon: const Icon(Icons.send),
                    label: const Text('Release'),
                  ),
                TextButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
