import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../cubit/assignment_detail_cubit.dart';
import '../models/assignment_model.dart';
import '../repositories/student_assignments_repository.dart';

class AssignmentDetailScreen extends StatelessWidget {
  final String assignmentId;

  const AssignmentDetailScreen({
    super.key,
    required this.assignmentId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AssignmentDetailCubit(
        sl<StudentAssignmentsRepository>(),
        assignmentId,
      )..loadAssignment(),
      child: const _AssignmentDetailView(),
    );
  }
}

class _AssignmentDetailView extends StatelessWidget {
  const _AssignmentDetailView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AssignmentDetailCubit, AssignmentDetailState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(title: const Text('Assignment Details')),
          body: state.status == AssignmentDetailStatus.loading ||
                  state.status == AssignmentDetailStatus.initial
              ? const Center(child: CircularProgressIndicator())
              : state.status == AssignmentDetailStatus.error
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            state.errorMessage ?? '',
                            style: const TextStyle(color: Colors.red),
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: () => context
                                .read<AssignmentDetailCubit>()
                                .loadAssignment(),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : _AssignmentDetailBody(assignment: state.assignment!),
        );
      },
    );
  }
}

class _AssignmentDetailBody extends StatefulWidget {
  final AssignmentModel assignment;

  const _AssignmentDetailBody({required this.assignment});

  @override
  State<_AssignmentDetailBody> createState() => _AssignmentDetailBodyState();
}

class _AssignmentDetailBodyState extends State<_AssignmentDetailBody> {
  bool _isSubmitting = false;

  Future<void> _submitAssignment() async {
    setState(() => _isSubmitting = true);
    try {
      await sl<StudentAssignmentsRepository>().submitAssignment(
          widget.assignment.id, 'Submitted via app');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Assignment submitted successfully!')),
      );
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to submit assignment.')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.assignment;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(a.title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(a.subject, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(a.dueDateLabel),
          const SizedBox(height: 4),
          Text('Status: ${a.statusLabel}'),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Description',
                      style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  Text(a.description),
                ],
              ),
            ),
          ),
          if (a.score != null && a.maxScore != null) ...[
            const SizedBox(height: 16),
            Card(
              color: Colors.green.shade50,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    const Icon(Icons.grade_rounded, color: Colors.green),
                    const SizedBox(width: 12),
                    Text(
                      'Score: ${a.score!.toStringAsFixed(0)}/${a.maxScore!.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (a.feedback != null) ...[
            const SizedBox(height: 16),
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Feedback',
                        style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    Text(a.feedback!),
                  ],
                ),
              ),
            ),
          ],
          const Spacer(),
          if (a.status == AssignmentStatus.pending ||
              a.status == AssignmentStatus.overdue)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitAssignment,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Submit Assignment'),
              ),
            ),
        ],
      ),
    );
  }
}
