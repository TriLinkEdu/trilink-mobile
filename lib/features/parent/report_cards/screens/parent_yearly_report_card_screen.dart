import 'package:flutter/material.dart';

import '../../../../core/services/api_service.dart';

/// Parent → full-year transcript
/// (`GET /report-cards/student/:studentId/academic-year/:academicYearId`).
class ParentYearlyReportCardScreen extends StatefulWidget {
  final String studentId;
  final String academicYearId;
  final String? childName;
  const ParentYearlyReportCardScreen({
    super.key,
    required this.studentId,
    required this.academicYearId,
    this.childName,
  });

  @override
  State<ParentYearlyReportCardScreen> createState() =>
      _ParentYearlyReportCardScreenState();
}

class _ParentYearlyReportCardScreenState
    extends State<ParentYearlyReportCardScreen> {
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
      final res = await ApiService().getStudentYearlyReportCard(
        widget.studentId,
        widget.academicYearId,
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
    final terms = ((_data['terms'] as List?) ?? const [])
        .whereType<Map<String, dynamic>>()
        .toList();
    return Scaffold(
      appBar: AppBar(
          title: Text(widget.childName?.isNotEmpty == true
              ? 'Year — ${widget.childName}'
              : 'Yearly transcript')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(12),
                    children: [
                      if (terms.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Center(
                              child: Text(
                                  'No transcript data for this year yet.')),
                        ),
                      ...terms.map((t) => Card(
                            child: ListTile(
                              title: Text(
                                  t['termName']?.toString() ?? 'Term'),
                              subtitle: Text(
                                'GPA ${t['gpa'] ?? '-'}  •  '
                                '${t['averagePercent'] ?? '-'}%  •  '
                                '${t['letterGrade'] ?? '-'}',
                              ),
                              trailing: Text(
                                'Att ${t['attendancePercent'] ?? '-'}%',
                              ),
                            ),
                          )),
                    ],
                  ),
                ),
    );
  }
}
