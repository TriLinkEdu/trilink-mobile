import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/api_service.dart';

class ParentResultsScreen extends StatefulWidget {
  final String? studentId;
  final String? childName;

  const ParentResultsScreen({super.key, this.studentId, this.childName});

  @override
  State<ParentResultsScreen> createState() => _ParentResultsScreenState();
}

class _ParentResultsScreenState extends State<ParentResultsScreen> {
  bool _loading = true;
  String? _error;

  String _studentId = '';
  String _studentName = '';
  String _gradeSection = '';

  Map<String, dynamic> _report = {};
  String _selectedPeriod = 'monthly'; // weekly | monthly

  @override
  void initState() {
    super.initState();
    _studentId = widget.studentId ?? '';
    _studentName = widget.childName ?? '';
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _loading = true; _error = null; });
    try {
      String sid = _studentId;
      if (sid.isEmpty) {
        final children = await ApiService().getMyChildren();
        if (children.isNotEmpty) {
          final s = children[0]['student'] as Map<String, dynamic>?;
          sid = s?['id'] as String? ?? children[0]['studentId'] as String? ?? '';
          _studentName = '${s?['firstName'] ?? ''} ${s?['lastName'] ?? ''}'.trim();
        }
      }
      if (sid.isEmpty) {
        setState(() => _loading = false);
        return;
      }
      _studentId = sid;

      // GET /reports/students/:studentId/report?periodType=monthly
      final report = await ApiService().getStudentReport(
        sid,
        periodType: _selectedPeriod,
      );
      if (!mounted) return;

      final student = report['student'] as Map<String, dynamic>? ?? {};
      if (_studentName.isEmpty) {
        _studentName =
            '${student['firstName'] ?? ''} ${student['lastName'] ?? ''}'.trim();
      }
      final grade = student['grade'] as String? ?? '';
      final section = student['section'] as String? ?? '';
      _gradeSection = section.isNotEmpty ? '$grade • Section $section' : grade;

      setState(() {
        _report = report;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Academic Results',
          style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 17),
        ),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStudentHeader(),
                        const SizedBox(height: 16),
                        _buildPeriodToggle(),
                        const SizedBox(height: 16),
                        _buildSummaryCard(),
                        const SizedBox(height: 20),
                        _buildSectionLabel('Subjects'),
                        const SizedBox(height: 10),
                        _buildSubjectsList(),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(_error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentHeader() {
    final initials = _studentName.isNotEmpty
        ? _studentName
            .split(' ')
            .where((p) => p.isNotEmpty)
            .take(2)
            .map((p) => p[0].toUpperCase())
            .join()
        : '?';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
            child: Text(initials,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_studentName,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary)),
                if (_gradeSection.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(_gradeSection,
                        style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500)),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodToggle() {
    return Row(
      children: [
        _buildPeriodChip('weekly', 'This Week'),
        const SizedBox(width: 10),
        _buildPeriodChip('monthly', 'This Month'),
      ],
    );
  }

  Widget _buildPeriodChip(String value, String label) {
    final selected = _selectedPeriod == value;
    return GestureDetector(
      onTap: () {
        if (_selectedPeriod != value) {
          setState(() => _selectedPeriod = value);
          _loadData();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? AppColors.primary : Colors.grey.shade300),
          boxShadow: selected
              ? [
                  BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2))
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    final summary = _report['summary'] as Map<String, dynamic>? ?? {};
    final avgPct = summary['overallSubjectsAveragePercent'] as num?;
    final attPct = summary['overallAttendancePercent'] as num?;
    final courses = (_report['courses'] as List<dynamic>?)?.length ?? 0;
    final exams = _report['exams'] as Map<String, dynamic>? ?? {};
    final releasedCount = exams['releasedAttempts'] as int? ?? 0;

    final avgColor = avgPct == null
        ? Colors.grey
        : avgPct >= 80
            ? AppColors.success
            : avgPct >= 60
                ? AppColors.warning
                : AppColors.error;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [avgColor, avgColor.withValues(alpha: 0.75)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: avgColor.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _selectedPeriod == 'weekly' ? 'This Week' : 'This Month',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8), fontSize: 13),
          ),
          const SizedBox(height: 6),
          Text(
            avgPct != null ? '${avgPct.toStringAsFixed(0)}%' : '--',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 42,
                fontWeight: FontWeight.bold),
          ),
          Text(
            'Average across $courses subject${courses == 1 ? '' : 's'}',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8), fontSize: 12),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _buildSummaryChip(
                Icons.event_available_outlined,
                attPct != null
                    ? '${attPct.toStringAsFixed(0)}% attendance'
                    : 'No attendance data',
              ),
              const SizedBox(width: 8),
              _buildSummaryChip(
                Icons.assignment_outlined,
                '$releasedCount exam${releasedCount == 1 ? '' : 's'} released',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 13),
          const SizedBox(width: 5),
          Text(text,
              style: const TextStyle(color: Colors.white, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(text,
        style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary));
  }

  Widget _buildSubjectsList() {
    final courses = (_report['courses'] as List<dynamic>?) ?? [];
    if (courses.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 32),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(14)),
        child: Column(
          children: [
            Icon(Icons.menu_book_outlined,
                size: 36, color: Colors.grey.shade300),
            const SizedBox(height: 8),
            Text('No subject data for this period',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
          ],
        ),
      );
    }

    final colors = [
      AppColors.primary,
      AppColors.secondary,
      const Color(0xFF7C4DFF),
      const Color(0xFFFF6D00),
      const Color(0xFF00BFA5),
      const Color(0xFFE91E63),
    ];

    return Column(
      children: courses.asMap().entries.map((entry) {
        final i = entry.key;
        final course = entry.value as Map<String, dynamic>;
        final co = course['classOffering'] as Map<String, dynamic>? ?? {};
        final subject = co['subject'] as Map<String, dynamic>? ?? {};
        final teacher = co['teacher'] as Map<String, dynamic>? ?? {};
        final assessments =
            course['assessments'] as Map<String, dynamic>? ?? {};
        final attendance =
            course['attendance'] as Map<String, dynamic>? ?? {};
        final totals = attendance['totals'] as Map<String, dynamic>? ?? {};

        final subjectName = subject['name'] as String? ?? 'Unknown';
        final teacherName =
            '${teacher['firstName'] ?? ''} ${teacher['lastName'] ?? ''}'
                .trim();
        final avgPct = assessments['averagePercent'] as num?;
        final releasedCount = assessments['releasedCount'] as int? ?? 0;
        final attPct = totals['attendancePercent'] as num?;
        final exams = (assessments['details'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>();
        final color = colors[i % colors.length];

        return _SubjectResultCard(
          subjectName: subjectName,
          teacherName: teacherName,
          avgPercent: avgPct,
          releasedCount: releasedCount,
          attendancePercent: attPct,
          color: color,
          exams: exams,
        );
      }).toList(),
    );
  }
}

