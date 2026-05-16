import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trilink_mobile/core/widgets/error_widget.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
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
          QuizCubit(sl<StudentGamificationRepository>())
            ..loadQuizIfNeeded(subjectId),
      child: _QuizView(subjectId: subjectId),
    );
  }
}

// ── View ─────────────────────────────────────────────────────────────────────

class _QuizView extends StatefulWidget {
  final String subjectId;
  const _QuizView({required this.subjectId});

  @override
  State<_QuizView> createState() => _QuizViewState();
}

class _QuizViewState extends State<_QuizView> with TickerProviderStateMixin {
  int _questionIndex = 0;
  int? _selectedOptionIndex;
  final Map<String, int> _answers = {};

  // Timer
  Timer? _timer;
  int _remainingSeconds = 600;
  bool _timerStarted = false;

  // Option animation
  late AnimationController _slideController;
  late Animation<Offset> _slideAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0.06, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));
    _fadeAnim = CurvedAnimation(parent: _slideController, curve: Curves.easeOut);
    _slideController.forward();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _slideController.dispose();
    super.dispose();
  }

  void _startTimer(int durationMinutes) {
    if (_timerStarted) return;
    _timerStarted = true;
    _remainingSeconds = durationMinutes * 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        _timer?.cancel();
        _autoSubmit();
      }
    });
  }

  Future<void> _autoSubmit() async {
    // Record selected option if one is pending
    final state = context.read<QuizCubit>().state;
    final quiz = state.quiz;
    if (quiz == null) return;
    if (_selectedOptionIndex != null && _questionIndex < quiz.questions.length) {
      _answers[quiz.questions[_questionIndex].id] = _selectedOptionIndex!;
    }
    _doSubmit(quiz);
  }

  Future<void> _doSubmit(ExamModel quiz) async {
    try {
      await context.read<QuizCubit>().submitQuiz(quiz.id, _answers);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to submit. Please retry.')),
      );
    }
  }

  void _selectOption(int index) => setState(() => _selectedOptionIndex = index);

  void _advance(ExamModel quiz) {
    final question = quiz.questions[_questionIndex];
    if (_selectedOptionIndex == null) return;
    _answers[question.id] = _selectedOptionIndex!;

    if (_questionIndex + 1 >= quiz.questions.length) {
      // Last question → submit
      _doSubmit(quiz);
      setState(() {
        _questionIndex++;
        _selectedOptionIndex = null;
      });
      return;
    }

    setState(() {
      _questionIndex++;
      _selectedOptionIndex = null;
    });
    _slideController
      ..reset()
      ..forward();
  }

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Color _timerColor(ThemeData theme) {
    if (_remainingSeconds <= 60) return AppColors.danger;
    if (_remainingSeconds <= 180) return AppColors.warning;
    return AppColors.success;
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
              newlyUnlockedAchievementIds: state.newlyUnlockedAchievementIds,
              newlyUnlockedBadges: state.newlyUnlockedBadges,
              newlyUnlockedBadgeIds: state.newlyUnlockedBadgeIds,
              leveledUp: state.leveledUp,
              newLevel: state.newLevel,
              leaderboardDelta: state.leaderboardDelta,
            ),
          ),
        );
      },
      child: BlocBuilder<QuizCubit, QuizState>(
        builder: (context, state) {
          // ── Loading ──────────────────────────────────────────
          if (state.status == QuizLoadStatus.initial ||
              state.status == QuizLoadStatus.loading) {
            return Scaffold(
              appBar: AppBar(title: const Text('Quiz')),
              body: const Padding(
                padding: AppSpacing.paddingLg,
                child: ShimmerList(itemCount: 5, itemHeight: 64),
              ),
            );
          }

          // ── Error ────────────────────────────────────────────
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

          // Start timer once quiz is loaded
          if (quiz.isTimeLimited) {
            _startTimer(quiz.durationMinutes);
          }

          // ── Submitting ───────────────────────────────────────
          if (state.submitting || _questionIndex >= quiz.questions.length) {
            return Scaffold(
              appBar: AppBar(title: Text(quiz.title)),
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    AppSpacing.gapMd,
                    Text(
                      'Calculating your score…',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            );
          }

          final theme = Theme.of(context);
          final question = quiz.questions[_questionIndex];
          final isLastQuestion =
              _questionIndex == quiz.questions.length - 1;
          final progress = (_questionIndex + 1) / quiz.questions.length;

          return Scaffold(
            // ── App bar with timer ───────────────────────────
            appBar: AppBar(
              title: Text(quiz.title, overflow: TextOverflow.ellipsis),
              actions: [
                if (quiz.isTimeLimited)
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _timerColor(theme).withAlpha(
                          _remainingSeconds <= 60 ? 40 : 26,
                        ),
                        borderRadius: AppRadius.borderMd,
                        border: Border.all(
                          color: _timerColor(theme).withAlpha(100),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.timer_rounded,
                            size: 16,
                            color: _timerColor(theme),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatTime(_remainingSeconds),
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: _timerColor(theme),
                              fontWeight: FontWeight.w800,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            body: SafeArea(
              child: Column(
                children: [
                  // ── Progress bar ─────────────────────────────
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    child: Row(
                      children: [
                        Text(
                          'Q ${_questionIndex + 1}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(AppRadius.full),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 6,
                                backgroundColor: theme
                                    .colorScheme.surfaceContainerHighest,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  theme.colorScheme.primary,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Text(
                          '${quiz.questions.length}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Question card + options ───────────────────
                  Expanded(
                    child: SlideTransition(
                      position: _slideAnim,
                      child: FadeTransition(
                        opacity: _fadeAnim,
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                          children: [
                            // Question text
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    theme.colorScheme.primary.withAlpha(18),
                                    theme.colorScheme.primaryContainer
                                        .withAlpha(30),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: AppRadius.borderLg,
                                border: Border.all(
                                  color: theme.colorScheme.primary.withAlpha(40),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Question ${_questionIndex + 1} of ${quiz.questions.length}',
                                    style: theme.textTheme.labelMedium?.copyWith(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  AppSpacing.gapSm,
                                  Text(
                                    question.text,
                                    style:
                                        theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      height: 1.45,
                                    ),
                                  ),
                                  AppSpacing.gapSm,
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.bolt_rounded,
                                        size: 14,
                                        color: AppColors.xpGold,
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        'Earn XP for each correct answer',
                                        style:
                                            theme.textTheme.labelSmall?.copyWith(
                                          color: AppColors.xpGold,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            AppSpacing.gapLg,

                            // Answer options
                            ...List.generate(
                              question.options.length,
                              (i) => _OptionCard(
                                label: _optionLabel(i),
                                text: question.options[i],
                                isSelected: _selectedOptionIndex == i,
                                onTap: () => _selectOption(i),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // ── Next / Submit button ─────────────────────
                  Padding(
                    padding:
                        const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _selectedOptionIndex != null
                            ? () => _advance(quiz)
                            : null,
                        icon: Icon(
                          isLastQuestion
                              ? Icons.check_circle_rounded
                              : Icons.arrow_forward_rounded,
                        ),
                        label: Text(
                          isLastQuestion ? 'Submit Quiz' : 'Next Question',
                        ),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          textStyle: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
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

  static String _optionLabel(int index) {
    const labels = ['A', 'B', 'C', 'D', 'E'];
    return index < labels.length ? labels[index] : '${index + 1}';
  }
}

// ── Option Card ───────────────────────────────────────────────────────────────

class _OptionCard extends StatelessWidget {
  final String label;
  final String text;
  final bool isSelected;
  final VoidCallback onTap;

  const _OptionCard({
    required this.label,
    required this.text,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: isSelected
              ? primary.withAlpha(22)
              : theme.colorScheme.surface,
          borderRadius: AppRadius.borderLg,
          border: Border.all(
            color: isSelected ? primary : theme.colorScheme.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: primary.withAlpha(30),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : AppShadows.subtle(theme.shadowColor),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: AppRadius.borderLg,
          child: InkWell(
            borderRadius: AppRadius.borderLg,
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: isSelected ? primary : primary.withAlpha(22),
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: Center(
                      child: Text(
                        label,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: isSelected
                              ? theme.colorScheme.onPrimary
                              : primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  AppSpacing.hGapMd,
                  Expanded(
                    child: Text(
                      text,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected
                            ? theme.colorScheme.onSurface
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  if (isSelected)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Icon(
                        Icons.check_circle_rounded,
                        color: primary,
                        size: 20,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
