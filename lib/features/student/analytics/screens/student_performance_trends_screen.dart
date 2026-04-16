import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/branded_refresh.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../../shared/widgets/student_page_background.dart';
import '../cubit/performance_trends_cubit.dart';
import '../cubit/performance_trends_state.dart';
import '../repositories/student_analytics_repository.dart';
import '../widgets/student_insight_cards.dart';
import '../widgets/student_semantic_colors.dart';

class StudentPerformanceTrendsScreen extends StatelessWidget {
  const StudentPerformanceTrendsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          PerformanceTrendsCubit(sl<StudentAnalyticsRepository>())
            ..loadTrends(),
      child: const _StudentPerformanceTrendsView(),
    );
  }
}

class _StudentPerformanceTrendsView extends StatelessWidget {
  const _StudentPerformanceTrendsView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Performance Trends')),
      body: StudentPageBackground(
        child: BlocBuilder<PerformanceTrendsCubit, PerformanceTrendsState>(
          builder: (context, state) {
            if (state.status == PerformanceTrendsStatus.loading ||
                state.status == PerformanceTrendsStatus.initial) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: ShimmerList(),
              );
            }

            if (state.status == PerformanceTrendsStatus.error ||
                state.trends == null) {
              return AppErrorWidget(
                message:
                    state.errorMessage ?? 'Unable to load performance trends.',
                onRetry: () => context.read<PerformanceTrendsCubit>().loadTrends(),
              );
            }

            final trends = state.trends!;

            return BrandedRefreshIndicator(
              onRefresh: () => context.read<PerformanceTrendsCubit>().loadTrends(),
              child: ListView(
                padding: const EdgeInsets.all(16),
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  InsightMetricCard(
                    title: 'Exam Readiness',
                    value: '${trends.examReadinessScore} / 100',
                    subtitle: 'Estimated from recent trends',
                    icon: Icons.analytics_rounded,
                    accent: StudentSemanticColors.info,
                  ),
                  AppSpacing.gapMd,
                  ...trends.subjects.map(
                    (subject) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: AppRadius.borderLg,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              subject.subjectName,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            AppSpacing.gapXs,
                            Text(
                              subject.recommendation,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
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