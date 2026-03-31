import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
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
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(state.errorMessage ?? '',
                      style: const TextStyle(color: AppColors.danger)),
                  AppSpacing.gapSm,
                  ElevatedButton(
                    onPressed: () =>
                        context.read<ExamAttemptCubit>().retryLoadExam(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        final exam = state.exam!;
        final questions = exam.questions;

        if (questions.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: Text(exam.title)),
            body: const Center(child: Text('No questions in this exam.')),
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
  bool _isSubmitting = false;
  int _currentQuestionIndex = 0;
  final Map<String, int> _answers = {};

  Future<void> _submitExam() async {
    setState(() => _isSubmitting = true);
    try {
      final result =
          await sl<StudentExamsRepository>().submitExam(widget.exam.id, _answers);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => QuizResultScreen(
            result: result,
            questions: widget.exam.questions,
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to submit exam.')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
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
    final exam = widget.exam;
    final questions = exam.questions;
    final current = questions[_currentQuestionIndex];
    final selectedOption = _answers[current.id];
    final isLastQuestion = _currentQuestionIndex == questions.length - 1;

    return Scaffold(
      appBar: AppBar(title: Text(exam.title)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Question ${_currentQuestionIndex + 1}/${questions.length}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  '${_answers.length}/${questions.length} answered',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            AppSpacing.gapXs,
            LinearProgressIndicator(
              value: (_currentQuestionIndex + 1) / questions.length,
            ),
            AppSpacing.gapLg,
            Text(
              current.text,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            AppSpacing.gapLg,
            ...List.generate(current.options.length, (index) {
              return RadioListTile<int>(
                value: index,
                groupValue: selectedOption,
                title: Text(current.options[index]),
                onChanged: (value) {
                  if (value != null) _selectAnswer(value);
                },
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
                    onPressed: selectedOption == null
                        ? null
                        : isLastQuestion
                            ? (_isSubmitting ? null : _submitExam)
                            : _nextQuestion,
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child:
                                CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(isLastQuestion
                            ? 'Submit Exam'
                            : 'Next Question'),
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
