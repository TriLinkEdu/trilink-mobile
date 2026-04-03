import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import 'package:trilink_mobile/core/widgets/error_widget.dart';
import '../../../../core/widgets/shimmer_loading.dart';
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
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: ShimmerList(),
                )
              : state.status == AssignmentDetailStatus.error
                  ? AppErrorWidget(
                      message: state.errorMessage ??
                          'Unable to load assignment details.',
                      onRetry: () => context
                          .read<AssignmentDetailCubit>()
                          .loadAssignment(),
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
  bool _hasJustSubmitted = false;
  final TextEditingController _submissionController = TextEditingController();

  @override
  void dispose() {
    _submissionController.dispose();
    super.dispose();
  }

  Future<void> _submitAssignment() async {
    final text = _submissionController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your submission before submitting.'),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await sl<StudentAssignmentsRepository>()
          .submitAssignment(widget.assignment.id, text);
      if (!mounted) return;
      setState(() => _hasJustSubmitted = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Assignment submitted successfully!')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to submit assignment.')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  bool get _showReadOnlySubmission {
    if (_hasJustSubmitted) return true;
    final s = widget.assignment.status;
    return s == AssignmentStatus.submitted || s == AssignmentStatus.graded;
  }

  String? get _submittedText {
    if (_hasJustSubmitted) return _submissionController.text.trim();
    return widget.assignment.submittedContent;
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.assignment;
    final canSubmit =
        !_hasJustSubmitted &&
        (a.status == AssignmentStatus.pending ||
            a.status == AssignmentStatus.overdue);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(a.title, style: Theme.of(context).textTheme.headlineSmall),
          AppSpacing.gapSm,
          Text(a.subject, style: Theme.of(context).textTheme.titleMedium),
          AppSpacing.gapSm,
          Text(a.dueDateLabel),
          AppSpacing.gapXs,
          Text('Status: ${_hasJustSubmitted ? 'Submitted' : a.statusLabel}'),
          AppSpacing.gapXxl,
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Description',
                      style: Theme.of(context).textTheme.titleSmall),
                  AppSpacing.gapSm,
                  Text(a.description),
                ],
              ),
            ),
          ),
          if (a.score != null && a.maxScore != null) ...[
            AppSpacing.gapLg,
            Card(
              color: AppColors.success.withAlpha(20),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    const Icon(Icons.grade_rounded, color: AppColors.success),
                    AppSpacing.hGapMd,
                    Text(
                      'Score: ${a.score!.toStringAsFixed(0)}/${a.maxScore!.toStringAsFixed(0)}',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (a.feedback != null) ...[
            AppSpacing.gapLg,
            Card(
              color: AppColors.info.withAlpha(20),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Feedback',
                        style: Theme.of(context).textTheme.titleSmall),
                    AppSpacing.gapSm,
                    Text(a.feedback!),
                  ],
                ),
              ),
            ),
          ],

          // Read-only submitted content
          if (_showReadOnlySubmission && _submittedText != null) ...[
            AppSpacing.gapLg,
            Card(
              color: AppColors.success.withAlpha(12),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.check_circle_rounded,
                            color: AppColors.success, size: 20),
                        AppSpacing.hGapSm,
                        Text('Your Submission',
                            style: Theme.of(context).textTheme.titleSmall),
                      ],
                    ),
                    AppSpacing.gapSm,
                    Text(_submittedText!),
                  ],
                ),
              ),
            ),
          ],

          // Editable submission area
          if (canSubmit) ...[
            AppSpacing.gapLg,
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Your Submission',
                        style: Theme.of(context).textTheme.titleSmall),
                    AppSpacing.gapSm,
                    TextField(
                      controller: _submissionController,
                      maxLines: 8,
                      decoration: const InputDecoration(
                        hintText: 'Type your answer or paste your work here...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    AppSpacing.gapSm,
                    OutlinedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'File picker will be available when integrated'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.attach_file_rounded),
                      label: const Text('Attach File'),
                    ),
                  ],
                ),
              ),
            ),
            AppSpacing.gapLg,
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
        ],
      ),
    );
  }
}
