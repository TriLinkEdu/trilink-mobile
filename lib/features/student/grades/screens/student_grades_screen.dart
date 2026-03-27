import 'package:flutter/material.dart';
import '../../../../core/routes/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../models/grade_model.dart';
import '../repositories/mock_student_grades_repository.dart';
import '../repositories/student_grades_repository.dart';

class StudentGradesScreen extends StatefulWidget {
  final StudentGradesRepository? repository;

  const StudentGradesScreen({super.key, this.repository});

  @override
  State<StudentGradesScreen> createState() => _StudentGradesScreenState();
}

class _StudentGradesScreenState extends State<StudentGradesScreen> {
  bool _isThisTerm = true;
  late final StudentGradesRepository _repository =
      widget.repository ?? MockStudentGradesRepository();
  bool _isLoading = true;
  String? _error;
  List<_SubjectSummary> _summaries = const [];

  @override
  void initState() {
    super.initState();
    _loadGrades();
  }

  Future<void> _loadGrades() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final term = _isThisTerm ? 'Fall 2023' : 'Spring 2023';
      final grades = await _repository.fetchGrades(term: term);
      final bySubject = <String, List<GradeModel>>{};
      for (final grade in grades) {
        bySubject.putIfAbsent(grade.subjectId, () => <GradeModel>[]).add(grade);
      }

      final summaries = bySubject.entries.map((entry) {
        final subjectGrades = entry.value
          ..sort((a, b) => a.date.compareTo(b.date));
        final average =
            subjectGrades.map((g) => g.percentage).reduce((a, b) => a + b) /
                subjectGrades.length;
        final trend = subjectGrades.length > 1
            ? subjectGrades.last.percentage - subjectGrades.first.percentage
            : 0.0;

        return _SubjectSummary(
          subjectId: entry.key,
          subjectName: subjectGrades.first.subjectName,
          average: average,
          assessmentCount: subjectGrades.length,
          trend: trend,
        );
      }).toList()
        ..sort((a, b) => b.average.compareTo(a.average));

