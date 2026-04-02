import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/routes/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../cubit/grades_cubit.dart';
import '../models/grade_model.dart';
import '../repositories/student_grades_repository.dart';

class StudentGradesScreen extends StatelessWidget {
  const StudentGradesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GradesCubit(sl<StudentGradesRepository>())..loadGrades(),
      child: const _GradesView(),
    );
  }
}

class _GradesView extends StatelessWidget {
  const _GradesView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GradesCubit, GradesState>(
      builder: (context, state) {
        final theme = Theme.of(context);
        final summaries = _summariesFromGrades(state.grades);
        final overallAverage = _overallAverage(summaries);
        final isLoading = state.status == GradesStatus.initial ||
            state.status == GradesStatus.loading;

        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding:
                      EdgeInsets.only(right: AppSpacing.md, top: AppSpacing.xs),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        tooltip: 'Switch term view',
                        onPressed: () {
                          final next = state.selectedTerm == 'Fall 2023'
                              ? 'Spring 2023'
                              : 'Fall 2023';
                          context.read<GradesCubit>().switchTerm(next);
                        },
                        icon: Icon(
                          Icons.more_horiz,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: isLoading
                      ? const Padding(
                          padding: AppSpacing.horizontalXl,
                          child: ShimmerList(itemCount: 6, itemHeight: 72),
                        )
                      : state.status == GradesStatus.error
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('Unable to load grades right now.',
                                      style: TextStyle(color: Theme.of(context).colorScheme.error)),
                                  AppSpacing.gapSm,
                                  ElevatedButton(
                                    onPressed: () => context
                                        .read<GradesCubit>()
                                        .loadGrades(),
                                    child: const Text('Retry'),
                                  ),
                                ],
                              ),
                            )
                          : summaries.isEmpty
                              ? Center(
                                  child: Text(
                                    'No grades available yet.',
                                    style: TextStyle(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                )
                              : SingleChildScrollView(
                                  padding: AppSpacing.horizontalXl,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 28),
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.primary
                                              .withAlpha(20),
                                          borderRadius: AppRadius.borderXl,
                                        ),
                                        child: Column(
                                          children: [
                                            Text(
                                              'Overall Average',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: theme.colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                            ),
                                            AppSpacing.gapSm,
                                            Text(
                                              '${overallAverage.toStringAsFixed(0)}%',
                                              style: TextStyle(
                                                fontSize: 48,
                                                fontWeight: FontWeight.bold,
                                                color: theme.colorScheme.primary,
                                              ),
                                            ),
                                            AppSpacing.gapXs,
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 5,
                                              ),
                                              decoration: BoxDecoration(
                                                color: theme.colorScheme.primary
                                                    .withAlpha(30),
                                                borderRadius: AppRadius.borderXl,
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.shield_rounded,
                                                    size: 14,
                                                    color: theme
                                                        .colorScheme.primary,
                                                  ),
                                                  AppSpacing.hGapXs,
                                                  Text(
                                                    'Performance Updated',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: theme
                                                          .colorScheme.primary,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      AppSpacing.gapXxl,
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            state.selectedTerm == 'Fall 2023'
                                                ? 'Fall Semester 2023'
                                                : 'Spring Semester 2023',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: theme.colorScheme.onSurface,
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              Navigator.of(context).pushNamed(
                                                  RouteNames.studentAssignments);
                                            },
                                            child: Text(
                                              'Assignments',
                                              style: TextStyle(
                                                color:
                                                    theme.colorScheme.primary,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      AppSpacing.gapSm,
                                      for (int index = 0;
                                          index < summaries.length;
                                          index++) ...[
                                        _SubjectGradeRow(
                                          icon: _iconForSubject(
                                              summaries[index].subjectName),
                                          iconBgColor: _colorForSubject(
                                              summaries[index].subjectName),
                                          name: summaries[index].subjectName,
                                          detail:
                                              '${summaries[index].assessmentCount} Assessments',
                                          grade:
                                              '${summaries[index].average.toStringAsFixed(0)}%',
                                          change: _trendLabel(
                                              summaries[index].trend),
                                          isPositive:
                                              summaries[index].trend >= 0,
                                          isHighlighted: index == 0,
                                          onTap: () =>
                                              Navigator.of(context).pushNamed(
                                            RouteNames.studentSubjectGrades,
                                            arguments: {
                                              'subjectId':
                                                  summaries[index].subjectId,
                                              'subjectName':
                                                  summaries[index].subjectName,
                                            },
                                          ),
                                        ),
                                        if (index < summaries.length - 1)
                                          AppSpacing.gapSm,
                                      ],
                                      AppSpacing.gapXl,
                                    ],
                                  ),
                                ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

List<_SubjectSummary> _summariesFromGrades(List<GradeModel> grades) {
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

  return summaries;
}

double _overallAverage(List<_SubjectSummary> summaries) {
  if (summaries.isEmpty) return 0;
  return summaries.map((summary) => summary.average).reduce((a, b) => a + b) /
      summaries.length;
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
  return AppColors.subjectColor(subjectName);
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
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.borderLg,
        child: Container(
          padding: AppSpacing.paddingMd,
          decoration: BoxDecoration(
            color: isHighlighted
                ? theme.colorScheme.primary
                : theme.colorScheme.surface,
            borderRadius: AppRadius.borderLg,
            boxShadow: AppShadows.subtle(theme.shadowColor),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isHighlighted
                      ? theme.colorScheme.onPrimary.withAlpha(40)
                      : iconBgColor.withAlpha(20),
                  borderRadius: AppRadius.borderMd,
                ),
                child: Icon(
                  icon,
                  color: isHighlighted
                      ? theme.colorScheme.onPrimary
                      : iconBgColor,
                  size: 22,
                ),
              ),
              AppSpacing.hGapMd,
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
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                    AppSpacing.gapXxs,
                    Text(
                      detail,
                      style: TextStyle(
                        fontSize: 11,
                        color: isHighlighted
                            ? theme.colorScheme.onPrimary.withAlpha(180)
                            : theme.colorScheme.onSurfaceVariant,
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
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                  AppSpacing.gapXxs,
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPositive
                            ? Icons.trending_up_rounded
                            : Icons.trending_down_rounded,
                        size: 14,
                        color: isHighlighted
                            ? theme.colorScheme.onPrimary.withAlpha(180)
                            : isPositive
                                ? AppColors.success
                                : AppColors.danger,
                      ),
                      AppSpacing.hGapXs,
                      Text(
                        change,
                        style: TextStyle(
                          fontSize: 11,
                          color: isHighlighted
                              ? theme.colorScheme.onPrimary.withAlpha(180)
                              : isPositive
                                  ? AppColors.success
                                  : AppColors.danger,
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
