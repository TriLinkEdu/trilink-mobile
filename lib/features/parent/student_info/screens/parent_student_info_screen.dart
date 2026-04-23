import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/api_service.dart';
import '../../chat/screens/parent_message_view_screen.dart';

class ParentStudentInfoScreen extends StatefulWidget {
  final String childName;
  final String? studentUserId;

  const ParentStudentInfoScreen({
    super.key,
    required this.childName,
    this.studentUserId,
  });

  @override
  State<ParentStudentInfoScreen> createState() =>
      _ParentStudentInfoScreenState();
}

class _ParentStudentInfoScreenState extends State<ParentStudentInfoScreen> {
  bool _loading = true;
  String? _error;

  Map<String, dynamic> _detail = {};
  Map<String, dynamic> _report = {};
  List<Map<String, dynamic>> _teachers = [];

  String get _studentId => widget.studentUserId ?? '';

  String get _studentName {
    final s = _detail['student'] as Map<String, dynamic>?;
    if (s != null) {
      return '${s['firstName'] ?? ''} ${s['lastName'] ?? ''}'.trim();
    }
    return widget.childName;
  }

  String get _gradeSection {
    final s = _detail['student'] as Map<String, dynamic>?;
    if (s == null) return '';
    final g = s['grade'] as String? ?? '';
    final sec = s['section'] as String? ?? '';
    return sec.isNotEmpty ? '$g • Section $sec' : g;
  }

  String get _initials {
    final parts = _studentName.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return _studentName.isNotEmpty ? _studentName[0].toUpperCase() : '?';
  }

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      String userId = _studentId;
      if (userId.isEmpty) {
        final children = await ApiService().getMyChildren();
        if (children.isNotEmpty) {
          final s = children[0]['student'] as Map<String, dynamic>?;
          userId =
              s?['id'] as String? ?? children[0]['studentId'] as String? ?? '';
        }
      }
      if (userId.isEmpty) {
        setState(() => _loading = false);
        return;
      }

      // Fire all 3 requests in parallel
      final results = await Future.wait([
        ApiService().getStudentDetail(userId),
        ApiService().getStudentReport(userId, periodType: 'monthly'),
        ApiService().getStudentTeachers(userId),
      ]);

      if (!mounted) return;

      final teachersData = results[2]['teachers'] as List<dynamic>? ?? [];

