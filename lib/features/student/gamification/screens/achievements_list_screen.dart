import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trilink_mobile/core/widgets/staggered_animation.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../cubit/achievements_list_cubit.dart';
import '../models/gamification_models.dart';
import '../repositories/student_gamification_repository.dart';

class AchievementsListScreen extends StatelessWidget {
  const AchievementsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AchievementsListCubit(sl<StudentGamificationRepository>())
        ..loadAchievements(),
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
      body: BlocBuilder<AchievementsListCubit, AchievementsListState>(
        builder: (context, state) {
          final loading = state.status == AchievementsListStatus.initial ||
              state.status == AchievementsListStatus.loading;
          if (loading) {
            return const Padding(
              padding: AppSpacing.paddingLg,
              child: ShimmerList(itemCount: 6, itemHeight: 72),
            );
          }
          final unlocked =
              state.achievements.where((a) => a.isUnlocked).toList();
          final locked =
              state.achievements.where((a) => !a.isUnlocked).toList();

          return ListView(
            padding: AppSpacing.paddingLg,
            children: [
              if (unlocked.isNotEmpty) ...[
                Text('Unlocked (${unlocked.length})',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                AppSpacing.gapSm,
                for (var i = 0; i < unlocked.length; i++)
                  StaggeredFadeSlide(
                    index: i,
                    child: _AchievementTile(achievement: unlocked[i]),
                  ),
                AppSpacing.gapXxl,
              ],
              if (locked.isNotEmpty) ...[
                Text('Locked (${locked.length})',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                AppSpacing.gapSm,
                for (var i = 0; i < locked.length; i++)
                  StaggeredFadeSlide(
                    index: unlocked.length + i,
                    child: _AchievementTile(achievement: locked[i]),
                  ),
              ],
            ],
          );
        },
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

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isUnlocked
                ? AppColors.leaderboardCrown.withAlpha(38)
                : theme.colorScheme.surfaceContainerHighest,
            borderRadius: AppRadius.borderMd,
          ),
          child: Icon(
            isUnlocked ? Icons.emoji_events_rounded : Icons.lock_rounded,
            color: isUnlocked ? AppColors.leaderboardCrown : theme.colorScheme.onSurfaceVariant,
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
          achievement.description,
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
