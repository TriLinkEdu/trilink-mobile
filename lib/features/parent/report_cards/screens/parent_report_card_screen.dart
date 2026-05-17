import 'package:flutter/material.dart';

import '../../../../core/services/api_service.dart';
import '../../../../core/routes/route_names.dart';

/// Parent → per-term report card for a child
/// (`GET /report-cards/student/:studentId/term/:termId`).
///
/// Includes a term picker plus a button to open the yearly transcript view.
class ParentReportCardScreen extends StatefulWidget {
  final String studentId;
  final String? childName;
  const ParentReportCardScreen({
    super.key,
    required this.studentId,
    this.childName,
  });

  @override
  State<ParentReportCardScreen> createState() => _ParentReportCardScreenState();
}

class _ParentReportCardScreenState extends State<ParentReportCardScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _terms = const [];
  String? _termId;
  String? _academicYearId;
  Map<String, dynamic> _data = const {};

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      final year = await ApiService().getActiveAcademicYear();
      _academicYearId =
          (year['id'] ?? (year['data'] as Map?)?['id']) as String?;
      final terms = (_academicYearId == null || _academicYearId!.isEmpty)
          ? <dynamic>[]
          : await ApiService().getAcademicYearTerms(_academicYearId!);
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
        _data = {};
        _loading = false;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await ApiService().getStudentTermReportCard(
        widget.studentId,
        _termId!,
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
    final theme = Theme.of(context);
    final subjects = ((_data['subjects'] as List?) ?? const [])
        .whereType<Map<String, dynamic>>()
        .toList();
    final attendance = (_data['attendance'] as Map?) ?? const {};
    final remark = (_data['homeroomRemark'] as Map?) ?? const {};

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.childName?.isNotEmpty == true
              ? 'Report — ${widget.childName}'
              : 'Report card',
        ),
        actions: [
          if ((_academicYearId ?? '').isNotEmpty)
            IconButton(
              tooltip: 'Yearly transcript',
              onPressed: () => Navigator.pushNamed(
                context,
                RouteNames.parentYearlyReportCard,
                arguments: <String, String>{
                  'studentId': widget.studentId,
                  'academicYearId': _academicYearId!,
                  if (widget.childName != null) 'childName': widget.childName!,
                },
              ),
              icon: const Icon(Icons.summarize),
            ),
        ],
      ),
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
                    .map(
                      (t) => DropdownMenuItem(
                        value: t['id'] as String?,
                        child: Text(t['name'] as String? ?? 'Term'),
                      ),
                    )
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
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView(
                      padding: const EdgeInsets.all(12),
                      children: [
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Overall',
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${_data['overallPercent'] ?? '-'}%  •  ${_data['overallLetterGrade'] ?? '-'}',
                                  style: theme.textTheme.titleMedium,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Attendance: ${attendance['attendancePercent'] ?? '-'}%  '
                                  '(${attendance['present'] ?? 0}/${attendance['total'] ?? 0} days)',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...subjects.map(_subjectCard),
                        const SizedBox(height: 12),
                        if (remark.isNotEmpty)
                          Card(
                            color: theme.colorScheme.surfaceContainerHighest,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Homeroom remark',
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(remark['remark']?.toString() ?? '—'),
                                  if ((remark['conductGrade']?.toString() ?? '')
                                      .isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(
                                        'Conduct: ${remark['conductGrade']}',
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _subjectCard(Map<String, dynamic> s) {
    final summary = (s['summary'] as Map?) ?? const {};
    final entries = ((s['entries'] as List?) ?? const [])
        .whereType<Map<String, dynamic>>()
        .toList();
    return Card(
      child: ExpansionTile(
        title: Text(
          s['subjectName']?.toString() ?? '-',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          'Avg ${summary['averagePercent'] ?? '-'}%  •  ${summary['letterGrade'] ?? '-'}',
        ),
        children: entries
            .map(
              (e) => ListTile(
                dense: true,
                title: Text(e['title']?.toString() ?? '-'),
                subtitle: Text('${e['type'] ?? '-'}'),
                trailing: Text(
                  '${e['score'] ?? '—'}/${e['maxScore'] ?? '-'}  '
                  '(${e['percent'] ?? '-'}%)',
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
