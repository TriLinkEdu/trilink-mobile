import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trilink_mobile/core/widgets/celebration_overlay.dart';
import 'package:trilink_mobile/core/widgets/empty_state_widget.dart';
import 'package:trilink_mobile/core/widgets/illustrations.dart';
import 'package:trilink_mobile/core/widgets/staggered_animation.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/routes/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/pressable.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../cubit/gamification_cubit.dart';
import '../models/gamification_models.dart';
import '../repositories/student_gamification_repository.dart';

/// Gamification hub: streaks, achievements, quick quizzes, leaderboard.
class GamificationScreen extends StatelessWidget {
  const GamificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          GamificationCubit(sl<StudentGamificationRepository>())..loadAll(),
      child: const _GamificationView(),
    );
  }
}

class _GamificationView extends StatefulWidget {
  const _GamificationView();

  @override
  State<_GamificationView> createState() => _GamificationViewState();
}

class _GamificationViewState extends State<_GamificationView> {
  static final _celebratedKeys = <String>{};

  bool _notifyQuizReminders = true;
  bool _notifyLeaderboard = true;
  bool _notifyAchievements = true;

  void _maybeCelebrateStreakMilestone(int streak) {
    if (streak < 7) return;

    String message;
    String subtext;
    if (streak >= 100) {
      message = '🔥 $streak Day Streak!';
      subtext = 'Incredible dedication!';
    } else if (streak >= 50) {
      message = '🔥 $streak Day Streak!';
      subtext = 'You are unstoppable!';
    } else if (streak >= 30) {
      message = '🔥 $streak Day Streak!';
      subtext = 'A full month of consistency!';
    } else if (streak >= 14) {
      message = '🔥 $streak Day Streak!';
      subtext = 'Two weeks strong!';
    } else {
      message = '🔥 $streak Day Streak!';
      subtext = 'Great start — keep the fire going!';
    }

    CelebrationOverlay.maybeOf(context)?.celebrate(
      type: CelebrationType.streak,
      message: message,
      subtext: subtext,
    );
  }

