import 'package:flutter/material.dart';

import '../../../../core/services/api_service.dart';

/// Parent → consolidated "Upcoming" view for a child
/// (`GET /parent-students/children/:studentId/upcoming`).
///
/// Combines exams + assignments + summary in a single payload.
class ParentUpcomingScreen extends StatefulWidget {
  final String studentId;
  final String? childName;
  const ParentUpcomingScreen({
    super.key,
    required this.studentId,
    this.childName,
  });

  @override
  State<ParentUpcomingScreen> createState() => _ParentUpcomingScreenState();
}

class _ParentUpcomingScreenState extends State<ParentUpcomingScreen> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic> _data = const {};

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
      final res = await ApiService().getChildUpcoming(widget.studentId);
      if (!mounted) return;
      setState(() {
        _data = res;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final summary = (_data['summary'] as Map?) ?? const {};
    final exams = ((_data['exams'] as List?) ?? const [])
        .whereType<Map<String, dynamic>>()
        .toList();
    final assignments = ((_data['assignments'] as List?) ?? const [])
        .whereType<Map<String, dynamic>>()
        .toList();
    return Scaffold(
      appBar: AppBar(
          title: Text(widget.childName?.isNotEmpty == true
              ? 'Upcoming — ${widget.childName}'
              : 'Upcoming')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(_error!, textAlign: TextAlign.center),
                ))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _SummaryCard(summary: summary),
                      const SizedBox(height: 20),
                      _SectionHeader(
                        title: 'Exams',
                        count: exams.length,
                      ),
                      if (exams.isEmpty)
                        const _EmptyHint('No upcoming exams.'),
                      ...exams.map(_examTile),
                      const SizedBox(height: 20),
                      _SectionHeader(
                        title: 'Assignments',
                        count: assignments.length,
                      ),
                      if (assignments.isEmpty)
                        const _EmptyHint('No outstanding assignments.'),
                      ...assignments.map(_assignmentTile),
                    ],
                  ),
                ),
    );
  }

  Widget _examTile(Map<String, dynamic> e) {
    return Card(
      child: ListTile(
        title: Text(e['title']?.toString() ?? '(untitled)'),
        subtitle: Text(
          [
            if ((e['subjectName']?.toString() ?? '').isNotEmpty)
              e['subjectName'],
            if ((e['gradeName']?.toString() ?? '').isNotEmpty) e['gradeName'],
            if ((e['opensAt']?.toString() ?? '').isNotEmpty)
              'Opens ${e['opensAt'].toString().split('T').first}',
          ].whereType<String>().join(' • '),
        ),
        trailing: _StatusChip(status: e['status']?.toString() ?? 'upcoming'),
      ),
    );
  }

  Widget _assignmentTile(Map<String, dynamic> a) {
    return Card(
      child: ListTile(
        title: Text(a['title']?.toString() ?? '(untitled)'),
        subtitle: Text(
          [
            if ((a['subjectName']?.toString() ?? '').isNotEmpty)
              a['subjectName'],
            if ((a['deadline']?.toString() ?? '').isNotEmpty)
              'Due ${a['deadline'].toString().split('T').first}',
          ].whereType<String>().join(' • '),
        ),
        trailing: _StatusChip(status: a['status']?.toString() ?? 'pending'),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final Map summary;
  const _SummaryCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget cell(String label, dynamic value) {
      return Expanded(
        child: Column(
          children: [
            Text('${value ?? 0}',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(label,
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(children: [
              cell('Exams', summary['examsTotal']),
              cell('Upcoming', summary['examsUpcoming']),
              cell('Missed', summary['examsMissed']),
            ]),
            const Divider(),
            Row(children: [
              cell('Assignments', summary['assignmentsTotal']),
              cell('Pending', summary['assignmentsPending']),
              cell('Overdue', summary['assignmentsOverdue']),
            ]),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Color color;
    switch (status) {
      case 'graded':
      case 'submitted':
        color = theme.colorScheme.primary;
        break;
      case 'available':
        color = theme.colorScheme.tertiary;
        break;
      case 'missed':
      case 'overdue':
        color = theme.colorScheme.error;
        break;
      default:
        color = theme.colorScheme.outline;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(status,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  const _SectionHeader({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(width: 8),
          Text('($count)',
              style: TextStyle(color: Theme.of(context).colorScheme.outline)),
        ],
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final String text;
  const _EmptyHint(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Text(
          text,
          style: TextStyle(color: Theme.of(context).colorScheme.outline),
        ),
      ),
    );
  }
}
