import 'package:flutter/material.dart';
import 'package:trilink_mobile/core/widgets/celebration_overlay.dart';
import '../../../../core/theme/app_colors.dart';
import '../../exams/models/exam_model.dart';
import '../widgets/badge_visuals.dart';

class QuizResultScreen extends StatefulWidget {
  final ExamResultModel result;
  final List<QuestionModel>? questions;
  final List<String> newlyUnlockedAchievements;
  final List<String> newlyUnlockedAchievementIds;
  final List<String> newlyUnlockedBadges;
  final List<String> newlyUnlockedBadgeIds;
  final bool leveledUp;
  final int? newLevel;
  final int? leaderboardDelta;

  const QuizResultScreen({
    super.key,
    required this.result,
    this.questions,
    this.newlyUnlockedAchievements = const [],
    this.newlyUnlockedAchievementIds = const [],
    this.newlyUnlockedBadges = const [],
    this.newlyUnlockedBadgeIds = const [],
    this.leveledUp = false,
    this.newLevel,
    this.leaderboardDelta,
  });

  @override
  State<QuizResultScreen> createState() => _QuizResultScreenState();
}

class _QuizResultScreenState extends State<QuizResultScreen> {
  static final _celebratedKeys = <String>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final pct = widget.result.percentage;
      final sessionKey = widget.result.examId;
      if (pct >= 90) {
        if (_celebratedKeys.contains(sessionKey)) return;
        _celebratedKeys.add(sessionKey);
        CelebrationOverlay.maybeOf(context)?.celebrate(
          type: CelebrationType.grade,
          message: 'Outstanding Score!',
          subtext: '${pct.round()}%   amazing work!',
        );
      } else if (pct >= 70) {
        if (_celebratedKeys.contains(sessionKey)) return;
        _celebratedKeys.add(sessionKey);
        CelebrationOverlay.maybeOf(context)?.celebrate(
          type: CelebrationType.completion,
          message: 'Quiz Complete!',
          subtext: '${pct.round()}%   nice job!',
        );
      }

      if (widget.leveledUp) {
        CelebrationOverlay.maybeOf(context)?.celebrate(
          type: CelebrationType.levelUp,
          message: 'Level Up!',
          subtext: widget.newLevel != null
              ? 'You reached level ${widget.newLevel}'
              : 'You advanced to the next level',
        );
      }

      if (widget.newlyUnlockedAchievements.isNotEmpty) {
        CelebrationOverlay.maybeOf(context)?.celebrate(
          type: CelebrationType.achievement,
          message: 'New Achievement Unlocked!',
          subtext: widget.newlyUnlockedAchievements.first,
        );
      }

      if (widget.newlyUnlockedBadges.isNotEmpty) {
        CelebrationOverlay.maybeOf(context)?.celebrate(
          type: CelebrationType.achievement,
          message: 'New Badge Unlocked!',
          subtext: widget.newlyUnlockedBadges.first,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pct = widget.result.percentage;
    final passed = pct >= 60;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz Results'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 16),
            Icon(
              passed
                  ? Icons.celebration_rounded
                  : Icons.sentiment_neutral_rounded,
              size: 64,
              color: passed
                  ? AppColors.warning
                  : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              passed ? 'Great job!' : 'Keep practicing!',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            if (widget.result.correctAnswers == widget.result.totalQuestions)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withAlpha(120),
                      blurRadius: 24,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: _ScoreCircle(percentage: pct, theme: theme),
              )
            else
              _ScoreCircle(percentage: pct, theme: theme),
            if (widget.result.correctAnswers ==
                widget.result.totalQuestions) ...[
              const SizedBox(height: 12),
              Text(
                'PERFECT!',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: theme.colorScheme.primary,
                  letterSpacing: 1.5,
                ),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _StatCard(
                  label: 'Correct',
                  value: '${widget.result.correctAnswers}',
                  color: AppColors.success,
                ),
                _StatCard(
                  label: 'Wrong',
                  value:
                      '${widget.result.totalQuestions - widget.result.correctAnswers}',
                  color: AppColors.danger,
                ),
                _StatCard(
                  label: 'XP Earned',
                  value: '+${widget.result.xpEarned}',
                  color: AppColors.warning,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Progress has been applied to your missions and achievements.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            if (widget.newlyUnlockedAchievements.isNotEmpty) ...[
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Unlocked',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.newlyUnlockedAchievements.asMap().entries.map((
                  entry,
                ) {
                  final index = entry.key;
                  final title = entry.value;
                  final achievementId =
                      index < widget.newlyUnlockedAchievementIds.length
                      ? widget.newlyUnlockedAchievementIds[index]
                      : '';
                  return Chip(
                    avatar: Icon(
                      BadgeVisuals.iconForAchievementId(achievementId),
                      size: 18,
                    ),
                    label: Text(title),
                  );
                }).toList(),
              ),
            ],
            if (widget.newlyUnlockedBadges.isNotEmpty) ...[
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Badges',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.newlyUnlockedBadges.asMap().entries.map((
                  entry,
                ) {
                  final index = entry.key;
                  final name = entry.value;
                  final badgeId = index < widget.newlyUnlockedBadgeIds.length
                      ? widget.newlyUnlockedBadgeIds[index]
                      : '';
                  return Chip(
                    avatar: Icon(BadgeVisuals.iconForBadge(badgeId), size: 18),
                    label: Text(name),
                  );
                }).toList(),
              ),
            ],
            if (widget.leaderboardDelta != null &&
                widget.leaderboardDelta! > 0) ...[
              const SizedBox(height: 12),
              Text(
                'You climbed ${widget.leaderboardDelta} place${widget.leaderboardDelta == 1 ? '' : 's'} on the leaderboard.',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            if (widget.questions != null) ...[
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              Text(
                'Question Breakdown',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              ...widget.questions!.asMap().entries.map((entry) {
                final idx = entry.key;
                final q = entry.value;
                final selected = widget.result.answerMap[q.id];
                final isCorrect = selected == q.correctIndex;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      radius: 14,
                      backgroundColor: isCorrect
                          ? AppColors.success
                          : AppColors.danger,
                      child: Icon(
                        isCorrect ? Icons.check : Icons.close,
                        size: 16,
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                    title: Text(
                      'Q${idx + 1}: ${q.text}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      isCorrect
                          ? 'Correct: ${q.options[q.correctIndex]}'
                          : 'Your answer: ${selected != null ? q.options[selected] : "Skipped"}\nCorrect: ${q.options[q.correctIndex]}',
                    ),
                  ),
                );
              }),
            ],
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Back'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreCircle extends StatelessWidget {
  final double percentage;
  final ThemeData theme;
  const _ScoreCircle({required this.percentage, required this.theme});

  @override
  Widget build(BuildContext context) {
    final color = percentage >= 80
        ? AppColors.success
        : percentage >= 60
        ? AppColors.warning
        : AppColors.danger;
    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CircularProgressIndicator(
            value: percentage / 100,
            strokeWidth: 10,
            backgroundColor: color.withValues(alpha: 0.15),
            valueColor: AlwaysStoppedAnimation(color),
          ),
          Center(
            child: Text(
              '${percentage.round()}%',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
