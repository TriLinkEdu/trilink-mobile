import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trilink_mobile/core/widgets/branded_refresh.dart';
import 'package:trilink_mobile/core/widgets/empty_state_widget.dart';
import 'package:trilink_mobile/core/widgets/error_widget.dart';
import 'package:trilink_mobile/core/widgets/illustrations.dart';
import 'package:trilink_mobile/core/widgets/pressable.dart';
import 'package:trilink_mobile/core/widgets/staggered_animation.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/routes/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../cubit/exam_list_cubit.dart';
import '../models/exam_model.dart';
import '../repositories/student_exams_repository.dart';

class StudentExamsScreen extends StatelessWidget {
  const StudentExamsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ExamListCubit(sl<StudentExamsRepository>())..loadExams(),
      child: const _StudentExamsView(),
    );
  }
}

class _StudentExamsView extends StatelessWidget {
  const _StudentExamsView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ExamListCubit, ExamListState>(
      builder: (context, state) {
        final loading =
            state.status == ExamListStatus.loading ||
            state.status == ExamListStatus.initial;

        return Scaffold(
          appBar: AppBar(title: const Text('Exams')),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: Theme.of(context).brightness == Brightness.dark
                    ? const [Color(0xFF0A1525), Color(0xFF0F2338)]
                    : const [Color(0xFFF0F8FF), Color(0xFFE6F4FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: loading
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: ShimmerList(itemHeight: 120),
                  )
                : BrandedRefreshIndicator(
                    onRefresh: () => context.read<ExamListCubit>().loadExams(),
                    child: state.status == ExamListStatus.error
                        ? LayoutBuilder(
                            builder: (context, constraints) {
                              return SingleChildScrollView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    minHeight: constraints.maxHeight,
                                  ),
                                  child: AppErrorWidget(
                                    message:
                                        state.errorMessage ??
                                        'Unable to load exams.',
                                    onRetry: () => context
                                        .read<ExamListCubit>()
                                        .loadExams(),
                                  ),
                                ),
                              );
                            },
                          )
                        : state.exams.isEmpty
                        ? LayoutBuilder(
                            builder: (context, constraints) {
                              return SingleChildScrollView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    minHeight: constraints.maxHeight,
                                  ),
                                  child: const EmptyStateWidget(
                                    illustration: GraduationCapIllustration(),
                                    icon: Icons.quiz_rounded,
                                    title: 'No exams available',
                                    subtitle:
                                        'Scheduled exams will appear here.',
                                  ),
                                ),
                              );
                            },
                          )
                        : ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(16),
                            itemCount: state.exams.length,
                            separatorBuilder: (_, _) => AppSpacing.gapMd,
                            itemBuilder: (context, index) {
                              return StaggeredFadeSlide(
                                index: index,
                                child: _ExamCard(exam: state.exams[index]),
                              );
                            },
                          ),
                  ),
          ),
        );
      },
    );
  }
}

// ── Exam Card ──

class _ExamCard extends StatelessWidget {
  final ExamModel exam;
  const _ExamCard({required this.exam});

  Color _lifecycleColor(ExamLifecycleState lifecycle) {
    switch (lifecycle) {
      case ExamLifecycleState.draft:
        return AppColors.warning;
      case ExamLifecycleState.published:
        return AppColors.info;
      case ExamLifecycleState.active:
        return AppColors.success;
      case ExamLifecycleState.completed:
        return AppColors.secondary;
      case ExamLifecycleState.archived:
        return AppColors.darkSurfaceBright;
    }
  }

  String _lifecycleLabel(ExamLifecycleState lifecycle) {
    switch (lifecycle) {
      case ExamLifecycleState.draft:
        return 'Draft';
      case ExamLifecycleState.published:
        return 'Upcoming';
      case ExamLifecycleState.active:
        return 'Active';
      case ExamLifecycleState.completed:
        return 'Completed';
      case ExamLifecycleState.archived:
        return 'Archived';
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Not scheduled';
    final months = [
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

  void _onTap(BuildContext context) {
    if (!exam.canAttempt && !exam.isCompleted) return;
    Navigator.of(
      context,
    ).pushNamed(RouteNames.studentExamAttempt, arguments: {'examId': exam.id});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final lifecycle = exam.lifecycleState;
    final color = _lifecycleColor(lifecycle);
    final enabled = exam.canAttempt || exam.isCompleted;

    return Pressable(
      onTap: enabled ? () => _onTap(context) : null,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.55,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark
                ? theme.colorScheme.surfaceContainerHigh
                : theme.colorScheme.surface,
            borderRadius: AppRadius.borderLg,
            border: Border.all(
              color: isDark
                  ? Colors.white.withAlpha(12)
                  : Colors.black.withAlpha(8),
            ),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withAlpha(8),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: color.withAlpha(24),
                      borderRadius: AppRadius.borderSm,
                    ),
                    child: Icon(Icons.quiz_rounded, color: color, size: 21),
                  ),
                  AppSpacing.hGapMd,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exam.title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        AppSpacing.gapXxs,
                        Text(
                          exam.subjectName,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _LifecycleChip(
                    label: _lifecycleLabel(lifecycle),
                    color: color,
                  ),
                ],
              ),
              AppSpacing.gapMd,
              Row(
                children: [
                  _InfoTag(
                    icon: Icons.access_time_rounded,
                    label: '${exam.durationMinutes} min',
                  ),
                  AppSpacing.hGapMd,
                  _InfoTag(
                    icon: Icons.help_outline_rounded,
                    label: '${exam.questions.length} questions',
                  ),
                  AppSpacing.hGapMd,
                  _InfoTag(
                    icon: Icons.calendar_today_rounded,
                    label: _formatDate(exam.scheduledAt),
                  ),
                ],
              ),
              AppSpacing.gapMd,
              if (exam.isCompleted && exam.score != null)
                _CompletedBanner(score: exam.score!)
              else if (exam.canAttempt)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => _onTap(context),
                    icon: const Icon(Icons.play_arrow_rounded, size: 18),
                    label: const Text('Start Exam'),
                  ),
                )
              else
                Text(
                  lifecycle == ExamLifecycleState.draft
                      ? 'This exam is still being prepared.'
                      : 'This exam is no longer available.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Lifecycle Chip ──

class _LifecycleChip extends StatelessWidget {
  final String label;
  final Color color;
  const _LifecycleChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: AppRadius.borderFull,
        border: Border.all(color: color.withAlpha(46)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

// ── Info Tag ──

class _InfoTag extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoTag({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ── Completed Banner ──

class _CompletedBanner extends StatelessWidget {
  final double score;
  const _CompletedBanner({required this.score});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final passed = score >= 50;
    final color = passed ? AppColors.success : AppColors.danger;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withAlpha(16),
        borderRadius: AppRadius.borderSm,
        border: Border.all(color: color.withAlpha(34)),
      ),
      child: Row(
        children: [
          Icon(
            passed ? Icons.check_circle_rounded : Icons.cancel_rounded,
            size: 18,
            color: color,
          ),
          AppSpacing.hGapSm,
          Text(
            'Score: ${score.toStringAsFixed(0)}%',
            style: theme.textTheme.labelLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Text(
            'Review',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 2),
          Icon(
            Icons.chevron_right_rounded,
            size: 16,
            color: theme.colorScheme.primary,
          ),
        ],
      ),
    );
  }
}