  void _showSettingsSheet() {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: AppSpacing.paddingXxl,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Notification Preferences',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              AppSpacing.gapLg,
              SwitchListTile(
                title: const Text('Quiz Reminders'),
                subtitle: const Text('Get reminded about available quizzes'),
                value: _notifyQuizReminders,
                onChanged: (val) {
                  setSheetState(() => _notifyQuizReminders = val);
                  setState(() {});
                },
              ),
              SwitchListTile(
                title: const Text('Leaderboard Updates'),
                subtitle: const Text('Know when rankings change'),
                value: _notifyLeaderboard,
                onChanged: (val) {
                  setSheetState(() => _notifyLeaderboard = val);
                  setState(() {});
                },
              ),
              SwitchListTile(
                title: const Text('Achievement Notifications'),
                subtitle: const Text('Get notified when you unlock badges'),
                value: _notifyAchievements,
                onChanged: (val) {
                  setSheetState(() => _notifyAchievements = val);
                  setState(() {});
                },
              ),
              AppSpacing.gapSm,
            ],
          ),
        ),
      ),
    );
  }

  void _showStreakHistory() {
    final streak = context.read<GamificationCubit>().state.streak;
    if (streak == null) return;

    showDialog(
      context: context,
      builder: (ctx) {
        final dialogTheme = Theme.of(ctx);
        return AlertDialog(
          title: const Text('Streak History'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _streakRow(ctx, 'Current Streak', '${streak.currentStreak} days'),
              AppSpacing.gapSm,
              _streakRow(ctx, 'Longest Streak', '${streak.longestStreak} days'),
              AppSpacing.gapMd,
              Text(
                'Recent Active Days',
                style: dialogTheme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              AppSpacing.gapSm,
              ...streak.recentDays.map(
                (d) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: AppColors.success,
                        size: 16,
                      ),
                      AppSpacing.hGapSm,
                      Text(
                        '${d.day}/${d.month}/${d.year}',
                        style: dialogTheme.textTheme.labelLarge,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _streakRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: theme.textTheme.bodyMedium),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  IconData _iconForSubject(String subjectName) {
    final lower = subjectName.toLowerCase();
    if (lower.contains('math') || lower.contains('calculus')) {
      return Icons.calculate_rounded;
    }
    if (lower.contains('phys') || lower.contains('mechanic')) {
      return Icons.science_rounded;
    }
    if (lower.contains('liter')) return Icons.menu_book_rounded;
    if (lower.contains('hist')) return Icons.public_rounded;
    if (lower.contains('comput')) return Icons.computer_rounded;
    return Icons.quiz_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? const [Color(0xFF0A1422), Color(0xFF10253A)]
                : const [Color(0xFFF0F8FF), Color(0xFFE6F4FF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.md,
                ),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Back',
                      onPressed: () {
                        Navigator.of(context).maybePop();
                      },
                      icon: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 18,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Gamification Hub',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Gamification settings',
                      onPressed: _showSettingsSheet,
                      icon: Icon(
                        Icons.settings_outlined,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: BlocBuilder<GamificationCubit, GamificationState>(
                  builder: (context, state) {
                    final loading =
                        state.status == GamificationStatus.initial ||
                        state.status == GamificationStatus.loading;
                    if (loading) {
                      return const Padding(
                        padding: AppSpacing.horizontalXl,
                        child: ShimmerList(itemCount: 5, itemHeight: 80),
                      );
                    }

                    final streak = state.streak?.currentStreak;
                    const key = 'streak_milestone';
                    if (!_celebratedKeys.contains(key) &&
                        streak != null &&
                        streak >= 7) {
                      _celebratedKeys.add(key);
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (!mounted) return;
                        _maybeCelebrateStreakMilestone(streak);
                      });
                    }

                    return SingleChildScrollView(
                      padding: AppSpacing.horizontalXl,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildStreakCard(state.streak),
                          AppSpacing.gapXxl,
                          _buildAchievementsSection(state.achievements),
                          AppSpacing.gapXxl,
                          _buildQuickQuizSection(state.availableQuizzes),
                          AppSpacing.gapXxl,
                          _buildLeaderboardSection(
                            state.leaderboardEntries,
                            state.isWeeklyRanking,
                          ),
                          AppSpacing.gapXxl,
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStreakCard(StreakModel? streak) {
    final theme = Theme.of(context);
    final isLegendary = (streak?.currentStreak ?? 0) >= 100;
    return Pressable(
      onTap: _showStreakHistory,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28),
        decoration: BoxDecoration(
          gradient: theme.ext.heroGradient,
          borderRadius: AppRadius.borderXl,
          border: isLegendary
              ? Border.all(color: AppColors.xpGold, width: 2.5)
              : null,
          boxShadow: isLegendary
              ? [
                  BoxShadow(
                    color: AppColors.xpGold.withAlpha(70),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: theme.colorScheme.onPrimary.withAlpha(28),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.local_fire_department_rounded,
                color: theme.colorScheme.onPrimary,
                size: 30,
              ),
            ),
            AppSpacing.gapMd,
            Text(
              streak != null
                  ? '${streak.currentStreak} Day Streak'
                  : '-- Day Streak',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onPrimary,
              ),
            ),
            if (isLegendary) ...[
              AppSpacing.gapXs,
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.xpGold,
                  borderRadius: AppRadius.borderSm,
                ),
                child: Text(
                  'LEGENDARY',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: theme.colorScheme.onPrimaryContainer,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
            AppSpacing.gapXs,
            Text(
              "Keep it up! You're on fire.",
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onPrimary.withAlpha(200),
              ),
            ),
            AppSpacing.gapLg,
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.onPrimary.withAlpha(28),
                borderRadius: AppRadius.borderXl,
              ),
              child: Text(
                'View History',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementsSection(List<AchievementModel> achievements) {
    final theme = Theme.of(context);
    final displayAchievements = achievements.take(4).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Achievements',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pushNamed(RouteNames.studentAchievements);
              },
              child: Text(
                'See All',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        AppSpacing.gapSm,
        if (displayAchievements.isEmpty)
          const EmptyStateWidget(
            illustration: TrophyIllustration(),
            icon: Icons.emoji_events_rounded,
            title: 'No achievements yet',
            subtitle: 'Complete challenges to earn achievements!',
          )
        else
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: displayAchievements.length,
              separatorBuilder: (_, _) => AppSpacing.hGapLg,
              itemBuilder: (_, i) {
                final a = displayAchievements[i];
                final color = a.isUnlocked
                    ? AppColors.leaderboardCrown
                    : theme.colorScheme.onSurfaceVariant;
                final icon = a.isUnlocked
                    ? Icons.emoji_events_rounded
                    : Icons.lock_rounded;
                return _AchievementChip(
                  icon: icon,
                  label: a.title,
                  sublabel: a.isUnlocked ? 'Unlocked' : 'Locked',
                  color: color,
                  isUnlocked: a.isUnlocked,
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildQuickQuizSection(List<QuizModel> availableQuizzes) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Quiz',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
        AppSpacing.gapMd,
        if (availableQuizzes.isEmpty)
          const EmptyStateWidget(
            illustration: TrophyIllustration(),
            icon: Icons.quiz_rounded,
            title: 'No quizzes available',
            subtitle: 'Quick quizzes will appear here.',
          )
        else
          ...List.generate(availableQuizzes.length, (i) {
            final quiz = availableQuizzes[i];
            return StaggeredFadeSlide(
              index: i,
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: i < availableQuizzes.length - 1 ? 10 : 0,
                ),
                child: _QuickQuizTile(
                  icon: _iconForSubject(quiz.subjectName),
                  title: '${quiz.subjectName}: ${quiz.title}',
                  questions: quiz.questionCount,
                  xp: quiz.xpReward,
                  onStart: () {
                    Navigator.of(context).pushNamed(
                      RouteNames.studentQuiz,
                      arguments: {'subjectId': quiz.subjectId},
                    );
                  },
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildLeaderboardSection(
    List<LeaderboardEntry> leaderboardEntries,
    bool isWeeklyRanking,
  ) {
    final theme = Theme.of(context);
    final topEntries = leaderboardEntries.take(3).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Leaderboard',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            InkWell(
              onTap: () =>
                  context.read<GamificationCubit>().toggleLeaderboardPeriod(),
              borderRadius: AppRadius.borderSm,
              child: Row(
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(
                        context,
                      ).pushNamed(RouteNames.studentLeaderboard);
                    },
                    child: const Text('Open'),
                  ),
                  Icon(
                    Icons.swap_vert_rounded,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  AppSpacing.hGapXs,
                  Text(
                    isWeeklyRanking ? 'Weekly' : 'Monthly',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        AppSpacing.gapMd,
        if (topEntries.isEmpty)
          const EmptyStateWidget(
            illustration: TrophyIllustration(),
            icon: Icons.leaderboard_rounded,
            title: 'No leaderboard data',
            subtitle: 'Compete with classmates to see rankings here.',
          )
        else
          ...List.generate(topEntries.length, (i) {
            final entry = topEntries[i];
            const rankColors = [
              AppColors.rankGold,
              AppColors.rankSilver,
              AppColors.rankBronze,
            ];
            final avatarColors = [
              AppColors.streakFire,
              AppColors.secondary,
              theme.colorScheme.primary,
            ];
            return StaggeredFadeSlide(
              index: i,
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: i < topEntries.length - 1 ? 8 : 0,
                ),
                child: _LeaderboardRow(
                  rank: entry.rank,
                  name: entry.studentName,
                  classLabel: '',
                  xp: '${entry.points} XP',
                  avatarColor: avatarColors[i % avatarColors.length],
                  rankColor: rankColors[i % rankColors.length],
                ),
              ),
            );
          }),
      ],
    );
  }
}

class _AchievementChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final Color color;
  final bool isUnlocked;

  const _AchievementChip({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.color,
    required this.isUnlocked,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: isUnlocked
                ? color.withAlpha(25)
                : theme.colorScheme.surfaceContainerLow,
            shape: BoxShape.circle,
            border: Border.all(
              color: isUnlocked
                  ? color.withAlpha(80)
                  : theme.colorScheme.outlineVariant,
              width: 2,
            ),
          ),
          child: Icon(
            icon,
            color: isUnlocked ? color : theme.colorScheme.onSurfaceVariant,
            size: 26,
          ),
        ),
        AppSpacing.gapSm,
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        Text(
          sublabel,
          style: theme.textTheme.labelSmall?.copyWith(
            color: isUnlocked
                ? AppColors.success
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _QuickQuizTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final int questions;
  final int xp;
  final VoidCallback onStart;

  const _QuickQuizTile({
    required this.icon,
    required this.title,
    required this.questions,
    required this.xp,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 2,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppRadius.borderLg,
        boxShadow: AppShadows.subtle(theme.shadowColor),
      ),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.onSurfaceVariant, size: 22),
          AppSpacing.hGapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                AppSpacing.gapXxs,
                Text(
                  '$questions Questions  •  $xp XP',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: onStart,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: theme.colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: AppRadius.borderSm),
              elevation: 0,
              textStyle: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            child: const Text('Start'),
          ),
        ],
      ),
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  final int rank;
  final String name;
  final String classLabel;
  final String xp;
  final Color avatarColor;
  final Color rankColor;

  const _LeaderboardRow({
    required this.rank,
    required this.name,
    required this.classLabel,
    required this.xp,
    required this.avatarColor,
    required this.rankColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppRadius.borderLg,
        boxShadow: AppShadows.subtle(theme.shadowColor),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: rankColor.withAlpha(24),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$rank',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: rankColor,
                ),
              ),
            ),
          ),
          AppSpacing.hGapMd,
          CircleAvatar(
            radius: 17,
            backgroundColor: avatarColor.withAlpha(24),
            child: Icon(Icons.person_rounded, color: avatarColor, size: 19),
          ),
          AppSpacing.hGapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                if (classLabel.isNotEmpty)
                  Text(
                    classLabel,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            xp,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
