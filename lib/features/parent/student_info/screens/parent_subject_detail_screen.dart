import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/api_service.dart';
import '../../../shared/widgets/role_page_background.dart';

class ParentSubjectDetailScreen extends StatefulWidget {
  final String studentId;
  final String subjectId;
  final String subjectName;
  final String childName;

  const ParentSubjectDetailScreen({
    super.key,
    required this.studentId,
    required this.subjectId,
    required this.subjectName,
    this.childName = '',
  });

  @override
  State<ParentSubjectDetailScreen> createState() =>
      _ParentSubjectDetailScreenState();
}

class _ParentSubjectDetailScreenState extends State<ParentSubjectDetailScreen>
    with SingleTickerProviderStateMixin {
  bool _loadingGrades = true;
  bool _loadingAttendance = true;
  String? _gradesError;
  String? _attendanceError;

  Map<String, dynamic>? _gradesData;
  Map<String, dynamic>? _attendanceData;

  late TabController _tabController;

  // Filters
  String _gradeTypeFilter = 'all'; // all | exam | quiz | assignment
  String _attendanceStatusFilter = 'all'; // all | present | absent | late | excused

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
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new,
              color: theme.colorScheme.onSurface, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.subjectName,
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
            if (widget.childName.isNotEmpty)
              Text(
                widget.childName,
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                ),
              ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
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
      body: RolePageBackground(
        flavor: RoleThemeFlavor.parent,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildGradesTab(),
            _buildAttendanceTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildGradesTab() {
    if (_loadingGrades) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_gradesError != null) {
      return _buildError(_gradesError!, _loadGrades);
    }

    final summary = _gradesData?['summary'] as Map<String, dynamic>? ?? {};
    final allEntries =
        (_gradesData?['entries'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();

    // Apply type filter
    final entries = _gradeTypeFilter == 'all'
        ? allEntries
        : allEntries.where((e) =>
            (e['type'] as String? ?? '').toLowerCase() == _gradeTypeFilter).toList();

    final total = summary['total'] as int? ?? 0;
    final withScore = summary['withScore'] as int? ?? 0;
    final avgPercent = summary['averagePercent'] as num? ?? 0;

    // Count per type for filter badges
    final examCount = allEntries.where((e) => (e['type'] as String? ?? '').toLowerCase() == 'exam').length;
    final quizCount = allEntries.where((e) => (e['type'] as String? ?? '').toLowerCase() == 'quiz').length;
    final assignCount = allEntries.where((e) => (e['type'] as String? ?? '').toLowerCase() == 'assignment').length;

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
            // Grade type filter
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('All', 'all', _gradeTypeFilter, allEntries.length,
                      AppColors.primary, () => setState(() => _gradeTypeFilter = 'all')),
                  const SizedBox(width: 8),
                  _buildFilterChip('Exams', 'exam', _gradeTypeFilter, examCount,
                      AppColors.error, () => setState(() => _gradeTypeFilter = 'exam')),
                  const SizedBox(width: 8),
                  _buildFilterChip('Quizzes', 'quiz', _gradeTypeFilter, quizCount,
                      AppColors.warning, () => setState(() => _gradeTypeFilter = 'quiz')),
                  const SizedBox(width: 8),
                  _buildFilterChip('Assignments', 'assignment', _gradeTypeFilter, assignCount,
                      AppColors.primary, () => setState(() => _gradeTypeFilter = 'assignment')),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'GRADE ENTRIES',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 12),
            if (entries.isEmpty)
              _buildEmptyState(
                Icons.grade_outlined,
                'No grades yet',
                _gradeTypeFilter == 'all'
                    ? 'Grades will appear here once released'
                    : 'No ${_gradeTypeFilter}s found',
              )
            else
              ...entries.map((entry) => _buildGradeCard(entry)),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceTab() {
    if (_loadingAttendance) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_attendanceError != null) {
      return _buildError(_attendanceError!, _loadAttendance);
    }

    final summary = _attendanceData?['summary'] as Map<String, dynamic>? ?? {};
    final allSessions =
        (_attendanceData?['sessions'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();

    // Apply status filter
    final sessions = _attendanceStatusFilter == 'all'
        ? allSessions
        : allSessions.where((s) =>
            (s['status'] as String? ?? '').toLowerCase() == _attendanceStatusFilter).toList();

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
              totalSessions, present, absent, late, excused, attendancePercent,
            ),
            const SizedBox(height: 16),
            // Attendance status filter
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('All', 'all', _attendanceStatusFilter, allSessions.length,
                      AppColors.secondary, () => setState(() => _attendanceStatusFilter = 'all')),
                  const SizedBox(width: 8),
                  _buildFilterChip('Present', 'present', _attendanceStatusFilter, present,
                      Colors.green, () => setState(() => _attendanceStatusFilter = 'present')),
                  const SizedBox(width: 8),
                  _buildFilterChip('Absent', 'absent', _attendanceStatusFilter, absent,
                      AppColors.error, () => setState(() => _attendanceStatusFilter = 'absent')),
                  const SizedBox(width: 8),
                  _buildFilterChip('Late', 'late', _attendanceStatusFilter, late,
                      Colors.orange, () => setState(() => _attendanceStatusFilter = 'late')),
                  const SizedBox(width: 8),
                  _buildFilterChip('Excused', 'excused', _attendanceStatusFilter, excused,
                      Colors.blue, () => setState(() => _attendanceStatusFilter = 'excused')),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'ATTENDANCE RECORDS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 12),
            if (sessions.isEmpty)
              _buildEmptyState(
                Icons.event_available_outlined,
                'No attendance records',
                _attendanceStatusFilter == 'all'
                    ? 'Attendance records will appear here'
                    : 'No ${_attendanceStatusFilter} records found',
              )
            else
              ...sessions.map((session) => _buildAttendanceCard(session)),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    String value,
    String current,
    int count,
    Color color,
    VoidCallback onTap,
  ) {
    final selected = current == value;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.12) : Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected ? color : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: selected ? color : Theme.of(context).colorScheme.onSurfaceVariant,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
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
                Text(
                  'Average',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${avgPercent.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$withScore of $total graded',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 13,
                  ),
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

  Widget _buildAttendanceSummaryCard(
    int totalSessions,
    int present,
    int absent,
    int late,
    int excused,
    num attendancePercent,
  ) {
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
            offset: const Offset(0, 4),
          ),
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
                    Text(
                      'Attendance Rate',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${attendancePercent.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$present of $totalSessions sessions',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 13,
                      ),
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
              _buildAttendanceStat('Present', present, Icons.check_circle),
              _buildAttendanceStat('Absent', absent, Icons.cancel),
              _buildAttendanceStat('Late', late, Icons.access_time),
              _buildAttendanceStat('Excused', excused, Icons.event_busy),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceStat(String label, int count, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white.withValues(alpha: 0.9), size: 20),
        const SizedBox(height: 4),
        Text(
          '$count',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 11,
          ),
        ),
      ],
    );
  }



  Widget _buildGradeCard(Map<String, dynamic> entry) {
    final title = entry['title'] as String? ?? 'Untitled';
    final type = entry['type'] as String? ?? 'assignment';
    final score = entry['score'] as num? ?? 0;
    final maxScore = entry['maxScore'] as num? ?? 100;
    final note = entry['note'] as String?;
    final percent = maxScore > 0 ? (score / maxScore * 100) : 0;

    Color typeColor;
    IconData typeIcon;
    switch (type.toLowerCase()) {
      case 'exam':
        typeColor = AppColors.error;
        typeIcon = Icons.assignment;
        break;
      case 'quiz':
        typeColor = AppColors.warning;
        typeIcon = Icons.quiz;
        break;
      case 'assignment':
        typeColor = AppColors.primary;
        typeIcon = Icons.assignment_turned_in;
        break;
      default:
        typeColor = AppColors.accent;
        typeIcon = Icons.grade;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
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
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      type[0].toUpperCase() + type.substring(1),
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$score / $maxScore',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    '${percent.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (note != null && note.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.note_outlined,
                      size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      note,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
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

  Widget _buildAttendanceCard(Map<String, dynamic> session) {
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
        statusColor = AppColors.warning;
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
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
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
                child: Icon(statusIcon, color: statusColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatDate(date),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 13,
                        color: statusColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
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
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          if (note != null && note.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.note_outlined,
                      size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      note,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
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



  Widget _buildError(String error, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              'Failed to load data',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
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

  Widget _buildEmptyState(IconData icon, String title, String subtitle) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(icon, size: 64, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      final d = DateTime.parse(iso);
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ];
      return '${months[d.month - 1]} ${d.day}, ${d.year}';
    } catch (_) {
      return iso;
    }
  }
}