      setState(() {
        _detail = results[0];
        _report = results[1];
        _teachers = teachersData.cast<Map<String, dynamic>>();
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
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: AppColors.textPrimary,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.childName,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _buildError()
          : RefreshIndicator(
              onRefresh: _loadAll,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProfileCard(),
                    const SizedBox(height: 16),
                    _buildSummaryRow(),
                    const SizedBox(height: 20),
                    _buildSectionLabel('Subjects & Results'),
                    const SizedBox(height: 10),
                    _buildSubjectsList(),
                    const SizedBox(height: 20),
                    _buildSectionLabel('Teachers'),
                    const SizedBox(height: 10),
                    _buildTeachersList(),
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
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadAll,
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

  Widget _buildProfileCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
            child: Text(
              _initials,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _studentName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                if (_gradeSection.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _gradeSection,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  (_detail['student'] as Map<String, dynamic>?)?['email']
                          as String? ??
                      '',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow() {
    final summary = _report['summary'] as Map<String, dynamic>? ?? {};
    final attendancePct = summary['overallAttendancePercent'] as num?;
    final avgPct = summary['overallSubjectsAveragePercent'] as num?;
    final courses = (_report['courses'] as List<dynamic>?)?.length ?? 0;

    return Row(
      children: [
        _buildStatCard(
          icon: Icons.event_available_outlined,
          color: AppColors.secondary,
          label: 'Attendance',
          value: attendancePct != null
              ? '${attendancePct.toStringAsFixed(0)}%'
              : '--',
        ),
        const SizedBox(width: 10),
        _buildStatCard(
          icon: Icons.grade_outlined,
          color: AppColors.primary,
          label: 'Avg Score',
          value: avgPct != null ? '${avgPct.toStringAsFixed(0)}%' : '--',
        ),
        const SizedBox(width: 10),
        _buildStatCard(
          icon: Icons.menu_book_outlined,
          color: const Color(0xFF7C4DFF),
          label: 'Subjects',
          value: '$courses',
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildSubjectsList() {
    final courses = (_report['courses'] as List<dynamic>?) ?? [];

    if (courses.isEmpty) {
      return _buildEmptyState(
        Icons.menu_book_outlined,
        'No subject data available',
      );
    }

    final subjectColors = [
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
        final attendance = course['attendance'] as Map<String, dynamic>? ?? {};
        final totals = attendance['totals'] as Map<String, dynamic>? ?? {};

        final subjectName = subject['name'] as String? ?? 'Unknown';
        final teacherName =
            '${teacher['firstName'] ?? ''} ${teacher['lastName'] ?? ''}'.trim();
        final avgPct = assessments['averagePercent'] as num?;
        final releasedCount = assessments['releasedCount'] as int? ?? 0;
        final attendancePct = totals['attendancePercent'] as num?;
        final color = subjectColors[i % subjectColors.length];
        final teacherId = teacher['id'] as String?;

        return _SubjectCard(
          subjectName: subjectName,
          teacherName: teacherName,
          teacherId: teacherId,
          avgPercent: avgPct,
          releasedCount: releasedCount,
          attendancePercent: attendancePct,
          color: color,
          exams: (assessments['details'] as List<dynamic>? ?? [])
              .cast<Map<String, dynamic>>(),
          onMessageTeacher: teacherId != null
              ? () => _openTeacherChat(
                  teacherId: teacherId,
                  teacherName: teacherName,
                  subject: subjectName,
                )
              : null,
        );
      }).toList(),
    );
  }

  Widget _buildTeachersList() {
    if (_teachers.isEmpty) {
      return _buildEmptyState(Icons.person_outline, 'No teachers found');
    }

    final colors = [
      AppColors.primary,
      AppColors.secondary,
      const Color(0xFF7C4DFF),
      const Color(0xFFFF6D00),
      const Color(0xFF00BFA5),
    ];

    return Column(
      children: _teachers.asMap().entries.map((entry) {
        final i = entry.key;
        final t = entry.value;
        final firstName = t['firstName'] as String? ?? '';
        final lastName = t['lastName'] as String? ?? '';
        final fullName = '$firstName $lastName'.trim();
        final initials =
            '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}'
                .toUpperCase();
        final subjects = (t['subjects'] as List<dynamic>? ?? [])
            .map((s) => s.toString())
            .toList();
        final department = t['department'] as String? ?? '';
        final color = colors[i % colors.length];
        final teacherId = t['id'] as String? ?? '';

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: color.withValues(alpha: 0.12),
                child: Text(
                  initials,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: color,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fullName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    if (subjects.isNotEmpty)
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: subjects
                            .map(
                              (s) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  s,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: color,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    if (department.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        department,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _openTeacherChat(
                  teacherId: teacherId,
                  teacherName: fullName,
                  subject: subjects.isNotEmpty ? subjects.first : '',
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.send_rounded, color: Colors.white, size: 14),
                      SizedBox(width: 4),
                      Text(
                        'Message',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmptyState(IconData icon, String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, size: 36, color: Colors.grey.shade300),
          const SizedBox(height: 10),
          Text(
            message,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Future<void> _openTeacherChat({
    required String teacherId,
    required String teacherName,
    required String subject,
  }) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final response = await ApiService().initiateConversation(teacherId);
      final conversation = response['conversation'] as Map<String, dynamic>;
      final conversationId = conversation['id'] as String;

      if (!mounted) return;
      Navigator.pop(context); // close loader

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ParentMessageViewScreen(
            conversationId: conversationId,
            teacherName: teacherName,
            subject: subject,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open chat: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

// ─── Subject Card ────────────────────────────────────────

class _SubjectCard extends StatefulWidget {
  final String subjectName;
  final String teacherName;
  final String? teacherId;
  final num? avgPercent;
  final int releasedCount;
  final num? attendancePercent;
  final Color color;
  final List<Map<String, dynamic>> exams;
  final VoidCallback? onMessageTeacher;

  const _SubjectCard({
    required this.subjectName,
    required this.teacherName,
    this.teacherId,
    this.avgPercent,
    required this.releasedCount,
    this.attendancePercent,
    required this.color,
    required this.exams,
    this.onMessageTeacher,
  });

  @override
  State<_SubjectCard> createState() => _SubjectCardState();
}

class _SubjectCardState extends State<_SubjectCard> {
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
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header row
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
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.teacherName,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Score badge
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
                          color: Colors.grey.shade400,
                        ),
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

          // Expanded details
          if (_expanded) ...[
            Divider(height: 1, color: Colors.grey.shade100),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Attendance row
                  if (widget.attendancePercent != null)
                    _buildInfoRow(
                      Icons.event_available_outlined,
                      'Attendance',
                      '${widget.attendancePercent!.toStringAsFixed(0)}%',
                      AppColors.secondary,
                    ),
                  const SizedBox(height: 10),

                  // Exam results
                  if (widget.exams.isNotEmpty) ...[
                    Text(
                      'Recent Exams',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...widget.exams.take(5).map((exam) {
                      final title = exam['examTitle'] as String? ?? 'Exam';
                      final score = exam['score'] as num?;
                      final maxPoints = exam['maxPoints'] as num? ?? 100;
                      final pct = score != null
                          ? (score / maxPoints * 100)
                          : null;
                      final scoreColor = pct == null
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
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textPrimary,
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
                                color: scoreColor,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ] else
                    Text(
                      'No exams released yet',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade400,
                      ),
                    ),

                  // Message teacher button
                  if (widget.onMessageTeacher != null) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: widget.onMessageTeacher,
                        icon: const Icon(Icons.send_rounded, size: 14),
                        label: Text('Message ${widget.teacherName}'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(
                            color: AppColors.primary,
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          textStyle: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
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
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
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
