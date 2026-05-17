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
import '../../../../core/theme/subject_visuals.dart';
import '../../../../core/widgets/pressable.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../../shared/widgets/profile_avatar.dart';
import '../../shared/widgets/student_page_background.dart';
import '../cubit/gamification_cubit.dart';
import '../models/gamification_models.dart';
import '../repositories/student_gamification_repository.dart';
import '../widgets/badge_visuals.dart';

/// Gamification hub: streaks, achievements, quick quizzes, leaderboard.
class GamificationScreen extends StatelessWidget {
  const GamificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          GamificationCubit(sl<StudentGamificationRepository>())
            ..loadIfNeeded(),
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

  int? _prevLevel;
  int? _prevTotalXp;

  bool _notifyQuizReminders = true;
  bool _notifyLeaderboard = true;
  bool _notifyAchievements = true;

  String? _resolveAchievementTitle(String id, List<AchievementModel> list) {
    for (final item in list) {
      if (item.id == id) return item.title;
    }
    return null;
  }

  String? _resolveBadgeName(String id, List<BadgeModel> list) {
    for (final item in list) {
      if (item.id == id) return item.name;
    }
    return null;
  }

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
      subtext = 'Great start   keep the fire going!';
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

  IconData _iconForSubject(String subjectName) =>
      SubjectVisuals.iconOf(subjectName);

  LeaderboardEntry? _entryByRank(List<LeaderboardEntry> entries, int rank) {
    for (final entry in entries) {
      if (entry.rank == rank) return entry;
    }
    return null;
  }