      if (!mounted) return;
      setState(() {
        _summaries = summaries;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Unable to load grades right now.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  SizedBox(
                    width: 40,
                    child: Navigator.of(context).canPop()
                        ? IconButton(
                            tooltip: 'Back',
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              size: 18,
                            ),
                          )
                        : null,
                  ),
                  const Expanded(
                    child: Text(
                      'Academic Grades',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Switch term view',
                    onPressed: () {
                      setState(() => _isThisTerm = !_isThisTerm);
                      _loadGrades();
                    },
                    icon: const Icon(
                      Icons.more_horiz,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        semanticsLabel: 'Loading grades',
                      ),
                    )
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(_error!,
                                  style: const TextStyle(color: Colors.red)),
                              const SizedBox(height: 10),
                              ElevatedButton(
                                onPressed: _loadGrades,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      : _summaries.isEmpty
                          ? const Center(
                              child: Text(
                                'No grades available yet.',
                                style:
                                    TextStyle(color: AppColors.textSecondary),
                              ),
                            )
                          : SingleChildScrollView(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 28),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withAlpha(20),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          'Overall Average',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          '${_overallAverage.toStringAsFixed(0)}%',
                                          style: const TextStyle(
                                            fontSize: 48,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 5,
                                          ),
                                          decoration: BoxDecoration(
                                            color:
                                                AppColors.primary.withAlpha(30),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.shield_rounded,
                                                size: 14,
                                                color: AppColors.primary,
                                              ),
                                              SizedBox(width: 4),
                                              Text(
                                                'Performance Updated',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: AppColors.primary,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _isThisTerm
                                            ? 'Fall Semester 2023'
                                            : 'Spring Semester 2023',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pushNamed(
                                              RouteNames.studentAssignments);
                                        },
                                        child: const Text(
                                          'Assignments',
                                          style: TextStyle(
                                            color: AppColors.primary,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  for (int index = 0;
                                      index < _summaries.length;
                                      index++) ...[
                                    _SubjectGradeRow(
                                      icon: _iconForSubject(
                                          _summaries[index].subjectName),
                                      iconBgColor: _colorForSubject(
                                          _summaries[index].subjectName),
                                      name: _summaries[index].subjectName,
                                      detail:
                                          '${_summaries[index].assessmentCount} Assessments',
                                      grade:
                                          '${_summaries[index].average.toStringAsFixed(0)}%',
                                      change:
                                          _trendLabel(_summaries[index].trend),
                                      isPositive:
                                          _summaries[index].trend >= 0,
                                      isHighlighted: index == 0,
                                      onTap: () =>
                                          Navigator.of(context).pushNamed(
                                        RouteNames.studentSubjectGrades,
                                        arguments: {
                                          'subjectId':
                                              _summaries[index].subjectId,
                                          'subjectName':
                                              _summaries[index].subjectName,
                                        },
                                      ),
                                    ),
                                    if (index < _summaries.length - 1)
                                      const SizedBox(height: 10),
                                  ],
                                  const SizedBox(height: 20),
                                ],
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  double get _overallAverage {
    if (_summaries.isEmpty) return 0;
    return _summaries.map((summary) => summary.average).reduce((a, b) => a + b) /
        _summaries.length;
  }

  String _trendLabel(double trend) {
    if (trend.abs() < 0.1) return '0.0%';
    final sign = trend >= 0 ? '+' : '';
    return '$sign${trend.toStringAsFixed(1)}%';
  }

  IconData _iconForSubject(String subjectName) {
    return switch (subjectName.toLowerCase()) {
      'mathematics' => Icons.calculate_rounded,
      'physics' => Icons.science_rounded,
      'literature' || 'english literature' => Icons.auto_stories_rounded,
      'history' => Icons.history_edu_rounded,
      'computer science' => Icons.computer_rounded,
      _ => Icons.school_rounded,
    };
  }

  Color _colorForSubject(String subjectName) {
    return switch (subjectName.toLowerCase()) {
      'mathematics' => const Color(0xFF1A73E8),
      'physics' => const Color(0xFF5F6368),
      'literature' || 'english literature' => const Color(0xFFEF6C00),
      'history' => const Color(0xFF6D4C41),
      'computer science' => const Color(0xFF0F9D58),
      _ => const Color(0xFF5F6368),
    };
  }
}

class _SubjectSummary {
  final String subjectId;
  final String subjectName;
  final double average;
  final int assessmentCount;
  final double trend;

  const _SubjectSummary({
    required this.subjectId,
    required this.subjectName,
    required this.average,
    required this.assessmentCount,
    required this.trend,
  });
}

class _SubjectGradeRow extends StatelessWidget {
  final IconData icon;
  final Color iconBgColor;
  final String name;
  final String detail;
  final String grade;
  final String change;
  final bool isPositive;
  final bool isHighlighted;
  final VoidCallback onTap;

  const _SubjectGradeRow({
    required this.icon,
    required this.iconBgColor,
    required this.name,
    required this.detail,
    required this.grade,
    required this.change,
    required this.isPositive,
    required this.isHighlighted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isHighlighted ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(8),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isHighlighted
                      ? Colors.white.withAlpha(40)
                      : iconBgColor.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: isHighlighted ? Colors.white : iconBgColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isHighlighted
                            ? Colors.white
                            : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      detail,
                      style: TextStyle(
                        fontSize: 11,
                        color: isHighlighted
                            ? Colors.white.withAlpha(180)
                            : Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    grade,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isHighlighted
                          ? Colors.white
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPositive
                            ? Icons.trending_up_rounded
                            : Icons.trending_down_rounded,
                        size: 14,
                        color: isHighlighted
                            ? Colors.white.withAlpha(180)
                            : isPositive
                                ? Colors.green
                                : Colors.red,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        change,
                        style: TextStyle(
                          fontSize: 11,
                          color: isHighlighted
                              ? Colors.white.withAlpha(180)
                              : isPositive
                                  ? Colors.green
                                  : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
