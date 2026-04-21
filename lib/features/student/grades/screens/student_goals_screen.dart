import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/branded_refresh.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/widgets/illustrations.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../../shared/widgets/student_page_background.dart';
import '../../../auth/cubit/auth_cubit.dart';
import '../cubit/student_goals_cubit.dart';
import '../cubit/student_goals_state.dart';
import '../repositories/student_performance_repository.dart';

class StudentGoalsScreen extends StatelessWidget {
  const StudentGoalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final studentId = context.read<AuthCubit>().currentUser?.id ?? '';
    return BlocProvider(
      create: (_) =>
          StudentGoalsCubit(sl<StudentPerformanceRepository>())
            ..loadIfNeeded(studentId),
      child: _StudentGoalsView(studentId: studentId),
    );
  }
}

class _StudentGoalsView extends StatefulWidget {
  final String studentId;

  const _StudentGoalsView({required this.studentId});

  @override
  State<_StudentGoalsView> createState() => _StudentGoalsViewState();
}

class _StudentGoalsViewState extends State<_StudentGoalsView> {
  final _goalController = TextEditingController();

  @override
  void dispose() {
    _goalController.dispose();
    super.dispose();
  }

  Future<void> _showCreateGoalDialog() async {
    final goalsCubit = context.read<StudentGoalsCubit>();
    DateTime? selectedDate;

    await showDialog<void>(
      context: context,
      useRootNavigator: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('New Goal'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _goalController,
                    minLines: 1,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Goal description',
                      hintText: 'e.g. Improve physics score to 80% this month',
                    ),
                  ),
                  AppSpacing.gapMd,
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          selectedDate == null
                              ? 'No target date'
                              : 'Target: ${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}',
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            firstDate: DateTime.now().subtract(
                              const Duration(days: 1),
                            ),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365 * 2),
                            ),
                            initialDate: selectedDate ?? DateTime.now(),
                          );
                          if (picked == null) return;
                          setDialogState(() => selectedDate = picked);
                        },
                        child: const Text('Set date'),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: goalsCubit.state.isSaving
                      ? null
                      : () async {
                          FocusScope.of(dialogContext).unfocus();
                          final text = _goalController.text.trim();
                          if (text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Please enter a goal before saving.',
                                ),
                              ),
                            );
                            return;
                          }

                          final navigator = Navigator.of(dialogContext);
                          navigator.pop();
                          _goalController.clear();

                          await goalsCubit.createGoal(
                            studentId: widget.studentId,
                            text: text,
                            targetDate: selectedDate,
                          );
                        },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Goals & Progress'),
        actions: [
          IconButton(
            tooltip: 'Add goal',
            onPressed: _showCreateGoalDialog,
            icon: const Icon(Icons.add_task_rounded),
          ),
        ],
      ),
      body: StudentPageBackground(
        child: BlocConsumer<StudentGoalsCubit, StudentGoalsState>(
          listener: (context, state) {
            if (state.errorMessage != null && state.errorMessage!.isNotEmpty) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
            }
          },
          builder: (context, state) {
            if (state.status == StudentGoalsStatus.initial ||
                state.status == StudentGoalsStatus.loading) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: ShimmerList(),
              );
            }

            if (state.status == StudentGoalsStatus.error) {
              return AppErrorWidget(
                message: state.errorMessage ?? 'Unable to load goals.',
                onRetry: () =>
                    context.read<StudentGoalsCubit>().load(widget.studentId),
              );
            }

            return BrandedRefreshIndicator(
              onRefresh: () =>
                  context.read<StudentGoalsCubit>().load(widget.studentId),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  if (state.report != null) ...[
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
                            'Latest Performance',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          AppSpacing.gapXs,
                          Text(
                            'Overall score: ${state.report!.overallScore.toStringAsFixed(1)}% (${state.report!.scoreLabel})',
                          ),
                          if (state.report!.recommendations.isNotEmpty) ...[
                            AppSpacing.gapSm,
                            Text(
                              state.report!.recommendations.first,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    AppSpacing.gapMd,
                  ],
                  if (state.mastery.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: AppRadius.borderLg,
                      ),
                      child: Text(
                        'Mastery topics loaded: ${state.mastery.length}',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  if (state.mastery.isNotEmpty) AppSpacing.gapMd,
                  if (state.goals.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 40),
                      child: EmptyStateWidget(
                        illustration: GraduationCapIllustration(),
                        icon: Icons.flag_outlined,
                        title: 'No goals yet',
                        subtitle:
                            'Create your first learning goal to track progress.',
                      ),
                    )
                  else
                    ...state.goals.map(
                      (goal) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: AppRadius.borderLg,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Checkbox(
                                value: goal.isAchieved,
                                onChanged: state.isSaving
                                    ? null
                                    : (_) => context
                                          .read<StudentGoalsCubit>()
                                          .toggleGoalCompletion(goal),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      goal.goalText,
                                      style: theme.textTheme.titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                            decoration: goal.isAchieved
                                                ? TextDecoration.lineThrough
                                                : null,
                                          ),
                                    ),
                                    AppSpacing.gapXxs,
                                    Text(
                                      goal.targetDate == null
                                          ? 'No deadline'
                                          : 'Target: ${goal.targetDate!.year}-${goal.targetDate!.month.toString().padLeft(2, '0')}-${goal.targetDate!.day.toString().padLeft(2, '0')}',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: theme
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  AppSpacing.gapXl,
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateGoalDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Goal'),
      ),
    );
  }
}
