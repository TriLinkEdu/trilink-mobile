import 'package:flutter/material.dart';

import '../../../../core/services/api_service.dart';
import '../../../../core/routes/route_names.dart';
import '../../../parent/report_cards/screens/parent_report_card_screen.dart';

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

  void _openStudentReportCard(Map<String, dynamic> student) {
    final id = student['id'] as String? ?? '';
    if (id.isEmpty) return;
    final name = '${student['firstName'] ?? ''} ${student['lastName'] ?? ''}'
        .trim();
    // Reuse the role-neutral term-report-card screen. It calls
    // `GET /report-cards/student/:studentId/term/:termId` internally.
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ParentReportCardScreen(
          studentId: id,
          childName: name.isEmpty ? null : name,
        ),
      ),
    );
  }

  void _openClassReportCard() {
    final a = _assignment;
    if (a == null) return;
    final gradeId = a['gradeId'] as String? ?? '';
    final sectionId = a['sectionId'] as String? ?? '';
    if (gradeId.isEmpty || sectionId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Homeroom assignment is missing grade/section.'),
        ),
      );
      return;
    }
    Navigator.pushNamed(
      context,
      RouteNames.teacherClassRanking,
      arguments: <String, String>{'gradeId': gradeId, 'sectionId': sectionId},
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
                  if (_assignment != null) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.tonalIcon(
                        onPressed: _openClassReportCard,
                        icon: const Icon(Icons.assessment_outlined),
                        label: const Text('Class report card'),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Students (${_students.length})',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
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
                      (s) => Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: theme.colorScheme.outlineVariant,
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.person_outline,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                          title: Text(
                            '${s['firstName'] ?? ''} ${s['lastName'] ?? ''}'
                                .trim(),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                if ((s['grade'] as String?)?.isNotEmpty ??
                                    false)
                                  _Pill(label: '${s['grade']}'),
                                if ((s['section'] as String?)?.isNotEmpty ??
                                    false)
                                  _Pill(label: 'Section ${s['section']}'),
                              ],
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'Report card',
                                onPressed: () => _openStudentReportCard(s),
                                icon: const Icon(Icons.assessment_outlined),
                              ),
                              IconButton(
                                tooltip: 'Remark',
                                onPressed: () => _openRemarkForm(s),
                                icon: const Icon(Icons.rate_review_outlined),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
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
      elevation: 0,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary.withValues(alpha: 0.08),
              theme.colorScheme.surface,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.class_outlined,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Active assignment',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Homeroom class details for the current academic year',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.45,
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.verified_outlined,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Homeroom assignment is active for the current academic year.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                        height: 1.25,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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

class _Pill extends StatelessWidget {
  final String label;

  const _Pill({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}
