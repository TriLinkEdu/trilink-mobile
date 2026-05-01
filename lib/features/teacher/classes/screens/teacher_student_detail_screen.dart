import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/api_service.dart';

class TeacherStudentDetailScreen extends StatefulWidget {
  final String studentId;
  final String studentName;
  final String subjectId;
  final String subjectName;

  const TeacherStudentDetailScreen({
    super.key,
    required this.studentId,
    required this.studentName,
    required this.subjectId,
    required this.subjectName,
  });

  @override
  State<TeacherStudentDetailScreen> createState() =>
      _TeacherStudentDetailScreenState();
}

class _TeacherStudentDetailScreenState
    extends State<TeacherStudentDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool _loadingGrades = true;
  bool _loadingAttendance = true;
  String? _gradesError;
  String? _attendanceError;

  Map<String, dynamic>? _gradesData;
  Map<String, dynamic>? _attendanceData;

  String _gradeTypeFilter = 'all';
  String _attendanceStatusFilter = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadGrades();
    _loadAttendance();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadGrades() async {
    setState(() {
      _loadingGrades = true;
      _gradesError = null;
    });
    try {
      final data = await ApiService().getGradesBySubject(
        widget.studentId,
        widget.subjectId,
      );
      if (!mounted) return;
      setState(() {
        _gradesData = data;
        _loadingGrades = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _gradesError = e.toString();
        _loadingGrades = false;
      });
    }
  }

  Future<void> _loadAttendance() async {
    setState(() {
      _loadingAttendance = true;
      _attendanceError = null;
    });
    try {
      final data = await ApiService().getAttendanceBySubject(
        widget.studentId,
        widget.subjectId,
      );
      if (!mounted) return;
      setState(() {
        _attendanceData = data;
        _loadingAttendance = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _attendanceError = e.toString();
        _loadingAttendance = false;
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
          icon: const Icon(Icons.arrow_back_ios_new,
              color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.studentName,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
            Text(
              widget.subjectName,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey.shade600,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          tabs: const [
            Tab(text: 'Grades'),
            Tab(text: 'Attendance'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildGradesTab(),
          _buildAttendanceTab(),
        ],
      ),
    );
  }

  // ─── Grades Tab ────────────────────────────────────────────────────────────

  Widget _buildGradesTab() {
    if (_loadingGrades) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_gradesError != null) {
      return _buildError(_gradesError!, _loadGrades);
    }

    final summary = _gradesData?['summary'] as Map<String, dynamic>? ?? {};
    final allEntries = (_gradesData?['entries'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();

    final entries = _gradeTypeFilter == 'all'
        ? allEntries
        : allEntries
            .where((e) =>
                (e['type'] as String? ?? '').toLowerCase() == _gradeTypeFilter)
            .toList();

    final total = summary['total'] as int? ?? 0;
    final withScore = summary['withScore'] as int? ?? 0;
    final avgPercent = summary['averagePercent'] as num? ?? 0;

    final examCount = allEntries
        .where((e) => (e['type'] as String? ?? '').toLowerCase() == 'exam')
        .length;
    final quizCount = allEntries
        .where((e) => (e['type'] as String? ?? '').toLowerCase() == 'quiz')
        .length;
    final assignCount = allEntries
        .where(
            (e) => (e['type'] as String? ?? '').toLowerCase() == 'assignment')
        .length;

    return RefreshIndicator(
      onRefresh: _loadGrades,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGradesSummaryCard(total, withScore, avgPercent),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _filterChip('All', 'all', _gradeTypeFilter, allEntries.length,
                      AppColors.primary,
                      () => setState(() => _gradeTypeFilter = 'all')),
                  const SizedBox(width: 8),
                  _filterChip('Exams', 'exam', _gradeTypeFilter, examCount,
                      AppColors.error,
                      () => setState(() => _gradeTypeFilter = 'exam')),
                  const SizedBox(width: 8),
                  _filterChip('Quizzes', 'quiz', _gradeTypeFilter, quizCount,
                      Colors.orange,
                      () => setState(() => _gradeTypeFilter = 'quiz')),
                  const SizedBox(width: 8),
                  _filterChip('Assignments', 'assignment', _gradeTypeFilter,
                      assignCount, AppColors.primary,
                      () => setState(() => _gradeTypeFilter = 'assignment')),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _sectionLabel('GRADE ENTRIES'),
            const SizedBox(height: 12),
            if (entries.isEmpty)
              _emptyState(
                Icons.grade_outlined,
                'No grades yet',
                _gradeTypeFilter == 'all'
                    ? 'Grades will appear here once released'
                    : 'No ${_gradeTypeFilter}s found',
              )
            else
              ...entries.map((e) => _gradeCard(e)),
          ],
        ),
      ),
    );
  }

  Widget _buildGradesSummaryCard(int total, int withScore, num avgPercent) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Average',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 14)),
                const SizedBox(height: 8),
                Text(
                  '${avgPercent.toStringAsFixed(1)}%',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  '$withScore of $total graded',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8), fontSize: 13),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.grade, color: Colors.white, size: 32),
          ),
        ],
      ),
    );
  }

  Widget _gradeCard(Map<String, dynamic> entry) {
    final title = entry['title'] as String? ?? 'Untitled';
    final type = entry['type'] as String? ?? 'assignment';
    final score = entry['score'] as num?;
    final maxScore = entry['maxScore'] as num? ?? 100;
    final note = entry['note'] as String?;
    final releasedAt = entry['releasedAt'] as String?;
    final percent = (score != null && maxScore > 0)
        ? (score / maxScore * 100)
        : null;

    Color typeColor;
    IconData typeIcon;
    switch (type.toLowerCase()) {
      case 'exam':
        typeColor = AppColors.error;
        typeIcon = Icons.assignment;
        break;
      case 'quiz':
        typeColor = Colors.orange;
        typeIcon = Icons.quiz;
        break;
      default:
        typeColor = AppColors.primary;
        typeIcon = Icons.assignment_turned_in;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(typeIcon, color: typeColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary)),
                    Text(
                      type[0].toUpperCase() + type.substring(1),
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    score != null ? '$score / $maxScore' : '— / $maxScore',
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary),
                  ),
                  if (percent != null)
                    Text(
                      '${percent.toStringAsFixed(1)}%',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade600),
                    ),
                  if (releasedAt == null)
                    Text(
                      'Not released',
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.orange.shade600,
                          fontStyle: FontStyle.italic),
                    ),
                ],
              ),
            ],
          ),
          if (note != null && note.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.note_outlined,
                      size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(note,
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade700)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Attendance Tab ────────────────────────────────────────────────────────

  Widget _buildAttendanceTab() {
    if (_loadingAttendance) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_attendanceError != null) {
      return _buildError(_attendanceError!, _loadAttendance);
    }

    final summary =
        _attendanceData?['summary'] as Map<String, dynamic>? ?? {};
    final allSessions =
        (_attendanceData?['sessions'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>();

    final sessions = _attendanceStatusFilter == 'all'
        ? allSessions
        : allSessions
            .where((s) =>
                (s['status'] as String? ?? '').toLowerCase() ==
                _attendanceStatusFilter)
            .toList();

    final totalSessions = summary['total'] as int? ?? 0;
    final present = summary['present'] as int? ?? 0;
    final absent = summary['absent'] as int? ?? 0;
    final late = summary['late'] as int? ?? 0;
    final excused = summary['excused'] as int? ?? 0;
    final attendancePercent = summary['attendanceRate'] as num? ?? 0;

    return RefreshIndicator(
      onRefresh: _loadAttendance,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAttendanceSummaryCard(
                totalSessions, present, absent, late, excused,
                attendancePercent),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _filterChip('All', 'all', _attendanceStatusFilter,
                      allSessions.length, AppColors.secondary,
                      () => setState(() => _attendanceStatusFilter = 'all')),
                  const SizedBox(width: 8),
                  _filterChip('Present', 'present', _attendanceStatusFilter,
                      present, Colors.green,
                      () => setState(
                          () => _attendanceStatusFilter = 'present')),
                  const SizedBox(width: 8),
                  _filterChip('Absent', 'absent', _attendanceStatusFilter,
                      absent, AppColors.error,
                      () => setState(
                          () => _attendanceStatusFilter = 'absent')),
                  const SizedBox(width: 8),
                  _filterChip('Late', 'late', _attendanceStatusFilter, late,
                      Colors.orange,
                      () =>
                          setState(() => _attendanceStatusFilter = 'late')),
                  const SizedBox(width: 8),
                  _filterChip('Excused', 'excused', _attendanceStatusFilter,
                      excused, Colors.blue,
                      () => setState(
                          () => _attendanceStatusFilter = 'excused')),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _sectionLabel('ATTENDANCE RECORDS'),
            const SizedBox(height: 12),
            if (sessions.isEmpty)
              _emptyState(
                Icons.event_available_outlined,
                'No attendance records',
                _attendanceStatusFilter == 'all'
                    ? 'Attendance records will appear here'
                    : 'No ${_attendanceStatusFilter} records found',
              )
            else
              ...sessions.map((s) => _attendanceCard(s)),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceSummaryCard(int total, int present, int absent,
      int late, int excused, num attendancePercent) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.secondary,
            AppColors.secondary.withValues(alpha: 0.8)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: AppColors.secondary.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Attendance Rate',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 14)),
                    const SizedBox(height: 8),
                    Text(
                      '${attendancePercent.toStringAsFixed(1)}%',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$present of $total sessions',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 13),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.event_available,
                    color: Colors.white, size: 32),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.white.withValues(alpha: 0.3), height: 1),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _attStat('Present', present, Icons.check_circle),
              _attStat('Absent', absent, Icons.cancel),
              _attStat('Late', late, Icons.access_time),
              _attStat('Excused', excused, Icons.event_busy),
            ],
          ),
        ],
      ),
    );
  }

  Widget _attStat(String label, int count, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white.withValues(alpha: 0.9), size: 20),
        const SizedBox(height: 4),
        Text('$count',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
        Text(label,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8), fontSize: 11)),
      ],
    );
  }

  Widget _attendanceCard(Map<String, dynamic> session) {
    final date = session['date'] as String? ?? '';
    final status = session['status'] as String? ?? 'unknown';
    final note = session['note'] as String?;

    Color statusColor;
    IconData statusIcon;
    String statusLabel;
    switch (status.toLowerCase()) {
      case 'present':
        statusColor = AppColors.success;
        statusIcon = Icons.check_circle;
        statusLabel = 'Present';
        break;
      case 'absent':
        statusColor = AppColors.error;
        statusIcon = Icons.cancel;
        statusLabel = 'Absent';
        break;
      case 'late':
        statusColor = Colors.orange;
        statusIcon = Icons.access_time;
        statusLabel = 'Late';
        break;
      case 'excused':
        statusColor = Colors.blue;
        statusIcon = Icons.event_busy;
        statusLabel = 'Excused';
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline;
        statusLabel = 'Unknown';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: statusColor.withValues(alpha: 0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(statusIcon, color: statusColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_formatDate(date),
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary)),
                    Text(statusLabel,
                        style: TextStyle(
                            fontSize: 13,
                            color: statusColor,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusLabel.toUpperCase(),
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                      letterSpacing: 0.5),
                ),
              ),
            ],
          ),
          if (note != null && note.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.note_outlined,
                      size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(note,
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade700)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Shared helpers ────────────────────────────────────────────────────────

  Widget _filterChip(String label, String value, String current, int count,
      Color color, VoidCallback onTap) {
    final selected = current == value;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.12)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? color : Colors.transparent, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.w500,
                color: selected ? color : Colors.grey.shade600,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 5),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: selected ? color : Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('$count',
                    style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Colors.grey.shade500,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildError(String error, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('Failed to load data',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700)),
            const SizedBox(height: 8),
            Text(error,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 13, color: Colors.grey.shade500)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
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

  Widget _emptyState(IconData icon, String title, String subtitle) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(icon, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(title,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600)),
          const SizedBox(height: 8),
          Text(subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13, color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      final d = DateTime.parse(iso);
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${months[d.month - 1]} ${d.day}, ${d.year}';
    } catch (_) {
      return iso;
    }
  }
}
