import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../shared/widgets/student_page_background.dart';
import '../cubit/feedback_cubit.dart';
import '../repositories/student_feedback_repository.dart';

class SubmitFeedbackScreen extends StatefulWidget {
  final String subjectId;
  final String subjectName;

  const SubmitFeedbackScreen({
    super.key,
    required this.subjectId,
    required this.subjectName,
  });

  @override
  State<SubmitFeedbackScreen> createState() => _SubmitFeedbackScreenState();
}

class _SubmitFeedbackScreenState extends State<SubmitFeedbackScreen> {
  final TextEditingController _commentController = TextEditingController();
  int _rating = 0;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => FeedbackCubit(sl<StudentFeedbackRepository>()),
      child: BlocConsumer<FeedbackCubit, FeedbackState>(
        listener: (context, state) {
          if (state.submissionStatus == FeedbackSubmissionStatus.success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Feedback submitted successfully.')),
            );
            context.read<FeedbackCubit>().clearSubmissionStatus();
            Navigator.of(context).pop(true);
          } else if (state.submissionStatus == FeedbackSubmissionStatus.error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state.submissionErrorMessage ?? 'Failed to submit feedback.',
                ),
              ),
            );
            context.read<FeedbackCubit>().clearSubmissionStatus();
          }
        },
        builder: (context, state) {
          final isSubmitting =
              state.submissionStatus == FeedbackSubmissionStatus.submitting;
          return Scaffold(
            appBar: AppBar(title: Text('Feedback: ${widget.subjectName}')),
            body: StudentPageBackground(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Rate this subject',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    AppSpacing.gapSm,
                    Row(
                      children: List.generate(
                        5,
                        (index) => IconButton(
                          tooltip:
                              'Set rating ${index + 1} star${index == 0 ? '' : 's'}',
                          onPressed: () => setState(() => _rating = index + 1),
                          icon: Icon(
                            index < _rating ? Icons.star : Icons.star_border,
                            color: AppColors.xpGold,
                          ),
                        ),
                      ),
                    ),
                    AppSpacing.gapMd,
                    TextField(
                      controller: _commentController,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        hintText: 'Share your feedback anonymously...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    AppSpacing.gapLg,
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isSubmitting ? null : _submit,
                        child: isSubmitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Submit Feedback'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _submit() {
    if (_rating == 0 || _commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide rating and comment.')),
      );
      return;
    }

    context.read<FeedbackCubit>().submitFeedback(
      subjectId: widget.subjectId,
      subjectName: widget.subjectName,
      rating: _rating,
      comment: _commentController.text.trim(),
    );
  }
}
