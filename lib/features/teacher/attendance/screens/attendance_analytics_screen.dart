import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/api_service.dart';

class AttendanceAnalyticsScreen extends StatefulWidget {
  const AttendanceAnalyticsScreen({super.key});

  @override
  State<AttendanceAnalyticsScreen> createState() =>
      _AttendanceAnalyticsScreenState();
}

class _AttendanceAnalyticsScreenState extends State<AttendanceAnalyticsScreen> {
  bool _loadingClasses = true;
  bool _loadingReport = false;
  String? _error;

  List<Map<String, dynamic>> _classOfferings = [];
  String? _selectedClassId;

  double _averageAttendance = 0;
  int _totalAbsences = 0;
  int _lateArrivals = 0;
  int _totalSessions = 0;
  int _totalStudents = 0;
  int _presentCount = 0;
  int _excusedCount = 0;
  List<_WeekData> _weeklyData = [];
  List<_AbsentStudent> _mostAbsent = [];
  List<_AbsentStudent> _mostLate = [];
  List<_AbsentStudent> _atRiskStudents = [];
  List<_DayAttendance> _dailyBreakdown = [];
  String? _worstDay;
  String? _bestDay;
  String? _className;

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    try {
      setState(() {
        _loadingClasses = true;
        _error = null;
      });

      final yearData = await ApiService().getActiveAcademicYear();
      final yearId = (yearData['id'] ?? yearData['data']?['id']) as String?;
      if (yearId == null) {
        throw Exception('No active academic year found');
      }
      final offerings = await ApiService().getMyClassOfferings(yearId);

      if (!mounted) return;
      setState(() {
        _classOfferings = offerings.cast<Map<String, dynamic>>();
        _loadingClasses = false;
        if (_classOfferings.isNotEmpty) {
          _selectedClassId = _classOfferings.first['id'] as String?;
          _loadReport();
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loadingClasses = false;
      });
    }
  }

  Future<void> _loadReport() async {
    if (_selectedClassId == null) return;
    try {
      setState(() {
        _loadingReport = true;
        _error = null;
      });

      final report = await ApiService().getClassAttendanceReport(
        _selectedClassId!,
      );

      if (!mounted) return;

      // Try to derive insights from real backend shape (sessions[].marks[])
      final sessions = report['sessions'] as List<dynamic>?;
      if (sessions != null && sessions.isNotEmpty) {
        _deriveFromSessions(report, sessions);
      } else {
        // Fallback to flat dummy/legacy shape
        _averageAttendance =
            (report['averageAttendance'] as num?)?.toDouble() ?? 0;
        _totalAbsences = (report['totalAbsences'] as num?)?.toInt() ?? 0;
        _lateArrivals = (report['lateArrivals'] as num?)?.toInt() ?? 0;
        _className = report['className'] as String?;

        final weekly = report['weeklyTrends'] as List<dynamic>? ?? [];
        _weeklyData = weekly.map((w) {
          final m = w as Map<String, dynamic>;
          return _WeekData(
            label: m['label']?.toString() ?? '',
            percentage: (m['percentage'] as num?)?.toDouble() ?? 0,
          );
        }).toList();

        final absent = report['mostAbsent'] as List<dynamic>? ?? [];
        _mostAbsent = absent.map((a) {
          final m = a as Map<String, dynamic>;
          return _AbsentStudent(
            name: m['name']?.toString() ?? 'Unknown',
            absences: (m['absences'] as num?)?.toInt() ?? 0,
            totalDays: (m['totalDays'] as num?)?.toInt() ?? 1,
          );
        }).toList();

        final daily = report['dailyBreakdown'] as List<dynamic>? ?? [];
        _dailyBreakdown = daily.map((d) {
          final m = d as Map<String, dynamic>;
          return _DayAttendance(
            day: m['day']?.toString() ?? '',
            percentage: (m['percentage'] as num?)?.toInt() ?? 0,
          );
        }).toList();
      }

      setState(() {
        _loadingReport = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loadingReport = false;
      });
    }
  }

