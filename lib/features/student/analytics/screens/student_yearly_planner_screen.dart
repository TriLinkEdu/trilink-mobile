import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/models/student_goal_model.dart';
import '../../../../core/routes/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/branded_refresh.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/widgets/illustrations.dart';
import '../../../../core/widgets/pressable.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../../shared/widgets/student_page_background.dart';
import '../cubit/yearly_planner_cubit.dart';
import '../cubit/yearly_planner_state.dart';
import '../repositories/student_analytics_repository.dart';

class StudentYearlyPlannerScreen extends StatelessWidget {
  const StudentYearlyPlannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => YearlyPlannerCubit(
        analyticsRepository: sl<StudentAnalyticsRepository>(),
      )..loadPlanner(),
      child: const _YearlyPlannerView(),
    );
  }
}

class _YearlyPlannerView extends StatelessWidget {
  const _YearlyPlannerView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Yearly Planner'),
        actions: [
          IconButton(
            tooltip: 'My Goals',
            onPressed: () =>
                Navigator.of(context).pushNamed(RouteNames.studentGoals),
            icon: const Icon(Icons.flag_rounded),
          ),
        ],
      ),
      body: StudentPageBackground(
        child: BlocBuilder<YearlyPlannerCubit, YearlyPlannerState>(
          builder: (context, state) {
            if (state.status == YearlyPlannerStatus.loading ||
                state.status == YearlyPlannerStatus.initial) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: ShimmerList(itemCount: 4, itemHeight: 120),
              );
            }

            if (state.status == YearlyPlannerStatus.error) {
              return AppErrorWidget(
                message: state.errorMessage ?? 'Unable to load planner.',
                onRetry: () =>
                    context.read<YearlyPlannerCubit>().loadPlanner(),
              );
            }

            return BrandedRefreshIndicator(
              onRefresh: () =>
                  context.read<YearlyPlannerCubit>().loadPlanner(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  // ── Year Overview Card ──
                  _YearOverviewCard(
                    year: state.academicYear,
                    overallScore: state.overallScore,
                    attendanceRate: state.attendanceRate,
                    totalXp: state.totalXp,
                    goalsCompleted: state.goalsCompleted,
                    goalsTotal: state.goalsTotal,
                  ),
                  AppSpacing.gapXl,

                  // ── Term Cards ──
                  Text(
                    'Term Progress',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  AppSpacing.gapMd,
                  ...state.terms.asMap().entries.map((entry) {
                    final index = entry.key;
                    final term = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _TermCard(
                        term: term,
                        isCurrentTerm: index == state.currentTermIndex,
                      ),
                    );
                  }),
                  AppSpacing.gapXl,

                  // ── Goals by Term ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Academic Goals',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => Navigator.of(context)
                            .pushNamed(RouteNames.studentGoals),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add Goal'),
                      ),
                    ],
                  ),
                  AppSpacing.gapSm,
                  if (state.activeGoals.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 20),
                      child: EmptyStateWidget(
                        illustration: GraduationCapIllustration(),
                        icon: Icons.flag_outlined,
                        title: 'No active goals',
                        subtitle:
                            'Set academic targets to track your yearly progress.',
                      ),
                    )
                  else
                    ...state.activeGoals.map(
                      (goal) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _GoalCard(goal: goal),
                      ),
                    ),

                  AppSpacing.gapXl,

                  // ── Quick Navigation ──
                  Text(
                    'Insights & Plans',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  AppSpacing.gapMd,
                  _InsightNavigationCard(
                    icon: Icons.task_alt_rounded,
                    title: 'Action Plan',
                    subtitle: 'Focused daily tasks for improvement',
                    color: AppColors.secondary,
                    onTap: () => Navigator.of(context)
                        .pushNamed(RouteNames.studentActionPlan),
                  ),
                  AppSpacing.gapSm,
                  _InsightNavigationCard(
                    icon: Icons.trending_up_rounded,
                    title: 'Performance Trends',
                    subtitle: 'Subject-level exam readiness',
                    color: Colors.deepPurple,
                    onTap: () => Navigator.of(context)
                        .pushNamed(RouteNames.studentPerformanceTrends),
                  ),
                  AppSpacing.gapSm,
                  _InsightNavigationCard(
                    icon: Icons.insights_rounded,
                    title: 'Attendance Insights',
                    subtitle: 'Weekly patterns and risk analysis',
                    color: Colors.teal,
                    onTap: () => Navigator.of(context)
                        .pushNamed(RouteNames.studentAttendanceInsights),
                  ),
                  AppSpacing.gapXxl,
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ── Year Overview Card ──

class _YearOverviewCard extends StatelessWidget {
  final String year;
  final double overallScore;
  final double attendanceRate;
  final int totalXp;
  final int goalsCompleted;
  final int goalsTotal;

  const _YearOverviewCard({
    required this.year,
    required this.overallScore,
    required this.attendanceRate,
    required this.totalXp,
    required this.goalsCompleted,
    required this.goalsTotal,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final goalProgress = goalsTotal > 0 ? goalsCompleted / goalsTotal : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withAlpha(200),
            theme.colorScheme.tertiary,
          ],
        ),
        borderRadius: AppRadius.borderXl,
        boxShadow: AppShadows.glow(theme.colorScheme.primary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.calendar_today_rounded,
                color: theme.colorScheme.onPrimary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Academic Year $year',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _OverviewStat(
                  label: 'Avg Score',
                  value: '${overallScore.round()}%',
                  icon: Icons.grade_rounded,
                ),
              ),
              Expanded(
                child: _OverviewStat(
                  label: 'Attendance',
                  value: '${(attendanceRate * 100).round()}%',
                  icon: Icons.event_available_rounded,
                ),
              ),
              Expanded(
                child: _OverviewStat(
                  label: 'XP Earned',
                  value: '$totalXp',
                  icon: Icons.star_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Goal progress bar
          Row(
            children: [
              Icon(
                Icons.flag_rounded,
                size: 16,
                color: theme.colorScheme.onPrimary.withAlpha(200),
              ),
              const SizedBox(width: 6),
              Text(
                'Goals: $goalsCompleted / $goalsTotal completed',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onPrimary.withAlpha(200),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: goalProgress,
              backgroundColor: theme.colorScheme.onPrimary.withAlpha(50),
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.onPrimary,
              ),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _OverviewStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onPrimary = theme.colorScheme.onPrimary;

    return Column(
      children: [
        Icon(icon, color: onPrimary.withAlpha(180), size: 20),
        const SizedBox(height: 6),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            color: onPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: onPrimary.withAlpha(180),
          ),
        ),
      ],
    );
  }
}

// ── Term Card ──

class _TermCard extends StatelessWidget {
  final TermProgress term;
  final bool isCurrentTerm;

  const _TermCard({
    required this.term,
    required this.isCurrentTerm,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ext = theme.ext;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCurrentTerm
            ? theme.colorScheme.primaryContainer.withAlpha(60)
            : ext.cardBackground,
        borderRadius: AppRadius.borderLg,
        border: Border.all(
          color: isCurrentTerm
              ? theme.colorScheme.primary.withAlpha(100)
              : ext.cardBorder,
          width: isCurrentTerm ? 1.5 : 0.5,
        ),
        boxShadow: AppShadows.subtle(theme.shadowColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (isCurrentTerm)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: AppRadius.borderFull,
                  ),
                  child: Text(
                    'CURRENT',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 9,
                    ),
                  ),
                ),
              Text(
                term.name,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                term.dateRange,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _TermStat(
                label: 'Score',
                value: '${term.avgScore.round()}%',
                color: _scoreColor(term.avgScore),
              ),
              const SizedBox(width: 16),
              _TermStat(
                label: 'Attendance',
                value: '${(term.attendanceRate * 100).round()}%',
                color: _scoreColor(term.attendanceRate * 100),
              ),
              const SizedBox(width: 16),
              _TermStat(
                label: 'Goals',
                value: '${term.goalsHit} / ${term.goalsTotal}',
                color: theme.colorScheme.primary,
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: term.avgScore / 100,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(
                _scoreColor(term.avgScore),
              ),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }

  Color _scoreColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }
}

class _TermStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _TermStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

// ── Goal Card ──

class _GoalCard extends StatelessWidget {
  final StudentGoalModel goal;

  const _GoalCard({required this.goal});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOverdue = goal.isOverdue;
    final daysRemaining = goal.daysRemaining;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppRadius.borderLg,
        border: Border.all(
          color: isOverdue
              ? Colors.red.withAlpha(80)
              : theme.colorScheme.outlineVariant.withAlpha(60),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: (isOverdue ? Colors.red : theme.colorScheme.primary)
                  .withAlpha(20),
              borderRadius: AppRadius.borderMd,
            ),
            child: Icon(
              goal.isAchieved
                  ? Icons.check_circle_rounded
                  : isOverdue
                      ? Icons.warning_amber_rounded
                      : Icons.flag_rounded,
              color: goal.isAchieved
                  ? Colors.green
                  : isOverdue
                      ? Colors.red
                      : theme.colorScheme.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  goal.goalText,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    decoration:
                        goal.isAchieved ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 4),
                if (daysRemaining != null)
                  Text(
                    isOverdue
                        ? 'Overdue by ${daysRemaining.abs()} days'
                        : '$daysRemaining days remaining',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isOverdue
                          ? Colors.red
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  )
                else
                  Text(
                    'No deadline set',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Insight Navigation Card ──

class _InsightNavigationCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _InsightNavigationCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: AppRadius.borderLg,
          boxShadow: AppShadows.subtle(theme.shadowColor),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withAlpha(18),
                borderRadius: AppRadius.borderMd,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
