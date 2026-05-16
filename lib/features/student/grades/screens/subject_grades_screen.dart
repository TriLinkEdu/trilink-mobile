import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:trilink_mobile/core/widgets/animated_counter.dart';
import 'package:trilink_mobile/core/widgets/empty_state_widget.dart';
import 'package:trilink_mobile/core/widgets/illustrations.dart';
import 'package:trilink_mobile/core/widgets/error_widget.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/pressable.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../../shared/widgets/student_page_background.dart';
import '../models/grade_model.dart';
import '../repositories/student_grades_repository.dart';

class SubjectGradesScreen extends StatefulWidget {
  final String subjectId;
  final String subjectName;
  final String? selectedTerm;
  final StudentGradesRepository? repository;

  const SubjectGradesScreen({
    super.key,
    required this.subjectId,
    required this.subjectName,
    this.selectedTerm,
    this.repository,
  });

  @override
  State<SubjectGradesScreen> createState() => _SubjectGradesScreenState();
}

class _SubjectGradesScreenState extends State<SubjectGradesScreen> {
  bool _sortByDateDescending = true;
  bool _isDownloading = false;
  late final StudentGradesRepository _repository =
      widget.repository ?? sl<StudentGradesRepository>();
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
      var grades = await _repository.fetchGradesBySubject(widget.subjectId);
      final term = widget.selectedTerm;
      if (term != null) {
        grades = grades.where((g) => g.term == term).toList();
      }
      if (!mounted) return;
      setState(() {
        _subjectGrades = grades;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load ${widget.subjectName} grades.';
        _isLoading = false;
      });
    }
  }

  Future<void> _downloadReport() async {
    setState(() => _isDownloading = true);
    try {
      final bytes = await _buildPdfBytes();
      final dir = await getApplicationDocumentsDirectory();
      final fileName =
          '${widget.subjectName.replaceAll(RegExp(r'[^\w]'), '_')}_grade_report.pdf';
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Report saved to $fileName'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to generate report: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  Future<List<int>> _buildPdfBytes() async {
    final document = PdfDocument();
    final page = document.pages.add();
    final content = page.graphics;
    final pageWidth = page.getClientSize().width;

    // ── Fonts ──────────────────────────────────────────────────────────────
    final titleFont = PdfStandardFont(PdfFontFamily.helvetica, 18,
        style: PdfFontStyle.bold);
    final headingFont = PdfStandardFont(PdfFontFamily.helvetica, 12,
        style: PdfFontStyle.bold);
    final bodyFont = PdfStandardFont(PdfFontFamily.helvetica, 10);
    final smallFont = PdfStandardFont(PdfFontFamily.helvetica, 9);

    double y = 20;

    // ── Header ─────────────────────────────────────────────────────────────
    content.drawString(
      'TriLink — Grade Report',
      titleFont,
      brush: PdfSolidBrush(PdfColor(67, 97, 238)),
      bounds: Rect.fromLTWH(0, y, pageWidth, 30),
    );
    y += 32;

    content.drawString(
      widget.subjectName,
      headingFont,
      brush: PdfSolidBrush(PdfColor(30, 30, 30)),
      bounds: Rect.fromLTWH(0, y, pageWidth, 20),
    );
    y += 22;

    content.drawString(
      'Generated: ${_formatDate(DateTime.now())}',
      smallFont,
      brush: PdfSolidBrush(PdfColor(100, 100, 100)),
      bounds: Rect.fromLTWH(0, y, pageWidth, 16),
    );
    y += 22;

    // ── Divider ────────────────────────────────────────────────────────────
    content.drawLine(
      PdfPen(PdfColor(200, 200, 200)),
      Offset(0, y),
      Offset(pageWidth, y),
    );
    y += 12;

    // ── Summary stats ──────────────────────────────────────────────────────
    final avg = _average;
    final summaryText =
        'Overall Average: ${avg.toStringAsFixed(1)}%   '  
        'Letter Grade: ${_letterGradeForAverage(avg)}   '
        'Assessments: ${_subjectGrades.length}   '
        'Highest: ${_highest.toStringAsFixed(0)}%   '
        'Lowest: ${_lowest.toStringAsFixed(0)}%';

    content.drawString(
      summaryText,
      bodyFont,
      brush: PdfSolidBrush(PdfColor(40, 40, 40)),
      bounds: Rect.fromLTWH(0, y, pageWidth, 30),
      format: PdfStringFormat(wordWrap: PdfWordWrapType.word),
    );
    y += 40;

    // ── Table header ───────────────────────────────────────────────────────
    content.drawRectangle(
      brush: PdfSolidBrush(PdfColor(67, 97, 238)),
      bounds: Rect.fromLTWH(0, y, pageWidth, 20),
    );
    content.drawString('Assessment', headingFont,
        brush: PdfSolidBrush(PdfColor(255, 255, 255)),
        bounds: Rect.fromLTWH(4, y + 4, pageWidth * 0.5, 14));
    content.drawString('Date', headingFont,
        brush: PdfSolidBrush(PdfColor(255, 255, 255)),
        bounds: Rect.fromLTWH(pageWidth * 0.5, y + 4, pageWidth * 0.25, 14));
    content.drawString('Score', headingFont,
        brush: PdfSolidBrush(PdfColor(255, 255, 255)),
        bounds: Rect.fromLTWH(pageWidth * 0.75, y + 4, pageWidth * 0.15, 14));
    content.drawString('Grade', headingFont,
        brush: PdfSolidBrush(PdfColor(255, 255, 255)),
        bounds: Rect.fromLTWH(pageWidth * 0.9, y + 4, pageWidth * 0.1, 14));
    y += 22;

    // ── Table rows ─────────────────────────────────────────────────────────
    final sorted = List<GradeModel>.from(_subjectGrades)
      ..sort((a, b) => b.date.compareTo(a.date));

    for (int i = 0; i < sorted.length; i++) {
      final g = sorted[i];
      if (i.isEven) {
        content.drawRectangle(
          brush: PdfSolidBrush(PdfColor(245, 247, 255)),
          bounds: Rect.fromLTWH(0, y, pageWidth, 18),
        );
      }
      content.drawString(g.assessmentName, bodyFont,
          brush: PdfSolidBrush(PdfColor(30, 30, 30)),
          bounds: Rect.fromLTWH(4, y + 3, pageWidth * 0.5, 14));
      content.drawString(_formatDate(g.date), bodyFont,
          brush: PdfSolidBrush(PdfColor(80, 80, 80)),
          bounds: Rect.fromLTWH(pageWidth * 0.5, y + 3, pageWidth * 0.25, 14));
      content.drawString(
          '${g.percentage.toStringAsFixed(0)}%', bodyFont,
          brush: PdfSolidBrush(PdfColor(30, 30, 30)),
          bounds:
              Rect.fromLTWH(pageWidth * 0.75, y + 3, pageWidth * 0.15, 14));
      content.drawString(g.letterGrade, bodyFont,
          brush: PdfSolidBrush(PdfColor(67, 97, 238)),
          bounds:
              Rect.fromLTWH(pageWidth * 0.9, y + 3, pageWidth * 0.1, 14));
      y += 20;

      // Add a new page if we're running out of space
      if (y > page.getClientSize().height - 30 &&
          i < sorted.length - 1) {
        document.pages.add();
        y = 20;
        content.save();
      }
    }

    // ── Footer ─────────────────────────────────────────────────────────────
    y += 12;
    content.drawLine(
      PdfPen(PdfColor(200, 200, 200)),
      Offset(0, y),
      Offset(pageWidth, y),
    );
    y += 8;
    content.drawString(
      'TriLink Intelligent Tutoring System — Confidential',
      smallFont,
      brush: PdfSolidBrush(PdfColor(150, 150, 150)),
      bounds: Rect.fromLTWH(0, y, pageWidth, 14),
    );

    final bytes = await document.save();
    document.dispose();
    return bytes;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: StudentPageBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                child: Row(
                  children: [
                    Pressable(
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
                        style: theme.textTheme.titleLarge?.copyWith(
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
                    ? const Padding(
                        padding: AppSpacing.horizontalXl,
                        child: ShimmerList(itemCount: 6, itemHeight: 72),
                      )
                    : _error != null
                    ? AppErrorWidget(
                        message: _error!,
                        onRetry: _loadSubjectGrades,
                      )
                    : _subjectGrades.isEmpty
                    ? const EmptyStateWidget(
                        illustration: GraduationCapIllustration(),
                        icon: Icons.assignment_rounded,
                        title: 'No assessments yet',
                        subtitle:
                            'Assessment results for this subject will appear here.',
                      )
                    : SingleChildScrollView(
                        padding: AppSpacing.horizontalXl,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              decoration: BoxDecoration(
                                gradient: Theme.of(context).ext.heroGradient,
                                borderRadius: AppRadius.borderXl,
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    'CURRENT AVERAGE',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme.colorScheme.onPrimary
                                          .withAlpha(180),
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                  AppSpacing.gapSm,
                                  Center(
                                    child: Hero(
                                      tag: 'grade-hero-${widget.subjectId}',
                                      child: Material(
                                        color: Colors.transparent,
                                        child: AnimatedCounter(
                                          value: _average,
                                          showTrend: true,
                                          style: theme.textTheme.displayLarge
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color:
                                                    theme.colorScheme.onPrimary,
                                                height: 1,
                                              ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  AppSpacing.gapSm,
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _gradeChipColor(
                                        _letterGradeForAverage(_average),
                                      ).withAlpha(180),
                                      borderRadius: AppRadius.borderSm,
                                    ),
                                    child: Text(
                                      'Grade ${_letterGradeForAverage(_average)}',
                                      style: theme.textTheme.labelLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: theme.colorScheme.onPrimary,
                                          ),
                                    ),
                                  ),
                                  AppSpacing.gapLg,
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
                                        value: '${_lowest.toStringAsFixed(0)}%',
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            AppSpacing.gapXxl,
                            Text(
                              'Grade Distribution',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            AppSpacing.gapMd,
                            _GradeBar(
                              grade: 'A',
                              count: _bucketCount(
                                _subjectGrades,
                                (p) => p >= 90,
                              ),
                              maxCount: _subjectGrades.length,
                            ),
                            AppSpacing.gapSm,
                            _GradeBar(
                              grade: 'B',
                              count: _bucketCount(
                                _subjectGrades,
                                (p) => p >= 80 && p < 90,
                              ),
                              maxCount: _subjectGrades.length,
                            ),
                            AppSpacing.gapSm,
                            _GradeBar(
                              grade: 'C',
                              count: _bucketCount(
                                _subjectGrades,
                                (p) => p >= 70 && p < 80,
                              ),
                              maxCount: _subjectGrades.length,
                            ),
                            AppSpacing.gapSm,
                            _GradeBar(
                              grade: 'D',
                              count: _bucketCount(
                                _subjectGrades,
                                (p) => p < 70,
                              ),
                              maxCount: _subjectGrades.length,
                            ),
                            AppSpacing.gapXxxl,
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Assessments',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    setState(
                                      () => _sortByDateDescending =
                                          !_sortByDateDescending,
                                    );
                                  },
                                  child: Text(
                                    _sortByDateDescending
                                        ? 'Sort by Date ↓'
                                        : 'Sort by Date ↑',
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            AppSpacing.gapSm,
                            for (final assessment in _sortedAssessments) ...[
                              _AssessmentRow(
                                icon:
                                    assessment.assessmentName
                                        .toLowerCase()
                                        .contains('quiz')
                                    ? Icons.quiz_rounded
                                    : Icons.assignment_rounded,
                                title: assessment.assessmentName,
                                date: _formatDate(assessment.date),
                                score:
                                    '${assessment.percentage.toStringAsFixed(0)}%',
                                grade: assessment.letterGrade,
                                gradeColor: _gradeColor(assessment.percentage),
                              ),
                              AppSpacing.gapSm,
                            ],
                            AppSpacing.gapXxl,
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
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: theme.colorScheme.onPrimary,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.download_rounded,
                                        size: 20,
                                      ),
                                label: Text(
                                  _isDownloading
                                      ? 'Preparing...'
                                      : 'Download Report PDF',
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.colorScheme.primary,
                                  foregroundColor: theme.colorScheme.onPrimary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: AppRadius.borderMd,
                                  ),
                                  elevation: 0,
                                  textStyle: theme.textTheme.titleSmall
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                            AppSpacing.gapXxl,
                          ],
                        ),
                      ),
              ),
            ],
          ),
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
        return AppColors.success;
      case 'B':
        return Theme.of(context).colorScheme.primary;
      case 'C':
        return AppColors.warning;
      default:
        return AppColors.danger;
    }
  }

  String _formatDate(DateTime date) {
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
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Color _gradeColor(double percentage) {
    if (percentage >= 90) return AppColors.success;
    if (percentage >= 80) return Theme.of(context).colorScheme.primary;
    if (percentage >= 70) return AppColors.warning;
    return AppColors.danger;
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;

  const _StatBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onPrimary.withAlpha(180),
          ),
        ),
        AppSpacing.gapXs,
        Text(
          value,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onPrimary,
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
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
        AppSpacing.hGapMd,
        Expanded(
          child: Stack(
            children: [
              Container(
                height: 10,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: AppRadius.borderSm,
                ),
              ),
              FractionallySizedBox(
                widthFactor: maxCount > 0 ? count / maxCount : 0,
                child: Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: AppRadius.borderSm,
                  ),
                ),
              ),
            ],
          ),
        ),
        AppSpacing.hGapMd,
        SizedBox(
          width: 20,
          child: Text(
            '$count',
            textAlign: TextAlign.right,
            style: theme.textTheme.bodySmall?.copyWith(
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
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppRadius.borderMd,
        boxShadow: AppShadows.subtle(theme.shadowColor),
      ),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.primary, size: 22),
          AppSpacing.hGapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                AppSpacing.gapXxs,
                Text(
                  date,
                  style: theme.textTheme.labelSmall?.copyWith(
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
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              Text(
                grade,
                style: theme.textTheme.bodySmall?.copyWith(
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
