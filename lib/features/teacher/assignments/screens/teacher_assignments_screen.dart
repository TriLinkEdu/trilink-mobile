import 'package:flutter/material.dart';

import '../../../../core/services/api_service.dart';
import '../../../../core/routes/route_names.dart';

/// Teacher → list of assignments (`GET /assignments/teacher/mine`).
///
/// Supports class + term filters, lets you publish/unpublish/delete drafts,
/// and links to the create/edit form and the submissions screen.
class TeacherAssignmentsScreen extends StatefulWidget {
  const TeacherAssignmentsScreen({super.key});

  @override
  State<TeacherAssignmentsScreen> createState() =>
      _TeacherAssignmentsScreenState();
}

class _TeacherAssignmentsScreenState extends State<TeacherAssignmentsScreen> {
  bool _loading = true;
  String? _error;

  List<Map<String, dynamic>> _classes = const [];
  List<Map<String, dynamic>> _terms = const [];
  List<Map<String, dynamic>> _items = const [];

  String? _classOfferingId;
  String? _termId;

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
        if (yearId.isNotEmpty) ApiService().getAcademicYearTerms(yearId),
      ]);
      _classes = (results[0]).whereType<Map<String, dynamic>>().toList();
      if (results.length > 1) {
        _terms = (results[1]).whereType<Map<String, dynamic>>().toList();
      }
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load: $e';
        _loading = false;
      });
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await ApiService().getTeacherAssignments(
        classOfferingId: _classOfferingId,
        termId: _termId,
      );
      if (!mounted) return;
      setState(() {
        _items = list.whereType<Map<String, dynamic>>().toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load assignments: $e';
        _loading = false;
      });
    }
  }

  Future<void> _openForm({Map<String, dynamic>? existing}) async {
    final saved = await Navigator.pushNamed(
      context,
      RouteNames.teacherAssignmentForm,
      arguments: <String, dynamic>{
        if (existing != null) 'existing': existing,
        'classes': _classes,
        'terms': _terms,
      },
    );
    if (saved == true) _refresh();
  }

  Future<void> _publish(Map<String, dynamic> a, bool publish) async {
    try {
      if (publish) {
        await ApiService().publishAssignment(a['id'] as String);
      } else {
        await ApiService().unpublishAssignment(a['id'] as String);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(publish ? 'Published.' : 'Unpublished.')),
      );
      _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  Future<void> _delete(Map<String, dynamic> a) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete assignment?'),
        content: Text('Delete "${a['title'] ?? ''}"? This cannot be undone.'),
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
      await ApiService().deleteAssignment(a['id'] as String);
      _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Delete failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assignments'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('New'),
      ),
      body: Column(
        children: [
          _Filters(
            classes: _classes,
            terms: _terms,
            classId: _classOfferingId,
            termId: _termId,
            onClassChanged: (v) {
              setState(() => _classOfferingId = v);
              _refresh();
            },
            onTermChanged: (v) {
              setState(() => _termId = v);
              _refresh();
            },
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
                    : _items.isEmpty
                        ? const Center(
                            child: Text('No assignments match your filters.'))
                        : RefreshIndicator(
                            onRefresh: _refresh,
                            child: ListView.separated(
                              padding: const EdgeInsets.all(12),
                              itemCount: _items.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 6),
                              itemBuilder: (_, i) {
                                final a = _items[i];
                                return _AssignmentTile(
                                  data: a,
                                  onTap: () => Navigator.pushNamed(
                                    context,
                                    RouteNames.teacherAssignmentSubmissions,
                                    arguments: <String, dynamic>{
                                      'assignmentId': a['id'],
                                      'title': a['title'],
                                    },
                                  ),
                                  onEdit: () => _openForm(existing: a),
                                  onPublish: () => _publish(
                                      a, !((a['published'] as bool?) ?? false)),
                                  onDelete: () => _delete(a),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

class _Filters extends StatelessWidget {
  final List<Map<String, dynamic>> classes;
  final List<Map<String, dynamic>> terms;
  final String? classId;
  final String? termId;
  final ValueChanged<String?> onClassChanged;
  final ValueChanged<String?> onTermChanged;
  const _Filters({
    required this.classes,
    required this.terms,
    required this.classId,
    required this.termId,
    required this.onClassChanged,
    required this.onTermChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String?>(
              value: classId,
              decoration: const InputDecoration(
                labelText: 'Class',
                isDense: true,
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('All classes')),
                ...classes.map((c) => DropdownMenuItem(
                      value: c['id'] as String?,
                      child: Text(_classLabel(c), overflow: TextOverflow.ellipsis),
                    )),
              ],
              onChanged: onClassChanged,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonFormField<String?>(
              value: termId,
              decoration: const InputDecoration(
                labelText: 'Term',
                isDense: true,
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('All terms')),
                ...terms.map((t) => DropdownMenuItem(
                      value: t['id'] as String?,
                      child: Text(t['name'] as String? ?? 'Term'),
                    )),
              ],
              onChanged: onTermChanged,
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
}

class _AssignmentTile extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onPublish;
  final VoidCallback onDelete;
  const _AssignmentTile({
    required this.data,
    required this.onTap,
    required this.onEdit,
    required this.onPublish,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final published = (data['published'] as bool?) ?? false;
    final overdue = (data['isOverdue'] as bool?) ?? false;
    final subj = (data['subject'] as Map?)?['name'] ?? '';
    final grade = (data['grade'] as Map?)?['name'] ?? '';
    final section = (data['section'] as Map?)?['name'] ?? '';
    return Card(
      child: ListTile(
        title: Text(data['title']?.toString() ?? '(untitled)'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text([subj, grade, if ((section as String).isNotEmpty) 'Sec $section']
                .where((e) => (e as String).isNotEmpty)
                .join(' • ')),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              children: [
                _Chip(
                  label: published ? 'Published' : 'Draft',
                  color: published
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline,
                ),
                if (overdue)
                  _Chip(
                    label: 'Overdue',
                    color: theme.colorScheme.error,
                  ),
                if ((data['deadline']?.toString() ?? '').isNotEmpty)
                  _Chip(
                    label:
                        'Due ${data['deadline'].toString().split('T').first}',
                    color: theme.colorScheme.tertiary,
                  ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (v) {
            switch (v) {
              case 'edit':
                onEdit();
                break;
              case 'publish':
                onPublish();
                break;
              case 'delete':
                onDelete();
                break;
            }
          },
          itemBuilder: (_) => [
            if (!published)
              const PopupMenuItem(value: 'edit', child: Text('Edit')),
            PopupMenuItem(
              value: 'publish',
              child: Text(published ? 'Unpublish' : 'Publish'),
            ),
            if (!published)
              const PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
            color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}
