import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/routes/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../cubit/assignments_cubit.dart';
import '../models/assignment_model.dart';
import '../repositories/student_assignments_repository.dart';

class StudentAssignmentsScreen extends StatelessWidget {
  const StudentAssignmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          AssignmentsCubit(sl<StudentAssignmentsRepository>())..loadAssignments(),
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
        return Scaffold(
          appBar: AppBar(title: const Text('Assignments')),
          body: state.status == AssignmentsStatus.loading ||
                  state.status == AssignmentsStatus.initial
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: ShimmerList(),
                )
              : state.status == AssignmentsStatus.error
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            state.errorMessage ?? '',
                            style: const TextStyle(color: AppColors.danger),
                          ),
                          AppSpacing.gapSm,
                          ElevatedButton(
                            onPressed: () => context
                                .read<AssignmentsCubit>()
                                .loadAssignments(),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : state.assignments.isEmpty
                      ? const Center(child: Text('No assignments available.'))
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: state.assignments.length,
                          separatorBuilder: (_, __) =>
                              AppSpacing.gapMd,
                          itemBuilder: (context, index) {
                            final assignment = state.assignments[index];
                            return Card(
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(14),
                                title: Text(
                                  assignment.title,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    '${assignment.subject} • ${assignment.dueDateLabel}',
                                  ),
                                ),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _statusColor(assignment.status)
                                        .withAlpha(30),
                                    borderRadius: AppRadius.borderSm,
                                  ),
                                  child: Text(
                                    assignment.statusLabel,
                                    style: TextStyle(
                                      color: _statusColor(assignment.status),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                onTap: () async {
                                  final result = await Navigator.pushNamed(
                                    context,
                                    RouteNames.studentAssignmentDetail,
                                    arguments: {
                                      'assignmentId': assignment.id,
                                    },
                                  );
                                  if (result == true && context.mounted) {
                                    context
                                        .read<AssignmentsCubit>()
                                        .loadAssignments();
                                  }
                                },
                              ),
                            );
                          },
                        ),
        );
      },
    );
  }
}
