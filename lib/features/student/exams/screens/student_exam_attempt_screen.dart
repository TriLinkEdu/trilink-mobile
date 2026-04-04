import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trilink_mobile/core/widgets/empty_state_widget.dart';
import 'package:trilink_mobile/core/widgets/illustrations.dart';
import 'package:trilink_mobile/core/widgets/error_widget.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../../gamification/screens/quiz_result_screen.dart';
import '../cubit/exam_attempt_cubit.dart';
import '../models/exam_model.dart';
import '../repositories/student_exams_repository.dart';

class StudentExamAttemptScreen extends StatelessWidget {
  final String? examId;

  const StudentExamAttemptScreen({super.key, this.examId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          ExamAttemptCubit(sl<StudentExamsRepository>())..loadExam(examId),
      child: const _ExamAttemptView(),
    );
  }
}

class _ExamAttemptView extends StatelessWidget {
  const _ExamAttemptView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ExamAttemptCubit, ExamAttemptState>(
      builder: (context, state) {
        if (state.status == ExamAttemptStatus.loading ||
            state.status == ExamAttemptStatus.initial) {
          return Scaffold(
            appBar: AppBar(title: const Text('Exam Attempt')),
            body: const Padding(
              padding: EdgeInsets.all(16),
              child: ShimmerList(),
            ),
          );
        }

        if (state.status == ExamAttemptStatus.error) {
          return Scaffold(
            appBar: AppBar(title: const Text('Exam Attempt')),
            body: AppErrorWidget(
              message: state.errorMessage ?? 'Unable to load exam.',
              onRetry: () => context.read<ExamAttemptCubit>().retryLoadExam(),
            ),
          );
        }

        final exam = state.exam!;
        final questions = exam.questions;

        if (questions.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: Text(exam.title)),
            body: const EmptyStateWidget(
              illustration: GraduationCapIllustration(),
              icon: Icons.quiz_rounded,
              title: 'No questions',
              subtitle: 'This exam does not have any questions yet.',
            ),
          );
        }

        return _ExamAttemptQuestions(exam: exam);
      },
    );
  }
}

class _ExamAttemptQuestions extends StatefulWidget {
  final ExamModel exam;

  const _ExamAttemptQuestions({required this.exam});

  @override
  State<_ExamAttemptQuestions> createState() => _ExamAttemptQuestionsState();
}

class _ExamAttemptQuestionsState extends State<_ExamAttemptQuestions> {
  static const String _currentUserId = 'student1';
  int _currentQuestionIndex = 0;
  final Map<String, int> _answers = {};

  Timer? _timer;
  late int _remainingSeconds;
  bool _warned5Min = false;
  bool _warned1Min = false;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.exam.durationMinutes * 60;
    if (widget.exam.isTimeLimited) {
      _timer = Timer.periodic(const Duration(seconds: 1), _onTick);
    }
    _startAttempt();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _startAttempt() async {
    await context.read<ExamAttemptCubit>().startAttempt(
      widget.exam.id,
      _currentUserId,
    );
  }

  Future<bool> _confirmSubmitIfNeeded() async {
    final total = widget.exam.questions.length;
    final answered = _answers.length;

    return (await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Submit exam?'),
            content: Text(
              answered == total
                  ? 'You answered all $total questions.'
                  : 'You answered $answered of $total questions. Unanswered questions will be marked incorrect.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Review'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Submit'),
              ),
            ],
          ),
        )) ??
        false;
  }

  void _onTick(Timer timer) {
    if (_remainingSeconds <= 0) {
      timer.cancel();
      return;
    }

    setState(() => _remainingSeconds--);

    if (_remainingSeconds == 300 && !_warned5Min) {
      _warned5Min = true;
      _showTimerWarning('5 minutes remaining!');
    } else if (_remainingSeconds == 60 && !_warned1Min) {
      _warned1Min = true;
      _showTimerWarning('1 minute remaining!');
    }

    if (_remainingSeconds <= 0) {
      timer.cancel();
      _autoSubmit();
    }
  }

  void _showTimerWarning(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.timer_outlined, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.orange.shade700,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _autoSubmit() async {
    if (!mounted) return;
    final isSubmitting =
        context.read<ExamAttemptCubit>().state.submissionStatus ==
        ExamSubmissionStatus.submitting;
    if (isSubmitting) return;
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Time is up! Auto-submitting your exam...'),
        backgroundColor: Colors.red,
      ),
    );
    await _submitExam();
  }

  String get _formattedTime {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _submitExam() async {
    _timer?.cancel();
    final result = await context.read<ExamAttemptCubit>().submitCurrentExam(
      _answers,
    );
    if (!mounted) return;
    if (result != null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => QuizResultScreen(
            result: result,
            questions: widget.exam.questions,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.read<ExamAttemptCubit>().state.submissionErrorMessage ??
                'Failed to submit exam.',
          ),
        ),
      );
    }
    context.read<ExamAttemptCubit>().clearSubmissionStatus();
  }

  void _selectAnswer(int optionIndex) {
    final question = widget.exam.questions[_currentQuestionIndex];
    setState(() => _answers[question.id] = optionIndex);
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < widget.exam.questions.length - 1) {
      setState(() => _currentQuestionIndex++);
    }
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() => _currentQuestionIndex--);
    }
  }

  @override
  Widget build(BuildContext context) {
    final submissionStatus = context.select(
      (ExamAttemptCubit c) => c.state.submissionStatus,
    );
    final isSubmitting = submissionStatus == ExamSubmissionStatus.submitting;
    final exam = widget.exam;
    final questions = exam.questions;
    final current = questions[_currentQuestionIndex];
    final selectedOption = _answers[current.id];
    final isLastQuestion = _currentQuestionIndex == questions.length - 1;
    final timerIsUrgent = _remainingSeconds < 60;

    return Scaffold(
      appBar: AppBar(
        title: Text(exam.title),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (_currentQuestionIndex + 1) / questions.length,
          ),
        ),
        actions: [
          if (exam.isTimeLimited)
            Center(
              child: Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: timerIsUrgent
                      ? Colors.red.withAlpha(30)
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      size: 18,
                      color: timerIsUrgent ? Colors.red : null,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formattedTime,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontFeatures: const [FontFeature.tabularFigures()],
                        color: timerIsUrgent ? Colors.red : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Question ${_currentQuestionIndex + 1} of ${questions.length}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  '${_answers.length}/${questions.length} answered',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            AppSpacing.gapLg,
            Text(current.text, style: Theme.of(context).textTheme.titleLarge),
            AppSpacing.gapLg,
            ...List.generate(current.options.length, (index) {
              final isSelected = selectedOption == index;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _selectAnswer(index),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.outlineVariant,
                      ),
                      color: isSelected
                          ? Theme.of(context).colorScheme.primaryContainer
                                .withValues(alpha: 0.4)
                          : null,
                    ),
                    child: ListTile(
                      leading: Icon(
                        isSelected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      title: Text(current.options[index]),
                    ),
                  ),
                ),
              );
            }),
            const Spacer(),
            Row(
              children: [
                if (_currentQuestionIndex > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _previousQuestion,
                      child: const Text('Previous'),
                    ),
                  ),
                if (_currentQuestionIndex > 0) AppSpacing.hGapMd,
                Expanded(
                  child: ElevatedButton(
                    onPressed: isSubmitting
                        ? null
                        : isLastQuestion
                        ? () async {
                            final ok = await _confirmSubmitIfNeeded();
                            if (!ok) return;
                            await _submitExam();
                          }
                        : _nextQuestion,
                    child: isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            isLastQuestion ? 'Submit Exam' : 'Next Question',
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