  String _formatChasingNames(List<String> names) {
    if (names.isEmpty) return '';
    if (names.length == 1) return names.first;
    if (names.length == 2) return '${names[0]} and ${names[1]}';
    return '${names[0]}, ${names[1]}, and others';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: StudentPageBackground(
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
                child: BlocConsumer<GamificationCubit, GamificationState>(
                  listener: (context, state) {
                    if (state.status != GamificationStatus.loaded) return;
                    final xp = state.xpProgress;
                    if (xp == null) return;
                    final prevLevel = _prevLevel;
                    final prevXp = _prevTotalXp;
                    _prevLevel = xp.level;
                    _prevTotalXp = xp.totalXp;
                    if (prevLevel == null || prevXp == null) return;
                    if (xp.level > prevLevel) {
                      CelebrationOverlay.maybeOf(context)?.celebrate(
                        type: CelebrationType.levelUp,
                        message: '⚡ Level ${xp.level} Reached!',
                        subtext: 'Keep earning XP to unlock more rewards!',
                      );
                    } else if (xp.totalXp > prevXp) {
                      final gained = xp.totalXp - prevXp;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('+$gained XP earned!'),
                          duration: const Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                          width: 160,
                        ),
                      );
                    }
                  },
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

                    // Celebrate newly unlocked achievements
                    for (final id in state.newlyUnlockedAchievementIds) {
                      final aKey = 'achievement_$id';
                      if (_celebratedKeys.contains(aKey)) continue;
                      _celebratedKeys.add(aKey);
                      final title =
                          _resolveAchievementTitle(id, state.achievements) ??
                              'Achievement';
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (!mounted) return;
                        CelebrationOverlay.maybeOf(context)?.celebrate(
                          type: CelebrationType.achievement,
                          message: '🏆 $title Unlocked!',
                          subtext: 'Great work — keep going!',
                        );
                      });
                    }

                    // Celebrate newly unlocked badges
                    for (final id in state.newlyUnlockedBadgeIds) {
                      final bKey = 'badge_$id';
                      if (_celebratedKeys.contains(bKey)) continue;
                      _celebratedKeys.add(bKey);
                      final name =
                          _resolveBadgeName(id, state.badges) ?? 'Badge';
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (!mounted) return;
                        CelebrationOverlay.maybeOf(context)?.celebrate(
                          type: CelebrationType.achievement,
                          message: '🎖️ $name Earned!',
                          subtext: 'New badge added to your collection',
                        );
                      });
                    }

                    if (state.status == GamificationStatus.error) {
                      return Center(
                        child: Padding(
                          padding: AppSpacing.paddingXxl,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.cloud_off_rounded,
                                size: 64,
                                color: theme.colorScheme.onSurfaceVariant
                                    .withAlpha(100),
                              ),
                              AppSpacing.gapMd,
                              Text(
                                'Could not load your hub',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              AppSpacing.gapSm,
                              Text(
                                state.errorMessage ??
                                    'Check your connection and try again.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              AppSpacing.gapLg,
                              FilledButton.icon(
                                onPressed: () =>
                                    context.read<GamificationCubit>().loadAll(),
                                icon: const Icon(Icons.refresh_rounded),
                                label: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return SingleChildScrollView(
                      padding: AppSpacing.horizontalXl,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildStreakCard(state.streak),
                          AppSpacing.gapLg,
                          _buildProgressSnapshot(
                            state.xpProgress,
                            state.nextBadgeProgress,
                          ),
                          AppSpacing.gapXxl,
                          _buildDailyMissionsSection(state.dailyMissions),
                          AppSpacing.gapXxl,
                          _buildTeamChallengeSection(state.teamChallenge),
                          AppSpacing.gapXxl,
                          _buildRecentUnlocksSection(
                            state.newlyUnlockedAchievementIds,
                            state.newlyUnlockedBadgeIds,
                            state.achievements,
                            state.badges,
                            state.leaderboardDelta,
                          ),
                          AppSpacing.gapXxl,
                          _buildAchievementsSection(state.achievements),
                          AppSpacing.gapXxl,
                          _buildQuickQuizSection(state.availableQuizzes),
                          AppSpacing.gapXxl,
                          _buildLeaderboardSection(
                            state.leaderboardEntries,
                            state.isWeeklyRanking,
                            state.currentUserId,
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

  Widget _buildProgressSnapshot(
    XpProgressModel? xpProgress,
    NextBadgeProgressModel? nextBadge,
  ) {
    final theme = Theme.of(context);
    final progress = xpProgress?.levelProgressRatio ?? 0.0;
    final weekly = xpProgress?.weeklyProgressRatio ?? 0.0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppRadius.borderLg,
        boxShadow: AppShadows.subtle(theme.shadowColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.bolt_rounded,
                color: theme.colorScheme.primary,
                size: 22,
              ),
              AppSpacing.hGapSm,
              Text(
                xpProgress != null
                    ? 'Level ${xpProgress.level} • ${xpProgress.totalXp} XP'
                    : 'Level -- • -- XP',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          AppSpacing.gapMd,
          LinearProgressIndicator(value: progress, minHeight: 8),
          AppSpacing.gapXs,
          Text(
            xpProgress != null
                ? '${xpProgress.xpIntoCurrentLevel}/${xpProgress.xpNeededForNextLevel} XP to next level'
                : 'Progress unavailable',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          AppSpacing.gapMd,
          Text(
            'Weekly Sprint',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          AppSpacing.gapXs,
          LinearProgressIndicator(value: weekly, minHeight: 8),
          AppSpacing.gapXs,
          Text(
            xpProgress != null
                ? '${xpProgress.weeklyXpEarned}/${xpProgress.weeklyXpTarget} XP this week'
                : '--/-- XP this week',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (nextBadge != null) ...[
            AppSpacing.gapMd,
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                borderRadius: AppRadius.borderMd,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Next Unlock: ${nextBadge.badgeName}',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  AppSpacing.gapXxs,
                  Text(nextBadge.description, style: theme.textTheme.bodySmall),
                  AppSpacing.gapSm,
                  LinearProgressIndicator(
                    value: nextBadge.completionRatio,
                    minHeight: 7,
                  ),
                  AppSpacing.gapXxs,
                  Text(
                    '${nextBadge.progressCurrent}/${nextBadge.progressTarget} • +${nextBadge.xpReward} XP',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDailyMissionsSection(List<DailyMissionModel> missions) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Daily Missions',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
        AppSpacing.gapSm,
        if (missions.isEmpty)
          const EmptyStateWidget(
            illustration: TrophyIllustration(),
            icon: Icons.task_alt_rounded,
            title: 'No missions today',
            subtitle: 'New missions will appear soon.',
          )
        else
          ...List.generate(missions.length, (i) {
            final mission = missions[i];
            return StaggeredFadeSlide(
              index: i,
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: i < missions.length - 1 ? 8 : 0,
                ),
                child: _MissionTile(
                  mission: mission,
                  onComplete: mission.isCompleted
                      ? null
                      : () async {
                          await context
                              .read<GamificationCubit>()
                              .completeMission(mission.id);
                          if (!mounted) return;
                          CelebrationOverlay.maybeOf(context)?.celebrate(
                            type: CelebrationType.completion,
                            message: 'Mission Completed!',
                            subtext: '+${mission.xpReward} XP earned',
                          );
                        },
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildTeamChallengeSection(TeamChallengeModel? challenge) {
    final theme = Theme.of(context);
    if (challenge == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cooperative Challenge',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
        AppSpacing.gapSm,
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: AppRadius.borderLg,
            boxShadow: AppShadows.subtle(theme.shadowColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                challenge.title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              AppSpacing.gapXxs,
              Text(challenge.objective, style: theme.textTheme.bodySmall),
              AppSpacing.gapSm,
              LinearProgressIndicator(
                value: challenge.completionRatio,
                minHeight: 8,
              ),
              AppSpacing.gapXs,
              Text(
                '${challenge.progressCurrent}/${challenge.progressTarget} XP • ${challenge.contributorCount} classmates contributed',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
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
            height: 168,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: displayAchievements.length,
              separatorBuilder: (_, _) => AppSpacing.hGapMd,
              itemBuilder: (_, i) {
                final a = displayAchievements[i];
                return _AchievementShowcaseCard(
                  icon: BadgeVisuals.iconForAchievement(a),
                  label: a.title,
                  sublabel: a.isUnlocked ? 'Unlocked' : 'Locked',
                  color: BadgeVisuals.accentForAchievement(a, theme),
                  completion: a.completionRatio,
                  isUnlocked: a.isUnlocked,
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildRecentUnlocksSection(
    List<String> achievementIds,
    List<String> badgeIds,
    List<AchievementModel> achievements,
    List<BadgeModel> badges,
    int? leaderboardDelta,
  ) {
    final theme = Theme.of(context);
    final unlockedAchievementTitles = achievementIds
        .map((id) => _resolveAchievementTitle(id, achievements))
        .whereType<String>()
        .toList();
    final unlockedBadgeNames = badgeIds
        .map((id) => _resolveBadgeName(id, badges))
        .whereType<String>()
        .toList();
    final hasContent =
        unlockedAchievementTitles.isNotEmpty ||
        unlockedBadgeNames.isNotEmpty ||
        (leaderboardDelta != null && leaderboardDelta > 0);
    if (!hasContent) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppRadius.borderLg,
        boxShadow: AppShadows.subtle(theme.shadowColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recently Unlocked',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          AppSpacing.gapSm,
          if (unlockedAchievementTitles.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: achievementIds
                  .map((id) {
                    final match = achievements.where((a) => a.id == id);
                    if (match.isEmpty) return null;
                    final item = match.first;
                    return Chip(
                      avatar: Icon(
                        BadgeVisuals.iconForAchievement(item),
                        size: 18,
                      ),
                      label: Text(item.title),
                    );
                  })
                  .whereType<Widget>()
                  .toList(),
            ),
          if (unlockedAchievementTitles.isNotEmpty &&
              unlockedBadgeNames.isNotEmpty)
            AppSpacing.gapSm,
          if (unlockedBadgeNames.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: badgeIds.map((id) {
                final name = _resolveBadgeName(id, badges) ?? id;
                return Chip(
                  avatar: Icon(BadgeVisuals.iconForBadge(id), size: 18),
                  label: Text(name),
                );
              }).toList(),
            ),
          if (leaderboardDelta != null && leaderboardDelta > 0) ...[
            AppSpacing.gapSm,
            Text(
              'You climbed $leaderboardDelta place${leaderboardDelta == 1 ? '' : 's'} on the leaderboard.',
              style: theme.textTheme.labelLarge?.copyWith(
                color: AppColors.success,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
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
        else ...[
          Builder(
            builder: (_) {
              final recommended = availableQuizzes.first;
              return _RecommendedQuizCard(
                icon: _iconForSubject(recommended.subjectName),
                title: '${recommended.subjectName}: ${recommended.title}',
                questions: recommended.questionCount,
                xp: recommended.xpReward,
                difficulty: recommended.difficulty,
                onStart: () {
                  Navigator.of(context).pushNamed(
                    RouteNames.studentQuiz,
                    arguments: {'subjectId': recommended.subjectId},
                  );
                },
              );
            },
          ),
          if (availableQuizzes.length > 1) ...[
            AppSpacing.gapMd,
            Text(
              'More Quizzes',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            AppSpacing.gapSm,
            ...List.generate(availableQuizzes.length - 1, (i) {
              final quiz = availableQuizzes[i + 1];
              return StaggeredFadeSlide(
                index: i,
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: i < availableQuizzes.length - 2 ? 10 : 0,
                  ),
                  child: _QuickQuizTile(
                    icon: _iconForSubject(quiz.subjectName),
                    title: '${quiz.subjectName}: ${quiz.title}',
                    questions: quiz.questionCount,
                    xp: quiz.xpReward,
                    difficulty: quiz.difficulty,
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
        ],
      ],
    );
  }

  Widget _buildLeaderboardSection(
    List<LeaderboardEntry> leaderboardEntries,
    bool isWeeklyRanking,
    String currentUserId,
  ) {
    final theme = Theme.of(context);
    final sortedEntries = [...leaderboardEntries]
      ..sort((a, b) => a.rank.compareTo(b.rank));
    final topEntries = sortedEntries.take(3).toList();
    final myEntry = leaderboardEntries.firstWhere(
      (entry) => entry.studentId == currentUserId,
      orElse: () => const LeaderboardEntry(
        studentId: '',
        studentName: 'You',
        rank: 0,
        points: 0,
      ),
    );
    final aheadEntry = myEntry.rank > 1
        ? _entryByRank(sortedEntries, myEntry.rank - 1)
        : null;
    final pointsToNext = aheadEntry != null
        ? (aheadEntry.points - myEntry.points).clamp(0, 99999)
        : 0;
    final chasingEntries = sortedEntries
        .where((entry) => entry.rank > myEntry.rank)
        .take(3)
        .toList();
    final chasingNames = chasingEntries.map((e) => e.studentName).toList();
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
        if (myEntry.rank > 0)
          _LeaderboardMomentumCard(
            rank: myEntry.rank,
            points: myEntry.points,
            pointsToNext: pointsToNext,
          ),
        if (chasingNames.isNotEmpty) ...[
          AppSpacing.gapSm,
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: AppRadius.borderLg,
              boxShadow: AppShadows.subtle(theme.shadowColor),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.groups_rounded,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                AppSpacing.hGapSm,
                Expanded(
                  child: Text(
                    'Team Sprint: ${_formatChasingNames(chasingNames)} are close behind.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          AppSpacing.gapMd,
        ],
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
                  userId: entry.studentId,
                  classLabel: '',
                  xp: '${entry.points} XP',
                  avatarColor: avatarColors[i % avatarColors.length],
                  rankColor: rankColors[i % rankColors.length],
                  isTopSpot: entry.rank == 1,
                ),
              ),
            );
          }),
      ],
    );
  }
}

class _AchievementShowcaseCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final Color color;
  final double completion;
  final bool isUnlocked;

  const _AchievementShowcaseCard({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.color,
    required this.completion,
    required this.isUnlocked,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 128,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppRadius.borderLg,
        border: Border.all(
          color: isUnlocked
              ? color.withAlpha(95)
              : theme.colorScheme.outlineVariant,
          width: 1.2,
        ),
        boxShadow: AppShadows.subtle(theme.shadowColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isUnlocked
                  ? color.withAlpha(28)
                  : theme.colorScheme.surfaceContainerLow,
              borderRadius: AppRadius.borderMd,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  icon,
                  color: isUnlocked
                      ? color
                      : theme.colorScheme.onSurfaceVariant,
                  size: 24,
                ),
                if (!isUnlocked)
                  Positioned(
                    right: 2,
                    bottom: 2,
                    child: Icon(
                      Icons.lock_rounded,
                      size: 12,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          AppSpacing.gapSm,
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          AppSpacing.gapXxs,
          Text(
            sublabel,
            style: theme.textTheme.labelSmall?.copyWith(
              color: isUnlocked
                  ? AppColors.success
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
          AppSpacing.gapXs,
          LinearProgressIndicator(value: completion, minHeight: 5),
        ],
      ),
    );
  }
}

class _QuickQuizTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final int questions;
  final int xp;
  final String difficulty;
  final VoidCallback onStart;

  const _QuickQuizTile({
    required this.icon,
    required this.title,
    required this.questions,
    required this.xp,
    required this.difficulty,
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
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withAlpha(120),
        ),
        boxShadow: AppShadows.subtle(theme.shadowColor),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              borderRadius: AppRadius.borderSm,
            ),
            child: Icon(
              icon,
              color: theme.colorScheme.onSurfaceVariant,
              size: 20,
            ),
          ),
          AppSpacing.hGapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                AppSpacing.gapXxs,
                Text(
                  '$questions Questions  •  $xp XP  •  $difficulty',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          FilledButton.tonalIcon(
            onPressed: onStart,
            style: FilledButton.styleFrom(
              foregroundColor: theme.colorScheme.primary,
              backgroundColor: theme.colorScheme.primaryContainer.withAlpha(80),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: AppRadius.borderSm),
            ),
            icon: const Icon(Icons.play_arrow_rounded, size: 18),
            label: const Text('Start'),
          ),
        ],
      ),
    );
  }
}

class _RecommendedQuizCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final int questions;
  final int xp;
  final String difficulty;
  final VoidCallback onStart;

  const _RecommendedQuizCard({
    required this.icon,
    required this.title,
    required this.questions,
    required this.xp,
    required this.difficulty,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppRadius.borderLg,
        border: Border.all(color: theme.colorScheme.primary.withAlpha(70)),
        boxShadow: AppShadows.subtle(theme.shadowColor),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 430;
          final titleText = Text(
            title,
            maxLines: compact ? 3 : 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          );

          final metaText = Text(
            '$questions Questions  •  $xp XP  •  $difficulty',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          );

          final cta = ElevatedButton.icon(
            onPressed: onStart,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: theme.colorScheme.onPrimary,
              shape: RoundedRectangleBorder(borderRadius: AppRadius.borderSm),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              textStyle: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            icon: const Icon(Icons.play_arrow_rounded, size: 18),
            label: const Text('Start'),
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer.withAlpha(
                          120,
                        ),
                        borderRadius: AppRadius.borderMd,
                      ),
                      child: Icon(icon, color: theme.colorScheme.primary),
                    ),
                    AppSpacing.hGapMd,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Recommended Quick Quiz',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: AppColors.success,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          AppSpacing.gapXxs,
                          titleText,
                          AppSpacing.gapXxs,
                          metaText,
                        ],
                      ),
                    ),
                  ],
                ),
                AppSpacing.gapMd,
                Align(alignment: Alignment.centerRight, child: cta),
              ],
            );
          }

          return Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withAlpha(120),
                  borderRadius: AppRadius.borderMd,
                ),
                child: Icon(icon, color: theme.colorScheme.primary),
              ),
              AppSpacing.hGapMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recommended Quick Quiz',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    AppSpacing.gapXxs,
                    titleText,
                    AppSpacing.gapXxs,
                    metaText,
                  ],
                ),
              ),
              AppSpacing.hGapMd,
              cta,
            ],
          );
        },
      ),
    );
  }
}

