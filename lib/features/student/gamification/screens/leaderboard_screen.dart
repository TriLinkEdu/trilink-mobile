import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trilink_mobile/core/widgets/empty_state_widget.dart';
import 'package:trilink_mobile/core/widgets/illustrations.dart';
import 'package:trilink_mobile/core/widgets/staggered_animation.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../cubit/leaderboard_cubit.dart';
import '../repositories/student_gamification_repository.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          LeaderboardCubit(sl<StudentGamificationRepository>())..loadLeaderboard(),
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
            onPressed: () =>
                context.read<LeaderboardCubit>().togglePeriod(),
            child: BlocBuilder<LeaderboardCubit, LeaderboardState>(
              builder: (context, state) =>
                  Text(state.weekly ? 'Weekly' : 'Monthly'),
            ),
          ),
        ],
      ),
      body: BlocBuilder<LeaderboardCubit, LeaderboardState>(
        builder: (context, state) {
          final loading = state.status == LeaderboardStatus.initial ||
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
          return ListView.separated(
            padding: AppSpacing.paddingLg,
            itemCount: state.entries.length,
            separatorBuilder: (_, _) => AppSpacing.gapSm,
            itemBuilder: (context, index) {
              final entry = state.entries[index];
              return StaggeredFadeSlide(
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
                        backgroundColor:
                            theme.colorScheme.surfaceContainerLow,
                        child: Text(
                          '${entry.rank}',
                          style: theme.textTheme.bodySmall,
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
              );
            },
          );
        },
      ),
    );
  }
}
