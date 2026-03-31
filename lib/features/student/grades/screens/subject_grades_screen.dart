import 'package:flutter/material.dart';
import '../models/grade_model.dart';
import '../repositories/mock_student_grades_repository.dart';
import '../repositories/student_grades_repository.dart';

class SubjectGradesScreen extends StatefulWidget {
  final String subjectId;
  final String subjectName;
  final StudentGradesRepository? repository;

  const SubjectGradesScreen({
    super.key,
    required this.subjectId,
    required this.subjectName,
    this.repository,
  });

  @override
  State<SubjectGradesScreen> createState() => _SubjectGradesScreenState();
}

class _SubjectGradesScreenState extends State<SubjectGradesScreen> {
  bool _sortByDateDescending = true;
  bool _isDownloading = false;
  late final StudentGradesRepository _repository =
      widget.repository ?? MockStudentGradesRepository();
  bool _isLoading = true;
  String? _error;
  List<GradeModel> _subjectGrades = const [];

  @override
  void initState() {
    super.initState();
    _loadSubjectGrades();
  }

  Future<void> _loadSubjectGrades() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final grades = await _repository.fetchGradesBySubject(widget.subjectId);
      if (!mounted) return;
      setState(() {
        _subjectGrades = grades;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load ${widget.subjectName} grades.';
        _isLoading = false;
      });
    }
  }

  Future<void> _downloadReport() async {
    setState(() => _isDownloading = true);
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    setState(() => _isDownloading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Report saved')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 20,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      widget.subjectName,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(_error!,
                                  style: const TextStyle(color: Colors.red)),
                              const SizedBox(height: 10),
                              ElevatedButton(
                                onPressed: _loadSubjectGrades,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      : _subjectGrades.isEmpty
                          ? Center(
                              child: Text(
                                'No assessments available for this subject yet.',
                                style: TextStyle(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
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
                                        vertical: 24),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF1A73E8),
                                          Color(0xFF4A90E2),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          'CURRENT AVERAGE',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color:
                                                Colors.white.withAlpha(180),
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 1,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _average.toStringAsFixed(0),
                                              style: const TextStyle(
                                                fontSize: 54,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                                height: 1,
                                              ),
                                            ),
                                            const Padding(
                                              padding:
                                                  EdgeInsets.only(top: 8),
                                              child: Text(
                                                '%',
                                                style: TextStyle(
                                                  fontSize: 22,
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.white70,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _gradeChipColor(
                                                    _letterGradeForAverage(
                                                        _average))
                                                .withAlpha(180),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            'Grade ${_letterGradeForAverage(_average)}',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 18),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceEvenly,
                                          children: [
                                            _StatBox(
                                              label: 'Highest Score',
                                              value:
                                                  '${_highest.toStringAsFixed(0)}%',
                                            ),
                                            _StatBox(
                                              label: 'Lowest Score',
                                              value:
                                                  '${_lowest.toStringAsFixed(0)}%',
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  Text(
                                    'Grade Distribution',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  _GradeBar(
                                    grade: 'A',
                                    count: _bucketCount(
                                        _subjectGrades, (p) => p >= 90),
                                    maxCount: _subjectGrades.length,
                                  ),
                                  const SizedBox(height: 8),
                                  _GradeBar(
                                    grade: 'B',
                                    count: _bucketCount(_subjectGrades,
                                        (p) => p >= 80 && p < 90),
                                    maxCount: _subjectGrades.length,
                                  ),
                                  const SizedBox(height: 8),
                                  _GradeBar(
                                    grade: 'C',
                                    count: _bucketCount(_subjectGrades,
                                        (p) => p >= 70 && p < 80),
                                    maxCount: _subjectGrades.length,
                                  ),
                                  const SizedBox(height: 8),
                                  _GradeBar(
                                    grade: 'D',
                                    count: _bucketCount(
                                        _subjectGrades, (p) => p < 70),
                                    maxCount: _subjectGrades.length,
                                  ),
                                  const SizedBox(height: 28),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Assessments',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: theme.colorScheme.onSurface,
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          setState(() =>
                                              _sortByDateDescending =
                                                  !_sortByDateDescending);
                                        },
                                        child: Text(
                                          _sortByDateDescending
                                              ? 'Sort by Date ↓'
                                              : 'Sort by Date ↑',
                                          style: TextStyle(
                                            color: theme.colorScheme.primary,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  for (final assessment
                                      in _sortedAssessments) ...[
                                    _AssessmentRow(
                                      icon: assessment.assessmentName
                                              .toLowerCase()
                                              .contains('quiz')
                                          ? Icons.quiz_rounded
                                          : Icons.assignment_rounded,
                                      title: assessment.assessmentName,
                                      date: _formatDate(assessment.date),
                                      score:
                                          '${assessment.percentage.toStringAsFixed(0)}%',
                                      grade: assessment.letterGrade,
                                      gradeColor: _gradeColor(
                                          assessment.percentage),
                                    ),
                                    const SizedBox(height: 8),
                                  ],
                                  const SizedBox(height: 24),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 50,
                                    child: ElevatedButton.icon(
                                      onPressed: _isDownloading
                                          ? null
                                          : _downloadReport,
                                      icon: _isDownloading
                                          ? SizedBox(
                                              width: 20,
                                              height: 20,
                                              child:
                                                  CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: theme
                                                    .colorScheme.onPrimary,
                                              ),
                                            )
                                          : const Icon(
                                              Icons.download_rounded,
                                              size: 20),
                                      label: Text(_isDownloading
                                          ? 'Preparing...'
                                          : 'Download Report PDF'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            theme.colorScheme.primary,
                                        foregroundColor:
                                            theme.colorScheme.onPrimary,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        elevation: 0,
                                        textStyle: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                ],
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  List<GradeModel> get _sortedAssessments {
    final sorted = List<GradeModel>.from(_subjectGrades)
      ..sort((a, b) => a.date.compareTo(b.date));
    return _sortByDateDescending ? sorted.reversed.toList() : sorted;
  }

  double get _average {
    if (_subjectGrades.isEmpty) return 0;
    return _subjectGrades
            .map((grade) => grade.percentage)
            .reduce((a, b) => a + b) /
        _subjectGrades.length;
  }

  double get _lowest {
    if (_subjectGrades.isEmpty) return 0;
    return _subjectGrades
        .map((grade) => grade.percentage)
        .reduce((a, b) => a < b ? a : b);
  }

  double get _highest {
    if (_subjectGrades.isEmpty) return 0;
    return _subjectGrades
        .map((grade) => grade.percentage)
        .reduce((a, b) => a > b ? a : b);
  }

  int _bucketCount(List<GradeModel> list, bool Function(double) predicate) {
    return list.where((grade) => predicate(grade.percentage)).length;
  }

  String _letterGradeForAverage(double avg) {
    if (avg >= 90) return 'A';
    if (avg >= 80) return 'B';
    if (avg >= 70) return 'C';
    if (avg >= 60) return 'D';
    return 'F';
  }

  Color _gradeChipColor(String grade) {
    switch (grade) {
      case 'A':
        return Colors.green;
      case 'B':
        return Theme.of(context).colorScheme.primary;
      case 'C':
        return Colors.orange;
      default:
        return Colors.red;
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Color _gradeColor(double percentage) {
    if (percentage >= 90) return Colors.green;
    if (percentage >= 80) return Theme.of(context).colorScheme.primary;
    if (percentage >= 70) return Colors.orange;
    return Colors.red;
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;

  const _StatBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.white.withAlpha(180)),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

class _GradeBar extends StatelessWidget {
  final String grade;
  final int count;
  final int maxCount;

  const _GradeBar({
    required this.grade,
    required this.count,
    required this.maxCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        SizedBox(
          width: 20,
          child: Text(
            grade,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Stack(
            children: [
              Container(
                height: 10,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              FractionallySizedBox(
                widthFactor: maxCount > 0 ? count / maxCount : 0,
                child: Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 20,
          child: Text(
            '$count',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

class _AssessmentRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String date;
  final String score;
  final String grade;
  final Color gradeColor;

  const _AssessmentRow({
    required this.icon,
    required this.title,
    required this.date,
    required this.score,
    required this.grade,
    required this.gradeColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withAlpha(8),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.primary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  date,
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                score,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              Text(
                grade,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: gradeColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
