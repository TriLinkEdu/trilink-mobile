import 'package:flutter/material.dart';

import '../../../../core/services/api_service.dart';

/// Teacher → "All my sessions" feed (`GET /attendance-sessions/my`).
///
/// One row per session across every class the teacher owns. Joined fields
/// (subject/grade/section/teacher) come back from the backend.
class TeacherAllSessionsScreen extends StatefulWidget {
  const TeacherAllSessionsScreen({super.key});

  @override
  State<TeacherAllSessionsScreen> createState() =>
      _TeacherAllSessionsScreenState();
}

class _TeacherAllSessionsScreenState extends State<TeacherAllSessionsScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _sessions = const [];

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
      final list = await ApiService().getMyAttendanceSessions();
      if (!mounted) return;
      setState(() {
        _sessions = list.whereType<Map<String, dynamic>>().toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load sessions: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All my sessions'),
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
              ? Center(child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(_error!, textAlign: TextAlign.center),
                ))
              : _sessions.isEmpty
                  ? const _EmptyState()
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: _sessions.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 6),
                        itemBuilder: (_, i) =>
                            _SessionTile(session: _sessions[i]),
                      ),
                    ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  final Map<String, dynamic> session;
  const _SessionTile({required this.session});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subj = (session['subject'] as Map?)?['name'] ?? '';
    final grade = (session['grade'] as Map?)?['name'] ?? '';
    final section = (session['section'] as Map?)?['name'] ?? '';
    final teacher = session['teacher'] as Map?;
    final teacherName = teacher == null
        ? ''
        : '${teacher['firstName'] ?? ''} ${teacher['lastName'] ?? ''}'.trim();
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Icon(Icons.event_note,
              color: theme.colorScheme.onPrimaryContainer),
        ),
        title: Text(
          session['className']?.toString() ??
              [subj, grade, section]
                  .where((e) => (e as String).isNotEmpty)
                  .join(' • '),
        ),
        subtitle: Text(
          [
            if ((session['date']?.toString() ?? '').isNotEmpty)
              session['date'].toString(),
            if (teacherName.isNotEmpty) teacherName,
          ].join(' • '),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          // Hook into existing attendance detail if/when wired.
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Session id: ${session['sessionId']}'),
            ),
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.event_busy_outlined, size: 48),
            const SizedBox(height: 12),
            Text(
              'No attendance sessions yet.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
