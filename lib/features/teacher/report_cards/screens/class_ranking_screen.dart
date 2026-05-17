import 'package:flutter/material.dart';

import '../../../../core/services/api_service.dart';

/// Teacher → Class ranking for a term
/// (`GET /report-cards/class/:gradeId/:sectionId/term/:termId`).
///
/// Expected as deep-link from "My Homeroom Class" once we know the
/// `gradeId/sectionId`. The screen also lets the user pick a term.
class ClassRankingScreen extends StatefulWidget {
  final String gradeId;
  final String sectionId;
  const ClassRankingScreen({
    super.key,
    required this.gradeId,
    required this.sectionId,
  });

  @override
  State<ClassRankingScreen> createState() => _ClassRankingScreenState();
}

class _ClassRankingScreenState extends State<ClassRankingScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _terms = const [];
  String? _termId;
  Map<String, dynamic> _data = const {'students': []};

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
      final terms = yearId.isEmpty
          ? <dynamic>[]
          : await ApiService().getAcademicYearTerms(yearId);
      _terms = terms.whereType<Map<String, dynamic>>().toList();
      _termId = _terms.isNotEmpty ? _terms.first['id'] as String? : null;
      await _load();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load: $e';
        _loading = false;
      });
    }
  }

  Future<void> _load() async {
    if (_termId == null) {
      setState(() {
        _data = {'students': []};
        _loading = false;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await ApiService().getClassTermReportCard(
        gradeId: widget.gradeId,
        sectionId: widget.sectionId,
        termId: _termId!,
      );
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
    final students = ((_data['students'] as List?) ?? const [])
        .whereType<Map<String, dynamic>>()
        .toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Class ranking')),
      body: Column(
        children: [
          if (_terms.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(12),
              child: DropdownButtonFormField<String>(
                value: _termId,
                decoration: const InputDecoration(
                  labelText: 'Term',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: _terms
                    .map((t) => DropdownMenuItem(
                          value: t['id'] as String?,
                          child: Text(t['name'] as String? ?? 'Term'),
                        ))
                    .toList(),
                onChanged: (v) {
                  setState(() => _termId = v);
                  _load();
                },
              ),
            ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text(_error!))
                    : students.isEmpty
                        ? const Center(child: Text('No data for this term.'))
                        : ListView.separated(
                            padding: const EdgeInsets.all(12),
                            itemCount: students.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 4),
                            itemBuilder: (_, i) {
                              final s = students[i];
                              return Card(
                                child: ListTile(
                                  leading: CircleAvatar(
                                    child: Text('${s['rank'] ?? '-'}'),
                                  ),
                                  title: Text(
                                    '${s['firstName'] ?? ''} ${s['lastName'] ?? ''}',
                                  ),
                                  subtitle: Text(
                                    'Grade ${s['overallLetterGrade'] ?? '-'}  •  '
                                    'Avg ${s['overallPercent'] ?? '-'}%  •  '
                                    'Att ${s['attendancePercent'] ?? '-'}%',
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
