import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/api_service.dart';
import 'parent_subject_detail_screen.dart';
import '../../../shared/widgets/role_page_background.dart';

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

  @override
  void initState() {
    super.initState();
    _studentId = widget.studentId ?? '';
    _studentName = widget.childName ?? '';
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      String sid = _studentId;
      if (sid.isEmpty) {
        final children = await ApiService().getMyChildren();
        if (children.isNotEmpty) {
          final s = children[0]['student'] as Map<String, dynamic>?;
          sid =
              s?['id'] as String? ?? children[0]['studentId'] as String? ?? '';
          _studentName = '${s?['firstName'] ?? ''} ${s?['lastName'] ?? ''}'
              .trim();
        }
      }
      if (sid.isEmpty) {
        setState(() => _loading = false);
        return;
      }
      _studentId = sid;

      // GET /reports/students/:studentId/report
      final report = await ApiService().getStudentReport(sid);
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
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: theme.colorScheme.onSurface,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Academic Results',
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
        centerTitle: true,
      ),
      body: RolePageBackground(
        flavor: RoleThemeFlavor.parent,
        child: _loading
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
                      _buildSummaryCard(),
                      const SizedBox(height: 20),
                      _buildSectionLabel('Subject Results'),
                      const SizedBox(height: 10),
                      _buildSubjectsList(),
                      const SizedBox(height: 20),
                    ],
                  ),
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
            Icon(
              Icons.wifi_off_rounded,
              size: 48,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
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
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
            child: Text(
              initials,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _studentName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                if (_gradeSection.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _gradeSection,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    final summary = _report['summary'] as Map<String, dynamic>? ?? {};
    final avgPct = summary['overallSubjectsAveragePercent'] as num?;
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

    return SizedBox(
      width: double.infinity,
      child: Container(
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
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Overall Performance',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              avgPct != null ? '${avgPct.toStringAsFixed(0)}%' : '--',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 48,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Average across $courses subject${courses == 1 ? '' : 's'}',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.assignment_outlined,
                    color: Colors.white,
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$releasedCount exam${releasedCount == 1 ? '' : 's'} released',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }

  Widget _buildSubjectsList() {
    final courses = (_report['courses'] as List<dynamic>?) ?? [];
    if (courses.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 32),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(
              Icons.menu_book_outlined,
              size: 36,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 8),
            Text(
              'No subject data for this period',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    final colors = [
      AppColors.primary,
      AppColors.secondary,
      AppColors.subjectPurple,
      AppColors.subjectOrange,
      AppColors.subjectTeal,
      AppColors.subjectPink,
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
        final attendance = course['attendance'] as Map<String, dynamic>? ?? {};
        final totals = attendance['totals'] as Map<String, dynamic>? ?? {};

        final subjectId = subject['id'] as String? ?? '';
        final subjectName = subject['name'] as String? ?? 'Unknown';
        final teacherName =
            '${teacher['firstName'] ?? ''} ${teacher['lastName'] ?? ''}'.trim();
        final avgPct = assessments['averagePercent'] as num?;
        final releasedCount = assessments['releasedCount'] as int? ?? 0;
        final exams = (assessments['details'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>();
        final color = colors[i % colors.length];

        return _SubjectResultCard(
          studentId: _studentId,
          studentName: _studentName,
          subjectId: subjectId,
          subjectName: subjectName,
          teacherName: teacherName,
          avgPercent: avgPct,
          releasedCount: releasedCount,
          color: color,
          exams: exams,
        );
      }).toList(),
    );
  }
}

// ─── Subject Result Card ─────────────────────────────────

class _SubjectResultCard extends StatefulWidget {
  final String studentId;
  final String studentName;
  final String subjectId;
  final String subjectName;
  final String teacherName;
  final num? avgPercent;
  final int releasedCount;
  final Color color;
  final List<Map<String, dynamic>> exams;

  const _SubjectResultCard({
    required this.studentId,
    required this.studentName,
    required this.subjectId,
    required this.subjectName,
    required this.teacherName,
    this.avgPercent,
    required this.releasedCount,
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
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
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
                          color: widget.color,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.subjectName,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.teacherName,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
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
                            color: _scoreColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${widget.releasedCount} exam${widget.releasedCount == 1 ? '' : 's'}',
                        style: TextStyle(
                          fontSize: 10,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            Divider(
              height: 1,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.exams.isNotEmpty) ...[
                    Text(
                      'Recent Exam Results',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
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
                              child: Text(
                                title,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              score != null
                                  ? '${score.toStringAsFixed(0)}/${maxPoints.toStringAsFixed(0)}'
                                  : '--',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: c,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 12),
                  ] else ...[
                    Text(
                      'No exams released yet',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ParentSubjectDetailScreen(
                              studentId: widget.studentId,
                              subjectId: widget.subjectId,
                              subjectName: widget.subjectName,
                              childName: widget.studentName,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.arrow_forward, size: 16),
                      label: const Text('View Details'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.color,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
