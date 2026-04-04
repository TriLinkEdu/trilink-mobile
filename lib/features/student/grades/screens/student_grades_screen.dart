import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/routes/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import 'package:trilink_mobile/core/widgets/empty_state_widget.dart';
import 'package:trilink_mobile/core/widgets/illustrations.dart';
import 'package:trilink_mobile/core/widgets/error_widget.dart';
import 'package:trilink_mobile/core/widgets/animated_counter.dart';
import 'package:trilink_mobile/core/widgets/branded_refresh.dart';
import 'package:trilink_mobile/core/widgets/celebration_overlay.dart';
import 'package:trilink_mobile/core/widgets/staggered_animation.dart';
import 'package:trilink_mobile/core/widgets/pressable.dart';
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

class _GradesView extends StatefulWidget {
  const _GradesView();

  @override
  State<_GradesView> createState() => _GradesViewState();
}

class _GradesViewState extends State<_GradesView> {
  static final _celebratedKeys = <String>{};

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GradesCubit, GradesState>(
      builder: (context, state) {
        final theme = Theme.of(context);
        final summaries = _summariesFromGrades(state.grades);
        final overallAverage = _overallAverage(summaries);
        final isLoading =
            state.status == GradesStatus.initial ||
            state.status == GradesStatus.loading;

        final loadedOk =
            !isLoading &&
            state.status != GradesStatus.error &&
            summaries.isNotEmpty;
        const key = 'high_average';
        if (loadedOk &&
            overallAverage >= 90 &&
            !_celebratedKeys.contains(key)) {
          _celebratedKeys.add(key);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            CelebrationOverlay.maybeOf(context)?.celebrate(
              type: CelebrationType.grade,
              message: 'Outstanding average!',
              subtext:
                  '${overallAverage.toStringAsFixed(0)}% across your subjects',
            );
          });
        }

        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: theme.brightness == Brightness.dark
                    ? const [Color(0xFF0A1526), Color(0xFF10263D)]
                    : const [Color(0xFFF0F8FF), Color(0xFFE6F4FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.only(
                      right: AppSpacing.md,
                      top: AppSpacing.xs,
                    ),
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
                        ? AppErrorWidget(
                            message: 'Unable to load grades right now.',
                            onRetry: () =>
                                context.read<GradesCubit>().loadGrades(),
                          )
                        : summaries.isEmpty
                        ? BrandedRefreshIndicator(
                            onRefresh: () =>
                                context.read<GradesCubit>().loadGrades(),
                            child: LayoutBuilder(
                              builder: (context, constraints) =>
                                  SingleChildScrollView(
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(
                                        minHeight: constraints.maxHeight,
                                      ),
                                      child: const EmptyStateWidget(
                                        illustration:
                                            GraduationCapIllustration(),
                                        icon: Icons.school_rounded,
                                        title: 'No grades yet',
                                        subtitle:
                                            'Your academic grades will appear here once teachers post them.',
                                      ),
                                    ),
                                  ),
                            ),
                          )
                        : BrandedRefreshIndicator(
                            onRefresh: () =>
                                context.read<GradesCubit>().loadGrades(),
                            child: SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: AppSpacing.horizontalXl,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 28,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          theme.colorScheme.primary.withAlpha(
                                            26,
                                          ),
                                          AppColors.secondary.withAlpha(18),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: AppRadius.borderXl,
                                      border: Border.all(
                                        color: theme.colorScheme.primary
                                            .withAlpha(32),
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          'Overall Average',
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                                color: theme
                                                    .colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                        ),
                                        AppSpacing.gapSm,
                                        AnimatedCounter(
                                          value: overallAverage,
                                          showTrend: true,
                                          style: theme.textTheme.displayLarge
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color:
                                                    theme.colorScheme.primary,
                                              ),
                                        ),
                                        AppSpacing.gapXs,
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: theme.colorScheme.primary
                                                .withAlpha(24),
                                            borderRadius: AppRadius.borderXl,
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.shield_rounded,
                                                size: 14,
                                                color:
                                                    theme.colorScheme.primary,
                                              ),
                                              AppSpacing.hGapXs,
                                              Text(
                                                'Performance Updated',
                                                style: theme.textTheme.bodySmall
                                                    ?.copyWith(
                                                      color: theme
                                                          .colorScheme
                                                          .primary,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      letterSpacing: 0.2,
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
                                        style: theme.textTheme.titleSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                              color:
                                                  theme.colorScheme.onSurface,
                                            ),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pushNamed(
                                            RouteNames.studentAssignments,
                                          );
                                        },
                                        child: Text(
                                          'Assignments',
                                          style: theme.textTheme.labelLarge
                                              ?.copyWith(
                                                color:
                                                    theme.colorScheme.primary,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  AppSpacing.gapSm,
                                  for (
                                    int index = 0;
                                    index < summaries.length;
                                    index++
                                  ) ...[
                                    StaggeredFadeSlide(
                                      index: index,
                                      child: _SubjectGradeRow(
                                        subjectId: summaries[index].subjectId,
                                        icon: _iconForSubject(
                                          summaries[index].subjectName,
                                        ),
                                        iconBgColor: _colorForSubject(
                                          summaries[index].subjectName,
                                        ),
                                        name: summaries[index].subjectName,
                                        detail:
                                            '${summaries[index].assessmentCount} Assessments',
                                        gradeValue: summaries[index].average,
                                        change: _trendLabel(
                                          summaries[index].trend,
                                        ),
                                        isPositive: summaries[index].trend >= 0,
                                        isHighlighted: index == 0,
                                        onTap: () =>
                                            Navigator.of(context).pushNamed(
                                              RouteNames.studentSubjectGrades,
                                              arguments: {
                                                'subjectId':
                                                    summaries[index].subjectId,
                                                'subjectName': summaries[index]
                                                    .subjectName,
                                                'selectedTerm':
                                                    state.selectedTerm,
                                              },
                                            ),
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
                  ),
                ],
              ),
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
    final subjectGrades = entry.value..sort((a, b) => a.date.compareTo(b.date));
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
  }).toList()..sort((a, b) => b.average.compareTo(a.average));

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
  final String subjectId;
  final IconData icon;
  final Color iconBgColor;
  final String name;
  final String detail;
  final double gradeValue;
  final String change;
  final bool isPositive;
  final bool isHighlighted;
  final VoidCallback onTap;

  const _SubjectGradeRow({
    required this.subjectId,
    required this.icon,
    required this.iconBgColor,
    required this.name,
    required this.detail,
    required this.gradeValue,
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
      child: Pressable(
        onTap: onTap,
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
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isHighlighted
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                    AppSpacing.gapXxs,
                    Text(
                      detail,
                      style: theme.textTheme.labelSmall?.copyWith(
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
                  Hero(
                    tag: 'grade-hero-$subjectId',
                    child: Material(
                      color: Colors.transparent,
                      child: AnimatedCounter(
                        value: gradeValue,
                        showTrend: true,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isHighlighted
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.onSurface,
                        ),
                      ),
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
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.15,
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
