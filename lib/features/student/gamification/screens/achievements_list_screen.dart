import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trilink_mobile/core/widgets/staggered_animation.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../../shared/widgets/student_page_background.dart';
import '../cubit/achievements_list_cubit.dart';
import '../models/gamification_models.dart';
import '../repositories/student_gamification_repository.dart';
import '../widgets/badge_visuals.dart';

class AchievementsListScreen extends StatelessWidget {
  const AchievementsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          AchievementsListCubit(sl<StudentGamificationRepository>())
            ..loadIfNeeded(),
      child: const _AchievementsListView(),
    );
  }
}

class _AchievementsListView extends StatelessWidget {
  const _AchievementsListView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Achievements'), centerTitle: true),
      body: StudentPageBackground(
        child: BlocBuilder<AchievementsListCubit, AchievementsListState>(
          builder: (context, state) {
            final loading =
                state.status == AchievementsListStatus.initial ||
                state.status == AchievementsListStatus.loading;
            if (loading) {
              return const Padding(
                padding: AppSpacing.paddingLg,
                child: ShimmerList(itemCount: 6, itemHeight: 72),
              );
            }

            final unlocked = state.achievements
                .where((a) => a.isUnlocked)
                .toList();
            final locked = state.achievements
                .where((a) => !a.isUnlocked)
                .toList();

            final grouped = <AchievementCategory, List<AchievementModel>>{
              for (final category in AchievementCategory.values)
                category: state.achievements
                    .where((a) => a.category == category)
                    .toList(),
            };

            return ListView(
              padding: AppSpacing.paddingLg,
              children: [
                Container(
                  padding: AppSpacing.paddingMd,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerLow,
                    borderRadius: AppRadius.borderMd,
                  ),
                  child: Text(
                    'Each badge is awarded once per student. If already earned, duplicate awards are skipped automatically.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                if (unlocked.isNotEmpty) ...[
                  Text(
                    'Unlocked (${unlocked.length})',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  AppSpacing.gapSm,
                  for (var i = 0; i < unlocked.length; i++)
                    StaggeredFadeSlide(
                      index: i,
                      child: _AchievementTile(achievement: unlocked[i]),
                    ),
                  AppSpacing.gapXxl,
                ],
                if (locked.isNotEmpty) ...[
                  Text(
                    'Locked (${locked.length})',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  AppSpacing.gapSm,
                  for (var i = 0; i < locked.length; i++)
                    StaggeredFadeSlide(
                      index: unlocked.length + i,
                      child: _AchievementTile(achievement: locked[i]),
                    ),
                ],
                AppSpacing.gapXxl,
                Text(
                  'Categories',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                AppSpacing.gapSm,
                for (final category in AchievementCategory.values)
                  if ((grouped[category] ?? const <AchievementModel>[])
                      .isNotEmpty)
                    _CategoryProgressCard(
                      category: category,
                      achievements: grouped[category]!,
                    ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _AchievementTile extends StatelessWidget {
  final AchievementModel achievement;
  const _AchievementTile({required this.achievement});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUnlocked = achievement.isUnlocked;
    final color = BadgeVisuals.accentForAchievement(achievement, theme);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isUnlocked
                ? color.withAlpha(38)
                : theme.colorScheme.surfaceContainerHighest,
            borderRadius: AppRadius.borderMd,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                BadgeVisuals.iconForAchievement(achievement),
                color: isUnlocked ? color : theme.colorScheme.onSurfaceVariant,
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
        title: Text(
          achievement.title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isUnlocked ? null : theme.colorScheme.onSurfaceVariant,
          ),
        ),
        subtitle: Text(
          isUnlocked
              ? achievement.description
              : '${achievement.description}\nProgress: ${achievement.progressCurrent}/${achievement.progressTarget}',
          style: TextStyle(
            color: isUnlocked
                ? null
                : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
          ),
        ),
        trailing: isUnlocked
            ? const Icon(Icons.check_circle_rounded, color: AppColors.success)
            : null,
      ),
    );
  }
}

class _CategoryProgressCard extends StatelessWidget {
  final AchievementCategory category;
  final List<AchievementModel> achievements;

  const _CategoryProgressCard({
    required this.category,
    required this.achievements,
  });

  String _title() {
    switch (category) {
      case AchievementCategory.consistency:
        return 'Consistency';
      case AchievementCategory.mastery:
        return 'Mastery';
      case AchievementCategory.social:
        return 'Social';
      case AchievementCategory.exploration:
        return 'Exploration';
      case AchievementCategory.milestone:
        return 'Milestones';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unlocked = achievements.where((a) => a.isUnlocked).length;
    final ratio = achievements.isEmpty ? 0.0 : unlocked / achievements.length;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: AppSpacing.paddingMd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _title(),
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            AppSpacing.gapXs,
            LinearProgressIndicator(value: ratio, minHeight: 7),
            AppSpacing.gapXxs,
            Text(
              '$unlocked/${achievements.length} unlocked',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
