import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trilink_mobile/core/widgets/error_widget.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../../exams/models/exam_model.dart';
import '../cubit/quiz_cubit.dart';
import '../repositories/student_gamification_repository.dart';
import 'quiz_result_screen.dart';

class QuizScreen extends StatelessWidget {
  final String subjectId;
  final String? chapterId;

  const QuizScreen({super.key, required this.subjectId, this.chapterId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          QuizCubit(sl<StudentGamificationRepository>())..loadQuiz(subjectId),
      child: _QuizView(subjectId: subjectId),
    );
  }
}

class _QuizView extends StatefulWidget {
  final String subjectId;

  const _QuizView({required this.subjectId});

  @override
  State<_QuizView> createState() => _QuizViewState();
}

class _QuizViewState extends State<_QuizView> {
  int _questionIndex = 0;
  final Map<String, int> _answers = {};

  Future<void> _submitQuiz(ExamModel quiz) async {
    try {
      await context.read<QuizCubit>().submitQuiz(quiz.id, _answers);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to submit quiz. Please retry.')),
      );
    }
  }

  void _selectAnswer(ExamModel quiz, int optionIndex) {
    if (_questionIndex >= quiz.questions.length) return;

    final question = quiz.questions[_questionIndex];
    setState(() {
      _answers[question.id] = optionIndex;
      _questionIndex += 1;
    });

    if (_questionIndex >= quiz.questions.length) {
      _submitQuiz(quiz);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<QuizCubit, QuizState>(
      listenWhen: (p, c) =>
          c.submitResult != null && c.submitResult != p.submitResult,
      listener: (context, state) {
        final result = state.submitResult;
        final quiz = state.quiz;
        if (result == null || quiz == null) return;
        context.read<QuizCubit>().clearSubmitResult();
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => QuizResultScreen(
              result: result,
              questions: quiz.questions,
              newlyUnlockedAchievements: state.newlyUnlockedAchievements,
              leveledUp: state.leveledUp,
              newLevel: state.newLevel,
            ),
          ),
        );
      },
      child: BlocBuilder<QuizCubit, QuizState>(
        builder: (context, state) {
          if (state.status == QuizLoadStatus.initial ||
              state.status == QuizLoadStatus.loading) {
            return Scaffold(
              appBar: AppBar(title: const Text('Quiz')),
              body: const Padding(
                padding: AppSpacing.paddingLg,
                child: ShimmerList(itemCount: 5, itemHeight: 56),
              ),
            );
          }

          if (state.status == QuizLoadStatus.error || state.quiz == null) {
            return Scaffold(
              appBar: AppBar(title: const Text('Quiz')),
              body: AppErrorWidget(
                message: state.errorMessage ?? 'Quiz not found.',
                onRetry: () =>
                    context.read<QuizCubit>().loadQuiz(widget.subjectId),
              ),
            );
          }

          final quiz = state.quiz!;
          final finished = _questionIndex >= quiz.questions.length;

          return Scaffold(
            appBar: AppBar(title: Text(quiz.title)),
            body: state.submitting
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ShimmerLoading(height: 24, width: 120),
                        SizedBox(height: 16),
                        Text('Submitting your answers...'),
                      ],
                    ),
                  )
                : finished
                ? const Padding(
                    padding: AppSpacing.paddingLg,
                    child: ShimmerList(itemCount: 3),
                  )
                : Padding(
                    padding: AppSpacing.paddingLg,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LinearProgressIndicator(
                          value: (_questionIndex + 1) / quiz.questions.length,
                        ),
                        AppSpacing.gapLg,
                        Text(
                          'Question ${_questionIndex + 1} of ${quiz.questions.length}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        AppSpacing.gapMd,
                        Text(
                          quiz.questions[_questionIndex].text,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w500),
                        ),
                        AppSpacing.gapLg,
                        ...List.generate(
                          quiz.questions[_questionIndex].options.length,
                          (index) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: () => _selectAnswer(quiz, index),
                                child: Text(
                                  quiz.questions[_questionIndex].options[index],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          );
        },
      ),
    );
  }
}
