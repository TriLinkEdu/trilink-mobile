import 'package:flutter/material.dart';

import '../../../../core/services/api_service.dart';

/// Parent → Student mastery snapshot
/// (`GET /reports/students/:studentId/mastery`).
class StudentMasteryScreen extends StatefulWidget {
  final String studentId;
  final String? childName;
  const StudentMasteryScreen({
    super.key,
    required this.studentId,
    this.childName,
  });

  @override
  State<StudentMasteryScreen> createState() => _StudentMasteryScreenState();
}

class _StudentMasteryScreenState extends State<StudentMasteryScreen> {
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
      final res = await ApiService().getStudentMastery(widget.studentId);
      if (!mounted) return;
      setState(() {
        _data = res;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final classes =
        ((_data['classes'] as List?) ??
                (_data['subjects'] as List?) ??
                const [])
            .whereType<Map<String, dynamic>>()
            .toList();
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.childName?.isNotEmpty == true
              ? 'Mastery — ${widget.childName}'
              : 'Subject mastery',
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  if (classes.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(child: Text('No mastery data yet.')),
                    ),
                  ...classes.map(_card),
                ],
              ),
            ),
    );
  }

  Widget _card(Map<String, dynamic> c) {
    final mastery =
        (c['masteryPercent'] ?? c['averagePercent'] ?? c['mastery'] ?? 0)
            .toDouble();
    final double value = (mastery / 100).clamp(0.0, 1.0).toDouble();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              c['subjectName']?.toString() ?? c['className']?.toString() ?? '-',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text('Mastery: ${mastery.toStringAsFixed(1)}%'),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(value: value, minHeight: 8),
            ),
          ],
        ),
      ),
    );
  }
}
