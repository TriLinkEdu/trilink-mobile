import 'package:flutter/material.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/theme/app_colors.dart';

class TeacherGradeAnalyticsScreen extends StatefulWidget {
  const TeacherGradeAnalyticsScreen({super.key});

  @override
  State<TeacherGradeAnalyticsScreen> createState() =>
      _TeacherGradeAnalyticsScreenState();
}

class _TeacherGradeAnalyticsScreenState
    extends State<TeacherGradeAnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool _loadingClasses = true;
  bool _loadingReport = false;
  String? _error;

  List<Map<String, dynamic>> _classOfferings = [];
  String? _selectedClassId;

  // Roster: studentId -> name
  final Map<String, String> _studentNames = {};

  // Groups returned from /grades/class/:id
  List<_AssessmentGroup> _groups = [];
  String? _selectedAssessmentTitle;

  // Per-student aggregates
  List<_StudentGrade> _studentAverages = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _bootstrap();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
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

      final results = await Future.wait([
        ApiService().getClassGrades(_selectedClassId!),
        ApiService().getClassStudents(_selectedClassId!),
      ]);
      if (!mounted) return;

      final gradesData = results[0];
      final studentsData = results[1];

      _studentNames.clear();
      final students = studentsData['students'] as List<dynamic>? ?? [];
      for (final s in students) {
        final m = s as Map<String, dynamic>;
        final id = (m['userId'] ?? m['studentId'] ?? m['id']) as String?;
        if (id == null) continue;
        final firstName = (m['firstName'] ?? '') as String;
        final lastName = (m['lastName'] ?? '') as String;
        final fullName = '$firstName $lastName'.trim();
        _studentNames[id] =
            fullName.isEmpty ? (m['name'] as String? ?? 'Student') : fullName;
      }

      final groupsRaw = gradesData['groups'] as List<dynamic>? ?? [];
      _groups = groupsRaw.map((g) {
        final m = g as Map<String, dynamic>;
        final entries = (m['entries'] as List<dynamic>? ?? []).map((e) {
          final em = e as Map<String, dynamic>;
          return _GradeEntry(
            studentId: (em['studentId'] ?? '') as String,
            score: (em['score'] as num?)?.toDouble(),
            maxScore: (em['maxScore'] as num?)?.toDouble() ?? 100,
            releasedAt: em['releasedAt'] as String?,
          );
        }).toList();
        return _AssessmentGroup(
          title: (m['title'] ?? 'Untitled') as String,
          type: ((m['type'] ?? 'other') as String).toLowerCase(),
          studentCount: (m['studentCount'] as num?)?.toInt() ??
              entries.length,
          entries: entries,
        );
      }).toList();

      _selectedAssessmentTitle =
          _groups.isNotEmpty ? _groups.first.title : null;

      // Compute per-student averages across all groups
      final aggMap = <String, _StudentAgg>{};
      for (final g in _groups) {
        for (final e in g.entries) {
          if (e.score == null) continue;
          final pct = (e.score! / e.maxScore) * 100;
          final agg = aggMap.putIfAbsent(
              e.studentId, () => _StudentAgg(studentId: e.studentId));
          agg.percentages.add(pct);
        }
      }
      _studentAverages = aggMap.values.map((a) {
        final avg = a.percentages.isEmpty
            ? 0.0
            : a.percentages.reduce((x, y) => x + y) / a.percentages.length;
        return _StudentGrade(
          studentId: a.studentId,
          name: _studentNames[a.studentId] ?? 'Student',
          average: avg,
          assessmentCount: a.percentages.length,
        );
      }).toList()
        ..sort((a, b) => a.average.compareTo(b.average));

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

  String _labelFor(Map<String, dynamic> offering) {
    final subject = offering['subject'];
    final grade = offering['grade'];
    final section = offering['section'];
    final subjectName = subject is Map ? (subject['name'] ?? '') : '';
    final gradeName = grade is Map ? (grade['name'] ?? '') : '';
    final sectionName = section is Map ? (section['name'] ?? '') : '';
    final composed = '$subjectName $gradeName$sectionName'.trim();
    if (composed.isNotEmpty) return composed;
    return (offering['displayName'] ??
            offering['subjectName'] ??
            offering['name'] ??
            'Class') as String;
  }

  double get _classAverage {
    if (_studentAverages.isEmpty) return 0;
    return _studentAverages.map((s) => s.average).reduce((a, b) => a + b) /
        _studentAverages.length;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Grade Analytics'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'By Assessment'),
            Tab(text: 'Students'),
          ],
        ),
      ),
      body: _loadingClasses
          ? const Center(child: CircularProgressIndicator())
          : _classOfferings.isEmpty
              ? Center(
                  child: Text(
                    _error ?? 'No classes assigned',
                    style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: _buildClassDropdown(theme),
                    ),
                    Expanded(
                      child: _loadingReport
                          ? const Center(child: CircularProgressIndicator())
                          : TabBarView(
                              controller: _tabController,
                              children: [
                                _buildOverviewTab(theme),
                                _buildByAssessmentTab(theme),
                                _buildStudentsTab(theme),
                              ],
                            ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildClassDropdown(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
        color: theme.colorScheme.surface,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedClassId,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down),
          items: _classOfferings.map((c) {
            return DropdownMenuItem<String>(
              value: c['id'] as String,
              child: Text(_labelFor(c)),
            );
          }).toList(),
          onChanged: (v) {
            if (v != null && v != _selectedClassId) {
              setState(() => _selectedClassId = v);
              _loadReport();
            }
          },
        ),
      ),
    );
  }

  // ─── TAB 1: OVERVIEW ────────────────────────────────────
  Widget _buildOverviewTab(ThemeData theme) {
    if (_groups.isEmpty) return _emptyState(theme, 'No grades published yet');

    final dist = _gradeDistribution();

    return RefreshIndicator(
      onRefresh: _loadReport,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildClassAverageCard(theme),
          const SizedBox(height: 16),
          _buildGradeDistribution(theme, dist),
          const SizedBox(height: 20),
          Text(
            'LOWEST PERFORMING STUDENTS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          ..._studentAverages.take(5).map((s) => _buildLowPerformerCard(theme, s)),
        ],
      ),
    );
  }

  Widget _buildClassAverageCard(ThemeData theme) {
    final avg = _classAverage;
    final color = avg >= 80
        ? AppColors.success
        : avg >= 60
            ? AppColors.warning
            : AppColors.error;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.85),
            AppColors.primaryDark.withOpacity(0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'CLASS AVERAGE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white70,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${avg.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'across ${_studentAverages.length} students',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.25),
              shape: BoxShape.circle,
            ),
            child: Icon(
              avg >= 70
                  ? Icons.trending_up
                  : avg >= 50
                      ? Icons.trending_flat
                      : Icons.trending_down,
              color: Colors.white,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }

  Map<String, int> _gradeDistribution() {
    final dist = {'A': 0, 'B': 0, 'C': 0, 'D': 0, 'F': 0};
    for (final s in _studentAverages) {
      if (s.average >= 90) {
        dist['A'] = dist['A']! + 1;
      } else if (s.average >= 80) {
        dist['B'] = dist['B']! + 1;
      } else if (s.average >= 70) {
        dist['C'] = dist['C']! + 1;
      } else if (s.average >= 60) {
        dist['D'] = dist['D']! + 1;
      } else {
        dist['F'] = dist['F']! + 1;
      }
    }
    return dist;
  }

  Widget _buildGradeDistribution(ThemeData theme, Map<String, int> dist) {
    final total = dist.values.fold<int>(0, (a, b) => a + b);
    final maxVal = dist.values.fold<int>(1, (a, b) => a > b ? a : b);
    final entries = dist.entries.toList();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'GRADE DISTRIBUTION',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: entries.map((e) {
                final pct = total == 0 ? 0.0 : (e.value / total) * 100;
                final h = maxVal == 0 ? 0.0 : (e.value / maxVal) * 110;
                final color = _gradeColor(e.key);
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          '${e.value}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              constraints: BoxConstraints(maxHeight: 110),
                              height: h,
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(6),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          e.key,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: color,
                          ),
                        ),
                        Text(
                          '${pct.toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 10,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Color _gradeColor(String letter) {
    switch (letter) {
      case 'A':
        return AppColors.success;
      case 'B':
        return Colors.lightGreen;
      case 'C':
        return AppColors.warning;
      case 'D':
        return Colors.deepOrange;
      case 'F':
      default:
        return AppColors.error;
    }
  }

  Widget _buildLowPerformerCard(ThemeData theme, _StudentGrade s) {
    final color = s.average >= 60 ? AppColors.warning : AppColors.error;
    return Container(
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
            backgroundColor: color.withOpacity(0.12),
            child: Text(
              _initials(s.name),
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  '${s.assessmentCount} assessments',
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${s.average.toStringAsFixed(0)}%',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ─── TAB 2: BY ASSESSMENT ───────────────────────────────
  Widget _buildByAssessmentTab(ThemeData theme) {
    if (_groups.isEmpty) return _emptyState(theme, 'No assessments yet');

    final selectedGroup = _groups.firstWhere(
      (g) => g.title == _selectedAssessmentTitle,
      orElse: () => _groups.first,
    );

    final scores =
        selectedGroup.entries.where((e) => e.score != null).toList();
    final scoresWithPct = scores
        .map((e) => (
              entry: e,
              pct: (e.score! / e.maxScore) * 100,
            ))
        .toList()
      ..sort((a, b) => b.pct.compareTo(a.pct));

    final avgPct = scoresWithPct.isEmpty
        ? 0.0
        : scoresWithPct.map((r) => r.pct).reduce((a, b) => a + b) /
            scoresWithPct.length;
    final passing = scoresWithPct.where((r) => r.pct >= 60).length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildAssessmentDropdown(theme),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _MiniStat(
                label: 'Average',
                value: '${avgPct.toStringAsFixed(0)}%',
                color: AppColors.primary,
                icon: Icons.show_chart,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MiniStat(
                label: 'Graded',
                value: '${scores.length}/${selectedGroup.entries.length}',
                color: AppColors.info,
                icon: Icons.check_circle_outline,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MiniStat(
                label: 'Passing',
                value: '$passing',
                color: AppColors.success,
                icon: Icons.thumb_up_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'STUDENT SCORES',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 10),
        ...scoresWithPct.map((r) => _buildAssessmentRow(
              theme,
              r.entry,
              r.pct,
            )),
        if (scoresWithPct.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'No scored entries for this assessment.',
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
      ],
    );
  }

  Widget _buildAssessmentDropdown(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedAssessmentTitle,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down),
          items: _groups.map((g) {
            return DropdownMenuItem<String>(
              value: g.title,
              child: Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _typeColor(g.type).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      g.type.toUpperCase(),
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: _typeColor(g.type),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      g.title,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (v) {
            setState(() => _selectedAssessmentTitle = v);
          },
        ),
      ),
    );
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'exam':
        return AppColors.error;
      case 'assignment':
        return Colors.purple;
      case 'quiz':
        return AppColors.info;
      case 'project':
        return AppColors.secondary;
      default:
        return Colors.blueGrey;
    }
  }

  Widget _buildAssessmentRow(
    ThemeData theme,
    _GradeEntry entry,
    double pct,
  ) {
    final name = _studentNames[entry.studentId] ?? 'Student';
    final passed = pct >= 60;
    final color = pct >= 80
        ? AppColors.success
        : pct >= 60
            ? AppColors.warning
            : AppColors.error;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          Text(
            '${entry.score?.toStringAsFixed(0) ?? '-'} / ${entry.maxScore.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 13,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  passed ? Icons.check : Icons.close,
                  size: 12,
                  color: color,
                ),
                const SizedBox(width: 4),
                Text(
                  '${pct.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── TAB 3: STUDENTS ─────────────────────────────────────
  Widget _buildStudentsTab(ThemeData theme) {
    if (_studentAverages.isEmpty) {
      return _emptyState(theme, 'No student grades yet');
    }
    // Sort alphabetically for student tab
    final sorted = [..._studentAverages]
      ..sort((a, b) => a.name.compareTo(b.name));
    return RefreshIndicator(
      onRefresh: _loadReport,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: sorted.length,
        itemBuilder: (_, i) => _buildStudentRow(theme, sorted[i]),
      ),
    );
  }

  Widget _buildStudentRow(ThemeData theme, _StudentGrade s) {
    final color = s.average >= 80
        ? AppColors.success
        : s.average >= 60
            ? AppColors.warning
            : AppColors.error;
    return Container(
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
            backgroundColor: color.withOpacity(0.12),
            child: Text(
              _initials(s.name),
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (s.average / 100).clamp(0.0, 1.0),
                    minHeight: 5,
                    backgroundColor: color.withOpacity(0.12),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${s.average.toStringAsFixed(0)}%',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(ThemeData theme, String msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.grading_outlined,
              size: 56,
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
            ),
            const SizedBox(height: 12),
            Text(
              msg,
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _initials(String name) {
    return name
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0])
        .take(2)
        .join()
        .toUpperCase();
  }
}

class _AssessmentGroup {
  final String title;
  final String type;
  final int studentCount;
  final List<_GradeEntry> entries;

  _AssessmentGroup({
    required this.title,
    required this.type,
    required this.studentCount,
    required this.entries,
  });
}

class _GradeEntry {
  final String studentId;
  final double? score;
  final double maxScore;
  final String? releasedAt;

  _GradeEntry({
    required this.studentId,
    required this.score,
    required this.maxScore,
    required this.releasedAt,
  });
}

class _StudentAgg {
  final String studentId;
  final List<double> percentages = [];

  _StudentAgg({required this.studentId});
}

class _StudentGrade {
  final String studentId;
  final String name;
  final double average;
  final int assessmentCount;

  _StudentGrade({
    required this.studentId,
    required this.name,
    required this.average,
    required this.assessmentCount,
  });
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