// ─── Subject Result Card ─────────────────────────────────

class _SubjectResultCard extends StatefulWidget {
  final String subjectName;
  final String teacherName;
  final num? avgPercent;
  final int releasedCount;
  final num? attendancePercent;
  final Color color;
  final List<Map<String, dynamic>> exams;

  const _SubjectResultCard({
    required this.subjectName,
    required this.teacherName,
    this.avgPercent,
    required this.releasedCount,
    this.attendancePercent,
    required this.color,
    required this.exams,
  });

  @override
  State<_SubjectResultCard> createState() => _SubjectResultCardState();
}

class _SubjectResultCardState extends State<_SubjectResultCard> {
  bool _expanded = false;

  Color get _scoreColor {
    final v = widget.avgPercent;
    if (v == null) return Colors.grey;
    if (v >= 80) return AppColors.success;
    if (v >= 60) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: widget.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        widget.subjectName.isNotEmpty
                            ? widget.subjectName[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: widget.color),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.subjectName,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: AppColors.textPrimary)),
                        const SizedBox(height: 2),
                        Text(widget.teacherName,
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade500)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _scoreColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          widget.avgPercent != null
                              ? '${widget.avgPercent!.toStringAsFixed(0)}%'
                              : '--',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: _scoreColor),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${widget.releasedCount} exam${widget.releasedCount == 1 ? '' : 's'}',
                        style: TextStyle(
                            fontSize: 10, color: Colors.grey.shade400),
                      ),
                    ],
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.grey.shade400,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            Divider(height: 1, color: Colors.grey.shade100),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.attendancePercent != null)
                    _buildInfoRow(
                      Icons.event_available_outlined,
                      'Attendance',
                      '${widget.attendancePercent!.toStringAsFixed(0)}%',
                      AppColors.secondary,
                    ),
                  if (widget.exams.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text('Exam Results',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600)),
                    const SizedBox(height: 8),
                    ...widget.exams.take(5).map((exam) {
                      final title = exam['examTitle'] as String? ?? 'Exam';
                      final score = exam['score'] as num?;
                      final maxPoints = exam['maxPoints'] as num? ?? 100;
                      final pct = score != null
                          ? score / maxPoints * 100
                          : null;
                      final c = pct == null
                          ? Colors.grey
                          : pct >= 80
                              ? AppColors.success
                              : pct >= 60
                                  ? AppColors.warning
                                  : AppColors.error;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(title,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textPrimary),
                                  overflow: TextOverflow.ellipsis),
                            ),
                            Text(
                              score != null
                                  ? '${score.toStringAsFixed(0)}/${maxPoints.toStringAsFixed(0)}'
                                  : '--',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: c),
                            ),
                          ],
                        ),
                      );
                    }),
                  ] else ...[
                    const SizedBox(height: 8),
                    Text('No exams released yet',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade400)),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(
      IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Text(label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        const Spacer(),
        Text(value,
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600, color: color)),
      ],
    );
  }
}