  void _deriveFromSessions(
    Map<String, dynamic> report,
    List<dynamic> sessions,
  ) {
    _className = report['className'] as String?;
    _totalSessions = sessions.length;

    int present = 0;
    int late = 0;
    int absent = 0;
    int excused = 0;

    final perStudent = <String, _StudentAgg>{};
    final perDayOfWeek = <int, _DayAgg>{};
    final weeklyMap = <String, _WeekAgg>{};

    for (final s in sessions) {
      final session = s as Map<String, dynamic>;
      final dateRaw = session['date'] as String?;
      final dt = dateRaw != null ? DateTime.tryParse(dateRaw) : null;

      final marks = session['marks'] as List<dynamic>? ?? [];
      for (final m in marks) {
        final mark = m as Map<String, dynamic>;
        final status = (mark['status'] as String? ?? '').toLowerCase();
        final studentId = (mark['studentId'] ?? mark['studentUserId']) as String?;
        final firstName = (mark['studentFirstName'] ?? mark['firstName']) ?? '';
        final lastName = (mark['studentLastName'] ?? mark['lastName']) ?? '';
        final fullName = '$firstName $lastName'.trim().isEmpty
            ? (mark['name'] as String? ?? 'Student')
            : '$firstName $lastName'.trim();

        if (status == 'present') present++;
        if (status == 'late') late++;
        if (status == 'absent') absent++;
        if (status == 'excused') excused++;

        final key = studentId ?? fullName;
        final agg = perStudent.putIfAbsent(key, () => _StudentAgg(name: fullName));
        agg.total++;
        if (status == 'present') agg.present++;
        if (status == 'late') agg.late++;
        if (status == 'absent') agg.absent++;
        if (status == 'excused') agg.excused++;

        if (dt != null) {
          final dow = dt.weekday;
          final ds = perDayOfWeek.putIfAbsent(dow, () => _DayAgg(weekday: dow));
          ds.total++;
          if (status == 'present' || status == 'late') ds.attended++;

          final weekStart = dt.subtract(Duration(days: dt.weekday - 1));
          final wkKey =
              '${weekStart.year}-${weekStart.month.toString().padLeft(2, '0')}-${weekStart.day.toString().padLeft(2, '0')}';
          final w = weeklyMap.putIfAbsent(
              wkKey,
              () => _WeekAgg(
                    label:
                        'Wk ${weekStart.month}/${weekStart.day}',
                  ));
          w.total++;
          if (status == 'present' || status == 'late') w.attended++;
        }
      }
    }

    final totalMarks = present + late + absent + excused;
    _presentCount = present;
    _lateArrivals = late;
    _totalAbsences = absent;
    _excusedCount = excused;
    _totalStudents = perStudent.length;
    _averageAttendance =
        totalMarks > 0 ? ((present + late) / totalMarks) * 100 : 0;

    // Most absent (top 5 sorted desc)
    final byAbsent = perStudent.values.toList()
      ..sort((a, b) => b.absent.compareTo(a.absent));
    _mostAbsent = byAbsent
        .where((a) => a.absent > 0)
        .take(5)
        .map((a) => _AbsentStudent(
              name: a.name,
              absences: a.absent,
              totalDays: a.total,
            ))
        .toList();

    // Most late
    final byLate = perStudent.values.toList()
      ..sort((a, b) => b.late.compareTo(a.late));
    _mostLate = byLate
        .where((a) => a.late > 0)
        .take(5)
        .map((a) => _AbsentStudent(
              name: a.name,
              absences: a.late,
              totalDays: a.total,
            ))
        .toList();

    // At-risk (<75% attendance)
    final atRisk = perStudent.values.where((a) {
      if (a.total == 0) return false;
      final rate = (a.present + a.late) / a.total;
      return rate < 0.75;
    }).toList()
      ..sort((a, b) {
        final ra = (a.present + a.late) / a.total;
        final rb = (b.present + b.late) / b.total;
        return ra.compareTo(rb);
      });
    _atRiskStudents = atRisk
        .take(8)
        .map((a) => _AbsentStudent(
              name: a.name,
              absences: a.absent,
              totalDays: a.total,
            ))
        .toList();

    // Day-of-week breakdown
    const dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    _dailyBreakdown = [];
    String? worstDay;
    String? bestDay;
    double worstRate = 200;
    double bestRate = -1;
    for (var i = 1; i <= 7; i++) {
      final agg = perDayOfWeek[i];
      if (agg == null) continue;
      final pct = agg.total > 0 ? (agg.attended / agg.total) * 100 : 0.0;
      _dailyBreakdown.add(_DayAttendance(day: dayLabels[i - 1], percentage: pct.round()));
      if (pct < worstRate) {
        worstRate = pct;
        worstDay = dayLabels[i - 1];
      }
      if (pct > bestRate) {
        bestRate = pct;
        bestDay = dayLabels[i - 1];
      }
    }
    _worstDay = worstDay;
    _bestDay = bestDay;

    // Weekly trends (last 6)
    final weekKeys = weeklyMap.keys.toList()..sort();
    final lastWeeks = weekKeys.length > 6
        ? weekKeys.sublist(weekKeys.length - 6)
        : weekKeys;
    _weeklyData = lastWeeks.map((k) {
      final w = weeklyMap[k]!;
      final pct = w.total > 0 ? (w.attended / w.total) * 100 : 0.0;
      return _WeekData(label: w.label, percentage: pct);
    }).toList();
  }

