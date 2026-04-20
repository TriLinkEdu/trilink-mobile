import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/routes/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import 'package:trilink_mobile/core/widgets/branded_refresh.dart';
import 'package:trilink_mobile/core/widgets/empty_state_widget.dart';
import 'package:trilink_mobile/core/widgets/illustrations.dart';
import 'package:trilink_mobile/core/widgets/error_widget.dart';
import 'package:trilink_mobile/core/widgets/staggered_animation.dart';
import 'package:trilink_mobile/core/widgets/pressable.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../../shared/widgets/student_page_background.dart';
import '../cubit/assignments_cubit.dart';
import '../models/assignment_model.dart';
import '../repositories/student_assignments_repository.dart';

class StudentAssignmentsScreen extends StatelessWidget {
  const StudentAssignmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          AssignmentsCubit(sl<StudentAssignmentsRepository>())..loadIfNeeded(),
      child: const _StudentAssignmentsView(),
    );
  }
}

class _StudentAssignmentsView extends StatelessWidget {
  const _StudentAssignmentsView();

  Color _statusColor(AssignmentStatus status) {
    switch (status) {
      case AssignmentStatus.pending:
        return AppColors.warning;
      case AssignmentStatus.submitted:
        return AppColors.info;
      case AssignmentStatus.graded:
        return AppColors.success;
      case AssignmentStatus.overdue:
        return AppColors.danger;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AssignmentsCubit, AssignmentsState>(
      builder: (context, state) {
        final loading =
            state.status == AssignmentsStatus.loading ||
            state.status == AssignmentsStatus.initial;
        return Scaffold(
          appBar: AppBar(title: const Text('Assignments')),
          body: StudentPageBackground(
            child: loading
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: ShimmerList(),
                  )
                : BrandedRefreshIndicator(
                    onRefresh: () =>
                        context.read<AssignmentsCubit>().loadAssignments(),
                    child: state.status == AssignmentsStatus.error
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
                                        'Unable to load assignments.',
                                    onRetry: () => context
                                        .read<AssignmentsCubit>()
                                        .loadAssignments(),
                                  ),
                                ),
                              );
                            },
                          )
                        : state.assignments.isEmpty
                        ? LayoutBuilder(
                            builder: (context, constraints) {
                              return SingleChildScrollView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    minHeight: constraints.maxHeight,
                                  ),
                                  child: const EmptyStateWidget(
                                    illustration: EmptyBoxIllustration(),
                                    icon: Icons.assignment_turned_in_rounded,
                                    title: 'No assignments',
                                    subtitle:
                                        'Assignments will appear here when available.',
                                  ),
                                ),
                              );
                            },
                          )
                        : ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(16),
                            itemCount: state.assignments.length,
                            separatorBuilder: (_, _) => AppSpacing.gapMd,
                            itemBuilder: (context, index) {
                              final assignment = state.assignments[index];
                              Future<void> openDetail() async {
                                final result = await Navigator.pushNamed(
                                  context,
                                  RouteNames.studentAssignmentDetail,
                                  arguments: {'assignmentId': assignment.id},
                                );
                                if (result == true && context.mounted) {
                                  context
                                      .read<AssignmentsCubit>()
                                      .loadAssignments();
                                }
                              }

                              return StaggeredFadeSlide(
                                index: index,
                                child: Pressable(
                                  onTap: openDetail,
                                  enableHaptic: false,
                                  child: Card(
                                    child: ListTile(
                                      onTap: openDetail,
                                      contentPadding: const EdgeInsets.all(16),
                                      title: Text(
                                        assignment.title,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                      subtitle: Padding(
                                        padding: const EdgeInsets.only(top: 6),
                                        child: Text(
                                          '${assignment.subject} • ${assignment.dueDateLabel}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.onSurfaceVariant,
                                                height: 1.3,
                                              ),
                                        ),
                                      ),
                                      trailing: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _statusColor(
                                            assignment.status,
                                          ).withAlpha(22),
                                          borderRadius: AppRadius.borderSm,
                                          border: Border.all(
                                            color: _statusColor(
                                              assignment.status,
                                            ).withAlpha(36),
                                          ),
                                        ),
                                        child: Text(
                                          assignment.statusLabel,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: _statusColor(
                                                  assignment.status,
                                                ),
                                                fontWeight: FontWeight.w700,
                                                letterSpacing: 0.2,
                                              ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
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
