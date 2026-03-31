import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/routes/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
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
  bool _notifyQuizReminders = true;
  bool _notifyLeaderboard = true;
  bool _notifyAchievements = true;

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
      builder: (ctx) => AlertDialog(
        title: const Text('Streak History'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _streakRow('Current Streak', '${streak.currentStreak} days'),
            AppSpacing.gapSm,
            _streakRow('Longest Streak', '${streak.longestStreak} days'),
            AppSpacing.gapMd,
            const Text(
              'Recent Active Days',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            AppSpacing.gapSm,
            ...streak.recentDays.map((d) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: AppColors.success, size: 16),
                      AppSpacing.hGapSm,
                      Text(
                        '${d.day}/${d.month}/${d.year}',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _streakRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14)),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md),
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
                  final loading = state.status == GamificationStatus.initial ||
                      state.status == GamificationStatus.loading;
                  if (loading) {
                    return const Padding(
                      padding: AppSpacing.horizontalXl,
                      child: ShimmerList(itemCount: 5, itemHeight: 80),
                    );
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
    );
  }

  Widget _buildStreakCard(StreakModel? streak) {
    return Pressable(
      onTap: _showStreakHistory,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28),
        decoration: BoxDecoration(
          gradient: AppGradients.primaryHero,
          borderRadius: AppRadius.borderXl,
        ),
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(35),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.local_fire_department_rounded,
                color: Colors.white,
                size: 30,
              ),
            ),
            AppSpacing.gapMd,
            Text(
              streak != null
                  ? '${streak.currentStreak} Day Streak'
                  : '-- Day Streak',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            AppSpacing.gapXs,
            Text(
              "Keep it up! You're on fire.",
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withAlpha(200),
              ),
            ),
            AppSpacing.gapLg,
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(40),
                borderRadius: AppRadius.borderXl,
              ),
              child: const Text(
                'View History',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white,
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
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pushNamed(
                  RouteNames.studentAchievements,
                );
              },
              child: Text(
                'See All',
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        AppSpacing.gapSm,
        SizedBox(
          height: 100,
          child: displayAchievements.isEmpty
              ? const Center(child: Text('No achievements yet.'))
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: displayAchievements.length,
                  separatorBuilder: (_, _) => AppSpacing.hGapLg,
                  itemBuilder: (_, i) {
                    final a = displayAchievements[i];
                    final color = a.isUnlocked ? AppColors.leaderboardCrown : Colors.grey;
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
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        AppSpacing.gapMd,
        if (availableQuizzes.isEmpty)
          const Center(child: Text('No quizzes available.'))
        else
          ...List.generate(availableQuizzes.length, (i) {
            final quiz = availableQuizzes[i];
            return Padding(
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
                      Navigator.of(context)
                          .pushNamed(RouteNames.studentLeaderboard);
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
                    style: TextStyle(
                      fontSize: 13,
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
          const Center(child: Text('No leaderboard data.'))
        else
          ...List.generate(topEntries.length, (i) {
            final entry = topEntries[i];
            const rankColors = [
              Color(0xFFFFD700),
              Color(0xFFC0C0C0),
              Color(0xFFCD7F32),
            ];
            final avatarColors = [AppColors.streakFire, AppColors.secondary, theme.colorScheme.primary];
            return Padding(
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
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        Text(
          sublabel,
          style: TextStyle(
            fontSize: 10,
            color: isUnlocked ? AppColors.success : theme.colorScheme.onSurfaceVariant,
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
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
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
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                AppSpacing.gapXxs,
                Text(
                  '$questions Questions  •  $xp XP',
                  style: TextStyle(
                    fontSize: 11,
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
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.borderSm,
              ),
              elevation: 0,
              textStyle: const TextStyle(
                fontSize: 13,
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
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppRadius.borderLg,
        boxShadow: AppShadows.subtle(theme.shadowColor),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: rankColor.withAlpha(40),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$rank',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: rankColor,
                ),
              ),
            ),
          ),
          AppSpacing.hGapMd,
          CircleAvatar(
            radius: 18,
            backgroundColor: avatarColor.withAlpha(40),
            child: Icon(Icons.person_rounded, color: avatarColor, size: 20),
          ),
          AppSpacing.hGapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                if (classLabel.isNotEmpty)
                  Text(
                    classLabel,
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            xp,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
