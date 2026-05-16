import 'package:flutter/material.dart';

import '../../../../core/services/api_service.dart';
import '../../../../core/routes/route_names.dart';

/// Teacher → Homeroom class screen.
///
/// Shows the homeroom assignment + student roster pulled from
/// `GET /homeroom/my-class` and lets the teacher open the term-remark form
/// for any student.
class TeacherHomeroomScreen extends StatefulWidget {
  const TeacherHomeroomScreen({super.key});

  @override
  State<TeacherHomeroomScreen> createState() => _TeacherHomeroomScreenState();
}

class _TeacherHomeroomScreenState extends State<TeacherHomeroomScreen> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _assignment;
  List<Map<String, dynamic>> _students = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await ApiService().getMyHomeroomClass();
      if (!mounted) return;
      setState(() {
        _assignment = res['assignment'] as Map<String, dynamic>?;
        _students = ((res['students'] as List?) ?? const [])
            .whereType<Map<String, dynamic>>()
            .toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load homeroom class: $e';
        _loading = false;
      });
    }
  }

  void _openRemarkForm(Map<String, dynamic> student) {
    Navigator.pushNamed(
      context,
      RouteNames.teacherHomeroomRemark,
      arguments: <String, dynamic>{
        'studentId': student['id'],
        'studentName':
            '${student['firstName'] ?? ''} ${student['lastName'] ?? ''}'.trim(),
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Homeroom Class'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorBanner(message: _error!, onRetry: _load)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _AssignmentCard(assignment: _assignment),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Students (${_students.length})',
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_students.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          child: Center(
                            child: Text(
                              _assignment == null
                                  ? 'You are not assigned as a homeroom teacher.'
                                  : 'No students enrolled yet.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        )
                      else
                        ..._students.map(
                          (s) => Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor:
                                    theme.colorScheme.primaryContainer,
                                child: Text(
                                  _initials(s),
                                  style: TextStyle(
                                    color: theme.colorScheme.onPrimaryContainer,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              title: Text(
                                '${s['firstName'] ?? ''} ${s['lastName'] ?? ''}'
                                    .trim(),
                              ),
                              subtitle: Text(
                                [
                                  if ((s['grade'] as String?)?.isNotEmpty ??
                                      false)
                                    s['grade'],
                                  if ((s['section'] as String?)?.isNotEmpty ??
                                      false)
                                    'Section ${s['section']}',
                                ].whereType<String>().join(' • '),
                              ),
                              trailing: TextButton.icon(
                                onPressed: () => _openRemarkForm(s),
                                icon: const Icon(Icons.rate_review_outlined),
                                label: const Text('Remark'),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }

  String _initials(Map<String, dynamic> s) {
    final f = (s['firstName'] as String? ?? '').trim();
    final l = (s['lastName'] as String? ?? '').trim();
    final parts = [
      if (f.isNotEmpty) f[0],
      if (l.isNotEmpty) l[0],
    ];
    return parts.join().toUpperCase();
  }
}

class _AssignmentCard extends StatelessWidget {
  final Map<String, dynamic>? assignment;
  const _AssignmentCard({required this.assignment});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (assignment == null) {
      return Card(
        color: theme.colorScheme.surfaceContainerHighest,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: theme.colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'You don’t have a homeroom class assigned for the active '
                  'academic year. Ask an admin to assign you on '
                  '`POST /homeroom/assign`.',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Active assignment',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            _kv('Assignment ID', assignment!['id']),
            _kv('Academic year', assignment!['academicYearId']),
            _kv('Grade ID', assignment!['gradeId']),
            _kv('Section ID', assignment!['sectionId']),
            _kv('Created at', assignment!['createdAt']),
          ],
        ),
      ),
    );
  }

  Widget _kv(String k, dynamic v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(
        '$k: ${v ?? '-'}',
        style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorBanner({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