  String _labelFor(Map<String, dynamic> offering) {
    final subject = offering['subject'];
    final grade = offering['grade'];
    final section = offering['section'];
    final subjectName = subject is Map ? (subject['name'] ?? '') : '';
    final gradeName = grade is Map ? (grade['name'] ?? '') : '';
    final sectionName = section is Map ? (section['name'] ?? '') : '';
    return '$subjectName $gradeName$sectionName'.trim();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        title: Text(
          'Attendance Analytics',
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    final theme = Theme.of(context);
    if (_loadingClasses) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _classOfferings.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(height: 16),
              Text(
                'Failed to load data',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error ?? '',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _loadClasses,
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

    if (_classOfferings.isEmpty) {
      return Center(
        child: Text(
          'No classes found.',
          style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurfaceVariant),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildClassDropdown(),
          const SizedBox(height: 20),
          if (_loadingReport)
            const Padding(
              padding: EdgeInsets.only(top: 80),
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            _buildSummaryHeader(),
            const SizedBox(height: 16),
            _buildOverviewCards(),
            const SizedBox(height: 16),
            _buildStatusBreakdown(),
            const SizedBox(height: 24),
            _buildInsightsCard(),
            const SizedBox(height: 24),
            if (_weeklyData.isNotEmpty) ...[
              _buildTrendsSection(),
              const SizedBox(height: 24),
            ],
            if (_mostAbsent.isNotEmpty) ...[
              _buildMostAbsentSection(),
              const SizedBox(height: 24),
            ],
            if (_mostLate.isNotEmpty) ...[
              _buildMostLateSection(),
              const SizedBox(height: 24),
            ],
            if (_atRiskStudents.isNotEmpty) ...[
              _buildAtRiskSection(),
              const SizedBox(height: 24),
            ],
            if (_dailyBreakdown.isNotEmpty) ...[
              _buildDailyBreakdownSection(),
              const SizedBox(height: 32),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildClassDropdown() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedClassId,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
          items: _classOfferings.map((c) {
            final id = c['id'] as String;
            return DropdownMenuItem(value: id, child: Text(_labelFor(c)));
          }).toList(),
          onChanged: (val) {
            if (val != null && val != _selectedClassId) {
              setState(() => _selectedClassId = val);
              _loadReport();
            }
          },
        ),
      ),
    );
  }

  Widget _buildOverviewCards() {
    return Row(
      children: [
        Expanded(
          child: _OverviewCard(
            title: 'Average\nAttendance',
            value: '${_averageAttendance.round()}%',
            icon: Icons.trending_up,
            color: AppColors.secondary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _OverviewCard(
            title: 'Total\nAbsences',
            value: '$_totalAbsences',
            icon: Icons.person_off_outlined,
            color: AppColors.error,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _OverviewCard(
            title: 'Late\nArrivals',
            value: '$_lateArrivals',
            icon: Icons.schedule,
            color: AppColors.accent,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.85),
            AppColors.primaryDark.withOpacity(0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.insights, color: Colors.white, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _className ?? 'Class Overview',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildHeaderStat('Sessions', '$_totalSessions'),
              const SizedBox(width: 16),
              _buildHeaderStat('Students', '$_totalStudents'),
              const SizedBox(width: 16),
              _buildHeaderStat(
                  'Rate', '${_averageAttendance.toStringAsFixed(0)}%'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBreakdown() {
    final theme = Theme.of(context);
    final total = _presentCount + _lateArrivals + _totalAbsences + _excusedCount;
    if (total == 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'STATUS BREAKDOWN',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurfaceVariant,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _StatusChip(
                  label: 'Present',
                  count: _presentCount,
                  color: AppColors.success),
              const SizedBox(width: 8),
              _StatusChip(
                  label: 'Late',
                  count: _lateArrivals,
                  color: AppColors.accent),
              const SizedBox(width: 8),
              _StatusChip(
                  label: 'Absent',
                  count: _totalAbsences,
                  color: AppColors.error),
              const SizedBox(width: 8),
              _StatusChip(
                  label: 'Excused',
                  count: _excusedCount,
                  color: AppColors.info),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsCard() {
    final theme = Theme.of(context);
    final insights = <String>[];
    if (_worstDay != null) {
      insights.add(
        'Most absences happen on $_worstDay. Consider checking in with students that day.',
      );
    }
    if (_bestDay != null && _bestDay != _worstDay) {
      insights.add('$_bestDay has the highest attendance rate.');
    }
    if (_atRiskStudents.isNotEmpty) {
      insights.add(
        '${_atRiskStudents.length} student${_atRiskStudents.length == 1 ? '' : 's'} below 75% attendance — may need follow-up.',
      );
    }
    if (_mostLate.isNotEmpty) {
      insights.add(
        '${_mostLate.first.name} has been late ${_mostLate.first.absences} times — most in the class.',
      );
    }
    if (insights.isEmpty) {
      insights.add('Class attendance looks healthy. Keep it up!');
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.info.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.info.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_outline,
                  color: AppColors.info, size: 18),
              const SizedBox(width: 8),
              Text(
                'INSIGHTS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.info,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...insights.map(
            (i) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Container(
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        color: AppColors.info,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      i,
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.onSurface,
                        height: 1.35,
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

  Widget _buildMostLateSection() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'MOST FREQUENTLY LATE',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurfaceVariant,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 12),
        ..._mostLate.map(
          (s) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.accent.withOpacity(0.12),
                  child: const Icon(Icons.schedule,
                      color: AppColors.accent, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    s.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${s.absences} late',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accent,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAtRiskSection() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'AT-RISK STUDENTS (< 75% attendance)',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurfaceVariant,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 12),
        ..._atRiskStudents.map((s) {
          final attended = s.totalDays - s.absences;
          final rate = s.totalDays > 0
              ? (attended / s.totalDays * 100).clamp(0, 100)
              : 0.0;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.error.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber,
                    color: AppColors.error, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    s.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                Text(
                  '${rate.toStringAsFixed(0)}%',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.error,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildTrendsSection() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'WEEKLY TRENDS',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurfaceVariant,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Column(
            children: [
              SizedBox(
                height: 180,
                child: CustomPaint(
                  size: const Size(double.infinity, 180),
                  painter: _TrendChartPainter(
                    data: _weeklyData,
                    labelColor: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: _weeklyData
                    .map(
                      (w) => Text(
                        w.label,
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMostAbsentSection() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'MOST ABSENT STUDENTS',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurfaceVariant,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 12),
        ...List.generate(_mostAbsent.length, (index) {
          final student = _mostAbsent[index];
          final ratio = student.totalDays > 0
              ? student.absences / student.totalDays
              : 0.0;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.error.withValues(alpha: 0.1),
                  child: Text(
                    student.name
                        .split(' ')
                        .where((w) => w.isNotEmpty)
                        .map((w) => w[0])
                        .take(2)
                        .join()
                        .toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.error,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: ratio,
                          minHeight: 6,
                          backgroundColor: theme.colorScheme.outlineVariant,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            ratio > 0.15 ? AppColors.error : AppColors.accent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${student.absences}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: AppColors.error,
                      ),
                    ),
                    Text(
                      'absences',
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildDailyBreakdownSection() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ATTENDANCE BY DAY',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurfaceVariant,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Column(
            children: _dailyBreakdown.map((day) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    SizedBox(
                      width: 36,
                      child: Text(
                        day.day,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: day.percentage / 100,
                          minHeight: 14,
                          backgroundColor: theme.colorScheme.surfaceContainerLowest,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            day.percentage >= 95
                                ? AppColors.secondary
                                : day.percentage >= 90
                                ? AppColors.primary
                                : AppColors.accent,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 40,
                      child: Text(
                        '${day.percentage}%',
                        textAlign: TextAlign.end,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _OverviewCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _OverviewCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendChartPainter extends CustomPainter {
  final List<_WeekData> data;
  final Color labelColor;

  _TrendChartPainter({required this.data, required this.labelColor});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    const double minVal = 80;
    const double maxVal = 100;
    const double range = maxVal - minVal;

    final gridPaint = Paint()
      ..color = labelColor.withOpacity(0.12)
      ..strokeWidth = 1;

    for (int i = 0; i <= 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final linePaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.primary.withValues(alpha: 0.25),
          AppColors.primary.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final dotPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill;

    final dotBorderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final points = <Offset>[];
    for (int i = 0; i < data.length; i++) {
      final x = data.length == 1
          ? size.width / 2
          : i * size.width / (data.length - 1);
      final clamped = data[i].percentage.clamp(minVal, maxVal);
      final normalized = (clamped - minVal) / range;
      final y = size.height - (normalized * size.height);
      points.add(Offset(x, y));
    }

    if (points.length == 1) {
      canvas.drawCircle(points[0], 5, dotBorderPaint);
      canvas.drawCircle(points[0], 3.5, dotPaint);
      return;
    }

    final linePath = Path()..moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      final cp1x = points[i - 1].dx + (points[i].dx - points[i - 1].dx) / 3;
      final cp2x = points[i].dx - (points[i].dx - points[i - 1].dx) / 3;
      linePath.cubicTo(
        cp1x,
        points[i - 1].dy,
        cp2x,
        points[i].dy,
        points[i].dx,
        points[i].dy,
      );
    }

    final fillPath = Path.from(linePath)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(fillPath, fillPaint);

    canvas.drawPath(linePath, linePaint);

    for (final point in points) {
      canvas.drawCircle(point, 5, dotBorderPaint);
      canvas.drawCircle(point, 3.5, dotPaint);
    }

    final textPainterStyle = TextStyle(
      fontSize: 10,
      color: labelColor,
      fontWeight: FontWeight.w500,
    );
    for (int i = 0; i <= 4; i++) {
      final val = maxVal - (range * i / 4);
      final tp = TextPainter(
        text: TextSpan(text: '${val.toInt()}%', style: textPainterStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      final y = size.height * i / 4 - tp.height - 2;
      tp.paint(canvas, Offset(0, y));
    }
  }

  @override
  bool shouldRepaint(covariant _TrendChartPainter oldDelegate) =>
      oldDelegate.data != data || oldDelegate.labelColor != labelColor;
}

class _WeekData {
  final String label;
  final double percentage;

  _WeekData({required this.label, required this.percentage});
}

class _AbsentStudent {
  final String name;
  final int absences;
  final int totalDays;

  _AbsentStudent({
    required this.name,
    required this.absences,
    required this.totalDays,
  });
}

class _DayAttendance {
  final String day;
  final int percentage;

  _DayAttendance({required this.day, required this.percentage});
}

class _StatusChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _StatusChip({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StudentAgg {
  final String name;
  int total = 0;
  int present = 0;
  int late = 0;
  int absent = 0;
  int excused = 0;

  _StudentAgg({required this.name});
}

class _DayAgg {
  final int weekday;
  int total = 0;
  int attended = 0;

  _DayAgg({required this.weekday});
}

class _WeekAgg {
  final String label;
  int total = 0;
  int attended = 0;

  _WeekAgg({required this.label});
}
