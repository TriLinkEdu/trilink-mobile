import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trilink_mobile/core/widgets/empty_state_widget.dart';
import 'package:trilink_mobile/core/widgets/illustrations.dart';
import 'package:trilink_mobile/core/widgets/staggered_animation.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../../shared/widgets/student_page_background.dart';
import '../cubit/leaderboard_cubit.dart';
import '../repositories/student_gamification_repository.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          LeaderboardCubit(sl<StudentGamificationRepository>())
            ..loadLeaderboard(),
      child: const _LeaderboardView(),
    );
  }
}

class _LeaderboardView extends StatelessWidget {
  const _LeaderboardView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard'),
        actions: [
          TextButton(
            onPressed: () => context.read<LeaderboardCubit>().togglePeriod(),
            child: BlocBuilder<LeaderboardCubit, LeaderboardState>(
              builder: (context, state) =>
                  Text(state.weekly ? 'Weekly' : 'Monthly'),
            ),
          ),
        ],
      ),
      body: StudentPageBackground(
        child: BlocBuilder<LeaderboardCubit, LeaderboardState>(
          builder: (context, state) {
            final loading =
                state.status == LeaderboardStatus.initial ||
                state.status == LeaderboardStatus.loading;
            if (loading) {
              return const Padding(
                padding: AppSpacing.paddingLg,
                child: ShimmerList(itemCount: 8, itemHeight: 56),
              );
            }
            if (state.entries.isEmpty) {
              return const EmptyStateWidget(
                illustration: TrophyIllustration(),
                icon: Icons.leaderboard_rounded,
                title: 'No leaderboard data',
                subtitle: 'Rankings will appear here once available.',
              );
            }
            final yourRank = state.entries.firstWhere(
              (e) => e.studentId == 's1',
              orElse: () => state.entries.first,
            );
            final teamProgress =
                state.entries.take(5).fold<int>(0, (sum, e) => sum + e.points) /
                2500;
            return ListView(
              padding: AppSpacing.paddingLg,
              children: [
                Container(
                  padding: AppSpacing.paddingMd,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: AppRadius.borderMd,
                    boxShadow: AppShadows.subtle(theme.shadowColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Position',
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      AppSpacing.gapXxs,
                      Text(
                        '#${yourRank.rank} • ${yourRank.points} XP',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      AppSpacing.gapSm,
                      Text(
                        'Tip: Complete one hard quiz (+60 XP) and one mission (+80 XP) to likely climb at least one rank.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                AppSpacing.gapMd,
                Container(
                  padding: AppSpacing.paddingMd,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: AppRadius.borderMd,
                    boxShadow: AppShadows.subtle(theme.shadowColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Class Team Sprint',
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      AppSpacing.gapXs,
                      LinearProgressIndicator(
                        value: teamProgress.clamp(0, 1),
                        minHeight: 8,
                      ),
                      AppSpacing.gapXxs,
                      Text(
                        'Top 5 combined XP toward 2,500 target',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                AppSpacing.gapMd,
                ...List.generate(state.entries.length, (index) {
                  final entry = state.entries[index];
                  final isTopThree = entry.rank <= 3;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: StaggeredFadeSlide(
                      index: index,
                      child: Container(
                        padding: AppSpacing.paddingMd,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: AppRadius.borderMd,
                          boxShadow: AppShadows.subtle(theme.shadowColor),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: isTopThree
                                  ? AppColors.leaderboardCrown.withAlpha(28)
                                  : theme.colorScheme.surfaceContainerLow,
                              child: Text(
                                '${entry.rank}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: isTopThree
                                      ? AppColors.leaderboardCrown
                                      : theme.colorScheme.onSurface,
                                ),
                              ),
                            ),
                            AppSpacing.hGapSm,
                            Expanded(
                              child: Text(
                                entry.studentName,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Text(
                              '${entry.points} XP',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            );
          },
        ),
      ),
    );
  }
}
