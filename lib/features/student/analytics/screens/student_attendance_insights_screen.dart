import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../../shared/widgets/student_page_background.dart';
import '../cubit/attendance_insights_cubit.dart';
import '../cubit/attendance_insights_state.dart';
import '../repositories/student_analytics_repository.dart';
import '../widgets/student_insight_cards.dart';

class StudentAttendanceInsightsScreen extends StatelessWidget {
  const StudentAttendanceInsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          AttendanceInsightsCubit(sl<StudentAnalyticsRepository>())
            ..loadInsights(),
      child: const _StudentAttendanceInsightsView(),
    );
  }
}

class _StudentAttendanceInsightsView extends StatelessWidget {
  const _StudentAttendanceInsightsView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Attendance Insights')),
      body: StudentPageBackground(
        child: BlocBuilder<AttendanceInsightsCubit, AttendanceInsightsState>(
          builder: (context, state) {
            if (state.status == AttendanceInsightsStatus.initial ||
                state.status == AttendanceInsightsStatus.loading) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: ShimmerList(),
              );
            }

            if (state.status == AttendanceInsightsStatus.error ||
                state.insight == null) {
              return AppErrorWidget(
                message:
                    state.errorMessage ?? 'Unable to load attendance insights.',
                onRetry: () =>
                    context.read<AttendanceInsightsCubit>().loadInsights(),
              );
            }

            final insight = state.insight!;

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                InsightMetricCard(
                  title: 'Current Attendance',
                  value: '${(insight.currentRate * 100).round()}%',
                  subtitle: 'Current month',
                  icon: Icons.event_available_rounded,
                  accent: theme.colorScheme.primary,
                ),
                AppSpacing.gapSm,
                Align(
                  alignment: Alignment.centerLeft,
                  child: RiskBadge(
                    label: '${insight.riskLevel} risk',
                    color: insight.riskLevel.toLowerCase() == 'low'
                        ? Colors.green
                        : insight.riskLevel.toLowerCase() == 'medium'
                        ? Colors.orange
                        : Colors.red,
                  ),
                ),
                AppSpacing.gapSm,
                _InsightRow(
                  label: 'Projected Month End',
                  value: '${(insight.projectedMonthEndRate * 100).round()}%',
                ),
                _InsightRow(label: 'Best Day', value: insight.bestDay),
                _InsightRow(label: 'Weak Day', value: insight.weakDay),
                AppSpacing.gapMd,
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: AppRadius.borderLg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Weekly Trend',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      AppSpacing.gapSm,
                      ...insight.weeklyTrend.map(
                        (point) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(point.label),
                              Text('${point.value.round()}%'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _InsightRow extends StatelessWidget {
  final String label;
  final String value;

  const _InsightRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppRadius.borderLg,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyMedium),
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
