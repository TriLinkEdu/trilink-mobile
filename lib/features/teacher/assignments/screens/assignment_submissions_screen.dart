import 'package:flutter/material.dart';

import '../../../../core/services/api_service.dart';

/// Teacher → Submissions list for one assignment.
/// Backed by `GET /assignments/:id/submissions`, with grade & release actions.
class AssignmentSubmissionsScreen extends StatefulWidget {
  final String assignmentId;
  final String? title;
  const AssignmentSubmissionsScreen({
    super.key,
    required this.assignmentId,
    this.title,
  });

  @override
  State<AssignmentSubmissionsScreen> createState() =>
      _AssignmentSubmissionsScreenState();
}

class _AssignmentSubmissionsScreenState
    extends State<AssignmentSubmissionsScreen> {
  bool _loading = true;
  bool _busy = false;
  String? _error;
  List<Map<String, dynamic>> _items = const [];

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
      final list = await ApiService().getAssignmentSubmissions(widget.assignmentId);
      if (!mounted) return;
      setState(() {
        _items = list.whereType<Map<String, dynamic>>().toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load submissions: $e';
        _loading = false;
      });
    }
  }

  Future<void> _grade(Map<String, dynamic> s) async {
    final scoreCtrl =
        TextEditingController(text: (s['score']?.toString() ?? ''));
    final feedbackCtrl =
        TextEditingController(text: (s['feedback']?.toString() ?? ''));
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Grade submission'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: scoreCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Score'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: feedbackCtrl,
              maxLines: 4,
              decoration:
                  const InputDecoration(labelText: 'Feedback (optional)'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save')),
        ],
      ),
    );
    if (ok != true) return;
    final score = num.tryParse(scoreCtrl.text.trim());
    if (score == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Score must be a number.')),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      await ApiService().gradeSubmission(
        s['id'] as String,
        score: score,
        feedback:
            feedbackCtrl.text.trim().isEmpty ? null : feedbackCtrl.text.trim(),
      );
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _release(Map<String, dynamic> s) async {
    setState(() => _busy = true);
    try {
      await ApiService().releaseSubmission(s['id'] as String);
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _releaseAll() async {
    setState(() => _busy = true);
    try {
      final res = await ApiService().releaseAllSubmissions(widget.assignmentId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Released ${res['released'] ?? 0}.')),
      );
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title ?? 'Submissions'),
        actions: [
          if (_items.isNotEmpty)
            TextButton.icon(
              onPressed: _busy ? null : _releaseAll,
              icon: const Icon(Icons.outbox),
              label: const Text('Release all'),
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
              : _items.isEmpty
                  ? const Center(child: Text('No submissions yet.'))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: _items.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 6),
                        itemBuilder: (_, i) {
                          final s = _items[i];
                          final student = s['student'] as Map?;
                          final name =
                              '${student?['firstName'] ?? ''} ${student?['lastName'] ?? ''}'
                                  .trim();
                          final score = s['score'];
                          final released = s['releasedAt'] != null;
                          return Card(
                            child: ListTile(
                              title: Text(name.isEmpty ? '—' : name),
                              subtitle: Text(
                                'Status: ${s['status'] ?? '-'}'
                                '${score != null ? '  •  Score: $score' : ''}'
                                '${released ? '  •  Released' : ''}',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    tooltip: 'Grade',
                                    onPressed:
                                        _busy ? null : () => _grade(s),
                                    icon: const Icon(Icons.edit),
                                  ),
                                  IconButton(
                                    tooltip: 'Release',
                                    onPressed: _busy || score == null || released
                                        ? null
                                        : () => _release(s),
                                    icon: const Icon(Icons.send),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