class _LeaderboardMomentumCard extends StatelessWidget {
  final int rank;
  final int points;
  final int pointsToNext;

  const _LeaderboardMomentumCard({
    required this.rank,
    required this.points,
    required this.pointsToNext,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTop = rank == 1;
    final subtitle = isTop
        ? 'You are #1 with $points XP'
        : 'You are #$rank with $points XP ($pointsToNext XP to next rank)';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withAlpha(90),
        borderRadius: AppRadius.borderLg,
        border: Border.all(color: theme.colorScheme.primary.withAlpha(70)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: AppRadius.borderMd,
            ),
            child: Icon(
              isTop ? Icons.shield_rounded : Icons.trending_up_rounded,
              color: theme.colorScheme.primary,
            ),
          ),
          AppSpacing.hGapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isTop ? 'Defending #1' : 'Momentum Building',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                AppSpacing.gapXxs,
                Text(subtitle, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  final int rank;
  final String name;
  final String userId;
  final String classLabel;
  final String xp;
  final Color avatarColor;
  final Color rankColor;
  final bool isTopSpot;

  const _LeaderboardRow({
    required this.rank,
    required this.name,
    required this.userId,
    required this.classLabel,
    required this.xp,
    required this.avatarColor,
    required this.rankColor,
    this.isTopSpot = false,
  });

  IconData _rankIcon() {
    switch (rank) {
      case 1:
        return Icons.emoji_events_rounded;
      case 2:
        return Icons.workspace_premium_rounded;
      case 3:
        return Icons.military_tech_rounded;
      default:
        return Icons.tag_rounded;
    }
  }

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
        border: Border.all(
          color: isTopSpot
              ? rankColor.withAlpha(150)
              : theme.colorScheme.outlineVariant.withAlpha(100),
        ),
        boxShadow: AppShadows.subtle(theme.shadowColor),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: rankColor.withAlpha(24),
              borderRadius: AppRadius.borderMd,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(_rankIcon(), color: rankColor, size: 18),
                Positioned(
                  bottom: 2,
                  right: 3,
                  child: Text(
                    '$rank',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: rankColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          AppSpacing.hGapMd,
          ProfileAvatar(
            radius: 17,
            userId: userId,
            fallbackText: name,
          ),
          AppSpacing.hGapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withAlpha(90),
              borderRadius: AppRadius.borderSm,
            ),
            child: Text(
              xp,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MissionTile extends StatelessWidget {
  final DailyMissionModel mission;
  final VoidCallback? onComplete;

  const _MissionTile({required this.mission, this.onComplete});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppRadius.borderMd,
        boxShadow: AppShadows.subtle(theme.shadowColor),
      ),
      child: Row(
        children: [
          Icon(
            mission.isCompleted
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            color: mission.isCompleted
                ? AppColors.success
                : theme.colorScheme.onSurfaceVariant,
          ),
          AppSpacing.hGapSm,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mission.title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                AppSpacing.gapXxs,
                Text(
                  mission.description,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                AppSpacing.gapXs,
                LinearProgressIndicator(
                  value: mission.completionRatio,
                  minHeight: 6,
                ),
                AppSpacing.gapXxs,
                Text(
                  '${mission.progressCurrent}/${mission.progressTarget} • +${mission.xpReward} XP',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (!mission.isCompleted)
            TextButton(onPressed: onComplete, child: const Text('Complete')),
        ],
      ),
    );
  }
}
