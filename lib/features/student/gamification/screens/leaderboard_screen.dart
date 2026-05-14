import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trilink_mobile/core/widgets/empty_state_widget.dart';
import 'package:trilink_mobile/core/widgets/illustrations.dart';
import 'package:trilink_mobile/core/widgets/staggered_animation.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../../shared/widgets/student_page_background.dart';
import '../cubit/leaderboard_cubit.dart';
import '../models/gamification_models.dart';
import '../repositories/student_gamification_repository.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          LeaderboardCubit(sl<StudentGamificationRepository>())..loadIfNeeded(),
      child: const _LeaderboardView(),
    );
  }
}

class _LeaderboardView extends StatefulWidget {
  const _LeaderboardView();

  @override
  State<_LeaderboardView> createState() => _LeaderboardViewState();
}

class _LeaderboardViewState extends State<_LeaderboardView> {
  String _currentUserId = '';
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 50) {
      context.read<LeaderboardCubit>().loadMoreLeaderboard();
    }
  }

  Future<void> _loadCurrentUser() async {
    final user = await sl<StorageService>().getUser();
    if (mounted) {
      setState(() {
        _currentUserId = (user?['id'] ?? '').toString();
      });
    }
  }

  String _periodLabel(bool weekly) => weekly ? 'Weekly' : 'Monthly';

  LeaderboardEntry _entryByRank(List<LeaderboardEntry> entries, int rank) {
    return entries.firstWhere(
      (entry) => entry.rank == rank,
      orElse: () => const LeaderboardEntry(
        studentId: 'none',
        studentName: '-',
        rank: 0,
        points: 0,
      ),
    );
  }

  Color _rankAccent(int rank) {
    switch (rank) {
      case 1:
        return AppColors.rankGold;
      case 2:
        return AppColors.rankSilver;
      case 3:
        return AppColors.rankBronze;
      default:
        return AppColors.primary;
    }
  }

  IconData _rankIcon(int rank) {
    switch (rank) {
      case 1:
        return Icons.workspace_premium_rounded;
      case 2:
        return Icons.military_tech_rounded;
      case 3:
        return Icons.emoji_events_rounded;
      default:
        return Icons.arrow_upward_rounded;
    }
  }

  String _chasingLabel(List<LeaderboardEntry> entries, LeaderboardEntry you) {
    final ahead = entries.where((entry) => entry.rank < you.rank).toList();
    if (ahead.isEmpty) return 'You are setting the pace for everyone.';

    final names = ahead.take(2).map((entry) => entry.studentName).toList();
    final joined = names.length == 1
        ? names.first
        : '${names.first} and ${names.last}';
    if (ahead.length <= 2) return '$joined are just ahead of you.';
    return '$joined and others are within reach this week.';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard'),
        actions: [
          BlocBuilder<LeaderboardCubit, LeaderboardState>(
            builder: (context, state) {
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: FilledButton.tonalIcon(
                  onPressed: () =>
                      context.read<LeaderboardCubit>().togglePeriod(),
                  icon: const Icon(Icons.calendar_month_rounded, size: 18),
                  label: Text(_periodLabel(state.weekly)),
                ),
              );
            },
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
            final entries = [...state.entries]
              ..sort((a, b) => a.rank.compareTo(b.rank));

            final yourRank = entries.firstWhere(
              (entry) => entry.studentId == _currentUserId,
              orElse: () => entries.first,
            );
            final leader = entries.first;
            final yourGap = (leader.points - yourRank.points).clamp(0, 9999);
            LeaderboardEntry? nextUp;
            for (final entry in entries) {
              if (entry.rank == yourRank.rank - 1) {
                nextUp = entry;
                break;
              }
            }
            final leapGap = nextUp == null
                ? 0
                : (nextUp.points - yourRank.points).clamp(0, 9999);
            final teamProgress =
                entries.take(5).fold<int>(0, (sum, e) => sum + e.points) /
                2500;

            return RefreshIndicator(
              onRefresh: () =>
                  context.read<LeaderboardCubit>().loadLeaderboard(),
              child: ListView(
                controller: _scrollController,
                padding: AppSpacing.paddingLg,
                children: [
                  // ── Your position hero card ──────────────────────
                  Container(
                    padding: AppSpacing.paddingLg,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primary.withAlpha(220),
                          AppColors.levelPurple.withAlpha(220),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: AppRadius.borderLg,
                      boxShadow: AppShadows.elevated(theme.shadowColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(34),
                                borderRadius: AppRadius.borderMd,
                              ),
                              child: const Icon(
                                Icons.insights_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            AppSpacing.hGapSm,
                            Expanded(
                              child: Text(
                                '${_periodLabel(state.weekly)} Sprint',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(34),
                                borderRadius: BorderRadius.circular(
                                  AppRadius.full,
                                ),
                              ),
                              child: Text(
                                '#${yourRank.rank}',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        AppSpacing.gapMd,
                        Text(
                          '${yourRank.points} XP collected',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        AppSpacing.gapXs,
                        Text(
                          yourRank.rank == 1
                              ? 'You are leading by $yourGap XP. Keep your pace strong.'
                              : 'Only $leapGap XP to overtake #${nextUp?.rank ?? yourRank.rank - 1}.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white.withAlpha(215),
                          ),
                        ),
                        AppSpacing.gapMd,
                        ClipRRect(
                          borderRadius:
                              BorderRadius.circular(AppRadius.full),
                          child: LinearProgressIndicator(
                            minHeight: 8,
                            value: yourRank.rank == 1
                                ? 1
                                : ((1 - (leapGap / 300)).clamp(
                                    0.08,
                                    0.95,
                                  )).toDouble(),
                            backgroundColor: Colors.white.withAlpha(40),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        ),
                        AppSpacing.gapXs,
                        Text(
                          _chasingLabel(entries, yourRank),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.white.withAlpha(215),
                          ),
                        ),
                      ],
                    ),
                  ),
                  AppSpacing.gapMd,

                  // ── Class team sprint ────────────────────────────
                  Container(
                    padding: AppSpacing.paddingMd,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: AppRadius.borderLg,
                      boxShadow: AppShadows.card(theme.shadowColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Class Team Sprint',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        AppSpacing.gapSm,
                        LinearProgressIndicator(
                          value: teamProgress.clamp(0, 1),
                          minHeight: 8,
                          backgroundColor:
                              theme.colorScheme.surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            theme.colorScheme.secondary,
                          ),
                        ),
                        AppSpacing.gapSm,
                        Row(
                          children: [
                            Icon(
                              Icons.groups_2_rounded,
                              size: 16,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            AppSpacing.hGapXs,
                            Expanded(
                              child: Text(
                                'Top 5 combined XP toward 2,500 target',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                            Text(
                              '${(teamProgress * 100).clamp(0, 100).toStringAsFixed(0)}%',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.secondary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  AppSpacing.gapMd,

                  // ── Top 3 podium ─────────────────────────────────
                  Container(
                    padding: AppSpacing.paddingMd,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: AppRadius.borderLg,
                      boxShadow: AppShadows.card(theme.shadowColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Top Performers',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        AppSpacing.gapMd,
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: _TopRankPillar(
                                entry: _entryByRank(entries, 2),
                                accent: _rankAccent(2),
                                icon: _rankIcon(2),
                                height: 92,
                              ),
                            ),
                            AppSpacing.hGapSm,
                            Expanded(
                              child: _TopRankPillar(
                                entry: _entryByRank(entries, 1),
                                accent: _rankAccent(1),
                                icon: _rankIcon(1),
                                height: 116,
                                highlighted: true,
                              ),
                            ),
                            AppSpacing.hGapSm,
                            Expanded(
                              child: _TopRankPillar(
                                entry: _entryByRank(entries, 3),
                                accent: _rankAccent(3),
                                icon: _rankIcon(3),
                                height: 82,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  AppSpacing.gapMd,

                  // ── Full ranked list ─────────────────────────────
                  ...List.generate(entries.length, (index) {
                    final entry = entries[index];
                    final isMe = entry.studentId == _currentUserId;
                    final rankColor = _rankAccent(entry.rank);
                    final gapFromLeader =
                        (leader.points - entry.points).clamp(0, 9999);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: StaggeredFadeSlide(
                        index: index,
                        child: Container(
                          padding: AppSpacing.paddingMd,
                          decoration: BoxDecoration(
                            color: isMe
                                ? theme.colorScheme.primary.withAlpha(16)
                                : theme.colorScheme.surface,
                            borderRadius: AppRadius.borderLg,
                            border: Border.all(
                              color: isMe
                                  ? theme.colorScheme.primary.withAlpha(60)
                                  : theme.colorScheme.outlineVariant
                                      .withAlpha(70),
                            ),
                            boxShadow: AppShadows.subtle(theme.shadowColor),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: rankColor.withAlpha(30),
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.full,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    '${entry.rank}',
                                    style:
                                        theme.textTheme.labelLarge?.copyWith(
                                      color: rankColor,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                              AppSpacing.hGapSm,
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isMe
                                          ? '${entry.studentName} (You)'
                                          : entry.studentName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style:
                                          theme.textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      gapFromLeader == 0
                                          ? 'Current leader'
                                          : '$gapFromLeader XP behind #1',
                                      style:
                                          theme.textTheme.labelSmall?.copyWith(
                                        color:
                                            theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${entry.points} XP',
                                    style:
                                        theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                  if (index > 0)
                                    Text(
                                      'vs #${entries[index - 1].rank}: '
                                      '${(entries[index - 1].points - entry.points).clamp(0, 9999)} XP',
                                      style:
                                          theme.textTheme.labelSmall?.copyWith(
                                        color:
                                            theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _TopRankPillar extends StatelessWidget {
  final LeaderboardEntry entry;
  final Color accent;
  final IconData icon;
  final double height;
  final bool highlighted;

  const _TopRankPillar({
    required this.entry,
    required this.accent,
    required this.icon,
    required this.height,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (entry.rank == 0) {
      return const SizedBox.shrink();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: highlighted ? 56 : 48,
          height: highlighted ? 56 : 48,
          decoration: BoxDecoration(
            color: accent.withAlpha(highlighted ? 42 : 28),
            borderRadius: BorderRadius.circular(AppRadius.full),
            border: Border.all(color: accent.withAlpha(120)),
          ),
          child: Icon(icon, color: accent, size: highlighted ? 28 : 24),
        ),
        AppSpacing.gapXs,
        Text(
          entry.studentName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          '${entry.points} XP',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        AppSpacing.gapXs,
        Container(
          width: double.infinity,
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [accent.withAlpha(170), accent.withAlpha(95)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          alignment: Alignment.center,
          child: Text(
            '#${entry.rank}',
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}
