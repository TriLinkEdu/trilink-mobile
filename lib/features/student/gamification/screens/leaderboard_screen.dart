import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
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
            return const Center(child: CircularProgressIndicator());
          }
          if (state.entries.isEmpty) {
            return const Center(child: Text('No leaderboard data available.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: state.entries.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final entry = state.entries[index];
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant,
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor:
                          theme.colorScheme.surfaceContainerLow,
                      child: Text(
                        '${entry.rank}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        entry.studentName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text('${entry.points} XP'),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
