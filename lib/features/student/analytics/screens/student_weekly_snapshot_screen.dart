import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/branded_refresh.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../../shared/widgets/student_page_background.dart';
import '../cubit/weekly_snapshot_cubit.dart';
import '../cubit/weekly_snapshot_state.dart';
import '../repositories/student_analytics_repository.dart';
import '../widgets/student_insight_cards.dart';
import '../widgets/student_semantic_colors.dart';

class StudentWeeklySnapshotScreen extends StatelessWidget {
  const StudentWeeklySnapshotScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          WeeklySnapshotCubit(sl<StudentAnalyticsRepository>())..loadIfNeeded(),
      child: const _StudentWeeklySnapshotView(),
    );
  }
}

class _StudentWeeklySnapshotView extends StatelessWidget {
  const _StudentWeeklySnapshotView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Weekly Snapshot')),
      body: StudentPageBackground(
        child: BlocBuilder<WeeklySnapshotCubit, WeeklySnapshotState>(
          builder: (context, state) {
            if (state.status == WeeklySnapshotStatus.loading ||
                state.status == WeeklySnapshotStatus.initial) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: ShimmerList(),
              );
            }

            if (state.status == WeeklySnapshotStatus.error ||
                state.snapshot == null) {
              return AppErrorWidget(
                message:
                    state.errorMessage ?? 'Unable to load weekly snapshot.',
                onRetry: () =>
                    context.read<WeeklySnapshotCubit>().loadSnapshot(),
              );
            }

            final snapshot = state.snapshot!;

            return BrandedRefreshIndicator(
              onRefresh: () =>
                  context.read<WeeklySnapshotCubit>().loadSnapshot(),
              child: ListView(
                padding: const EdgeInsets.all(16),
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  InsightMetricCard(
                    title: 'Attendance',
                    value: '${(snapshot.attendanceRate * 100).round()}%',
                    subtitle: 'This week',
                    icon: Icons.event_available_rounded,
                    accent: StudentSemanticColors.info,
                  ),
                  AppSpacing.gapSm,
                  InsightMetricCard(
                    title: 'Average Quiz Score',
                    value: '${snapshot.averageQuizScore.round()}%',
                    subtitle: 'This week',
                    icon: Icons.quiz_rounded,
                    accent: StudentSemanticColors.success,
                  ),
                  AppSpacing.gapSm,
                  InsightMetricCard(
                    title: 'Assignments Due',
                    value: '${snapshot.dueAssignments}',
                    subtitle: 'Due soon',
                    icon: Icons.assignment_late_rounded,
                    accent: StudentSemanticColors.warning,
                  ),
                  AppSpacing.gapMd,
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: AppRadius.borderLg,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Summary',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        AppSpacing.gapXs,
                        Text(snapshot.summary),
                        AppSpacing.gapSm,
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: snapshot.focusSubjects
                              .map(
                                (s) => Chip(
                                  label: Text(s),
                                  visualDensity: VisualDensity.compact,
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
