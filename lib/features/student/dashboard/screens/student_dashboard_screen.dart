import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' as intl;
import 'package:trilink_mobile/core/widgets/animated_counter.dart';
import 'package:trilink_mobile/core/widgets/branded_refresh.dart';
import 'package:trilink_mobile/core/widgets/error_widget.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/routes/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/pressable.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../../../../core/widgets/staggered_animation.dart';
import '../../../auth/cubit/auth_cubit.dart';
import '../widgets/student_shell_scope.dart';
import '../cubit/dashboard_cubit.dart';
import '../models/dashboard_data_model.dart';
import '../repositories/student_dashboard_repository.dart';

class StudentDashboardScreen extends StatelessWidget {
  const StudentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          DashboardCubit(sl<StudentDashboardRepository>())..loadDashboard(),
      child: const _DashboardView(),
    );
  }
}

class _DashboardView extends StatelessWidget {
  const _DashboardView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardCubit, DashboardState>(
      builder: (context, state) {
        if (state.status == DashboardStatus.loading ||
            state.status == DashboardStatus.initial) {
          return const _DashboardSkeleton();
        }

        if (state.status == DashboardStatus.error) {
          return Scaffold(
            body: AppErrorWidget(
              message: state.errorMessage ?? 'Something went wrong',
              onRetry: () => context.read<DashboardCubit>().loadDashboard(),
            ),
          );
        }

        return _DashboardContent(data: state.data!);
      },
    );
  }
}

// ── Skeleton Loading ──

class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.paddingXl,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppSpacing.gapLg,
              const ShimmerLoading(width: 120, height: 14),
              AppSpacing.gapSm,
              const ShimmerLoading(width: 200, height: 24),
              AppSpacing.gapXxl,
              Row(
                children: [
                  Expanded(child: ShimmerLoading(height: 90, borderRadius: AppRadius.borderLg)),
                  AppSpacing.hGapMd,
                  Expanded(child: ShimmerLoading(height: 90, borderRadius: AppRadius.borderLg)),
                  AppSpacing.hGapMd,
                  Expanded(child: ShimmerLoading(height: 90, borderRadius: AppRadius.borderLg)),
                ],
              ),
              AppSpacing.gapXxl,
              ShimmerLoading(height: 120, borderRadius: AppRadius.borderLg),
              AppSpacing.gapXl,
              const ShimmerLoading(width: 140, height: 18),
              AppSpacing.gapMd,
              const ShimmerList(itemCount: 3, itemHeight: 56),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Main Content ──

class _DashboardContent extends StatelessWidget {
  final DashboardDataModel data;

  const _DashboardContent({required this.data});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateStr = intl.DateFormat('EEEE, MMM dd').format(now);
    final hour = now.hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';
    final userName =
        context.read<AuthCubit>().currentUser?.name ?? 'Student';
    final firstName = userName.split(' ').first;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: BrandedRefreshIndicator(
          onRefresh: () => context.read<DashboardCubit>().loadDashboard(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: StaggeredColumn(
              children: [
                _HeroGreeting(
                  date: dateStr,
                  greeting: greeting,
                  name: firstName,
                  subtitle: _buildContextualGreeting(data),
                  onProfileTap: () => Navigator.of(context)
                      .pushNamed(RouteNames.studentProfile),
                ),
                AppSpacing.gapXl,

                _GamificationRow(
                  streak: data.stats.streakDays,
                  xp: data.stats.totalXp,
                  level: data.stats.level,
                  levelTitle: data.stats.levelTitle,
                  onTap: () => Navigator.of(context)
                      .pushNamed(RouteNames.studentGamification),
                ),
                AppSpacing.gapXxl,

                if (data.nextUp != null) ...[
                  _SectionHeader(
                    title: 'Next Up',
                    actionLabel: 'Calendar',
                    onAction: () => Navigator.of(context)
                        .pushNamed(RouteNames.studentCalendar),
                  ),
                  AppSpacing.gapMd,
                  _NextUpCard(data: data.nextUp!),
                  AppSpacing.gapXxl,
                ],

                _SectionHeader(
                  title: 'Quick Actions',
                  actionLabel: 'All',
                  onAction: () =>
                      StudentShellScope.of(context).openDrawer(),
                ),
                AppSpacing.gapMd,
                _QuickActionsRow(),
                AppSpacing.gapXxl,

                _SectionHeader(
                  title: 'Announcements',
                  actionLabel: 'See All',
                  onAction: () => Navigator.of(context)
                      .pushNamed(RouteNames.studentAnnouncements),
                ),
                AppSpacing.gapMd,
                ...data.recentAnnouncements.map((a) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _AnnouncementCard(
                        authorName: a.authorName,
                        snippet: a.snippet,
                        createdAt: a.createdAt,
                        onTap: () => Navigator.of(context).pushNamed(
                          RouteNames.studentAnnouncementDetail,
                          arguments: {'announcementId': a.id},
                        ),
                      ),
                    )),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        tooltip: 'AI Assistant',
        onPressed: () =>
            Navigator.of(context).pushNamed(RouteNames.studentAiAssistant),
        child: Hero(
          tag: 'ai-tutor-hero',
          child: Material(
            color: Colors.transparent,
            child: Icon(
              Icons.auto_awesome,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Hero Greeting ──

/// Short line under the hero name. Priority: streak → upcoming [nextUp] → recent grade → default.
String _buildContextualGreeting(DashboardDataModel data) {
  final streak = data.stats.streakDays;
  if (streak >= 7) {
    return "You're on a $streak-day streak — keep going!";
  }

  final next = data.nextUp;
  if (next != null && _isDueWithinDays(next.dueAt, DateTime.now(), 3)) {
    final typeLabel = _formatNextUpTypeLabel(next.type);
    return 'You have an upcoming $typeLabel — stay prepared!';
  }

  final highlight = data.recentGradeHighlight;
  if (highlight != null && highlight.scorePercent >= 85) {
    return 'Great work on ${highlight.subjectName} — ${highlight.scorePercent}%!';
  }

  return 'Ready to learn something new today?';
}

bool _isDueWithinDays(DateTime dueAt, DateTime now, int days) {
  final today = DateTime(now.year, now.month, now.day);
  final dueDay = DateTime(dueAt.year, dueAt.month, dueAt.day);
  final diffDays = dueDay.difference(today).inDays;
  return diffDays >= 0 && diffDays <= days;
}

String _formatNextUpTypeLabel(String type) {
  final t = type.trim();
  if (t.isEmpty) return 'item';
  return '${t[0].toUpperCase()}${t.length > 1 ? t.substring(1).toLowerCase() : ''}';
}

class _HeroGreeting extends StatelessWidget {
  final String date;
  final String greeting;
  final String name;
  final String subtitle;
  final VoidCallback onProfileTap;

  const _HeroGreeting({
    required this.date,
    required this.greeting,
    required this.name,
    required this.subtitle,
    required this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                date,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              AppSpacing.gapXs,
              Text(
                '$greeting,',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w400,
                ),
              ),
              Text(
                name,
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
              AppSpacing.gapSm,
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
        Pressable(
          onTap: onProfileTap,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: AppGradients.primaryHero,
              borderRadius: AppRadius.borderMd,
              boxShadow: AppShadows.glow(AppColors.primary),
            ),
            child: Icon(
              Icons.person_rounded,
              color: theme.colorScheme.onPrimary,
              size: 26,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Gamification Stat Row ──

class _GamificationRow extends StatelessWidget {
  final int streak;
  final int xp;
  final int level;
  final String levelTitle;
  final VoidCallback onTap;

  const _GamificationRow({
    required this.streak,
    required this.xp,
    required this.level,
    required this.levelTitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onPrimaryStyle = theme.textTheme.titleLarge?.copyWith(
      fontWeight: FontWeight.w700,
      color: theme.colorScheme.onPrimary,
    );

    return Row(
      children: [
        Expanded(
          child: _GradientStatCard(
            icon: Icons.local_fire_department_rounded,
            value: AnimatedCounter(
              value: streak.toDouble(),
              suffix: '',
              showTrend: true,
              style: onPrimaryStyle,
            ),
            label: 'Day Streak',
            gradient: AppGradients.streak,
            onTap: onTap,
          ),
        ),
        AppSpacing.hGapMd,
        Expanded(
          child: _GradientStatCard(
            icon: Icons.star_rounded,
            value: AnimatedCounter(
              value: xp.toDouble(),
              suffix: '',
              showTrend: true,
              style: onPrimaryStyle,
            ),
            label: 'Total XP',
            gradient: AppGradients.xp,
            onTap: onTap,
          ),
        ),
        AppSpacing.hGapMd,
        Expanded(
          child: _GradientStatCard(
            icon: Icons.emoji_events_rounded,
            value: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Lvl ', style: onPrimaryStyle),
                AnimatedCounter(
                  value: level.toDouble(),
                  suffix: '',
                  showTrend: true,
                  style: onPrimaryStyle,
                ),
              ],
            ),
            label: levelTitle,
            gradient: AppGradients.level,
            onTap: onTap,
          ),
        ),
      ],
    );
  }
}

class _GradientStatCard extends StatelessWidget {
  final IconData icon;
  final Widget value;
  final String label;
  final LinearGradient gradient;
  final VoidCallback? onTap;

  const _GradientStatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.gradient,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: AppRadius.borderLg,
          boxShadow: AppShadows.glow(gradient.colors.first),
        ),
        child: Column(
          children: [
            Icon(icon, color: theme.colorScheme.onPrimary, size: 22),
            AppSpacing.gapSm,
            value,
            AppSpacing.gapXxs,
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onPrimary.withAlpha(200),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Section Header ──

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _SectionHeader({required this.title, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: theme.textTheme.titleMedium),
        if (actionLabel != null)
          TextButton(
            onPressed: onAction,
            child: Text(actionLabel!),
          ),
      ],
    );
  }
}

// ── Next Up Card ──

class _NextUpCard extends StatelessWidget {
  final NextUpItemModel data;

  const _NextUpCard({required this.data});

  String _dueIn(DateTime dt) {
    final diff = dt.difference(DateTime.now());
    if (diff.isNegative) return 'Overdue';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ext = theme.ext;
    final subjectColor = AppColors.subjectColor(data.subjectName);

    return Pressable(
      onTap: () => Navigator.of(context).pushNamed(
        RouteNames.studentSubjectGrades,
        arguments: {
          'subjectId': data.subjectId,
          'subjectName': data.subjectName,
        },
      ),
      child: Container(
        padding: AppSpacing.paddingLg,
        decoration: BoxDecoration(
          color: ext.cardBackground,
          borderRadius: AppRadius.borderLg,
          border: Border.all(color: ext.cardBorder, width: 0.5),
          boxShadow: AppShadows.card(theme.shadowColor),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: subjectColor.withAlpha(25),
                borderRadius: AppRadius.borderMd,
              ),
              child: Icon(Icons.quiz_rounded, color: subjectColor, size: 22),
            ),
            AppSpacing.hGapMd,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          data.title,
                          style: theme.textTheme.titleSmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      AppSpacing.hGapSm,
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: subjectColor.withAlpha(20),
                          borderRadius: AppRadius.borderFull,
                        ),
                        child: Text(
                          _dueIn(data.dueAt),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: subjectColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  AppSpacing.gapXs,
                  Text(
                    data.subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Quick Actions (top 3) ──

class _QuickActionsRow extends StatelessWidget {
  static const _actions = [
    _ActionData(Icons.assignment_rounded, 'Assignments', AppColors.streakFire, RouteNames.studentAssignments),
    _ActionData(Icons.emoji_events_rounded, 'Gamification', AppColors.xpGold, RouteNames.studentGamification),
    _ActionData(Icons.calendar_month_rounded, 'Calendar', AppColors.physics, RouteNames.studentCalendar),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _actions
          .map((a) => Expanded(child: _QuickActionTile(data: a)))
          .toList()
          .expand<Widget>((w) => [w, AppSpacing.hGapMd])
          .toList()
        ..removeLast(),
    );
  }
}

class _ActionData {
  final IconData icon;
  final String label;
  final Color color;
  final String route;
  const _ActionData(this.icon, this.label, this.color, this.route);
}

class _QuickActionTile extends StatelessWidget {
  final _ActionData data;

  const _QuickActionTile({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ext = theme.ext;

    return Pressable(
      onTap: () => Navigator.of(context).pushNamed(data.route),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: ext.cardBackground,
          borderRadius: AppRadius.borderLg,
          border: Border.all(color: ext.cardBorder, width: 0.5),
          boxShadow: AppShadows.subtle(theme.shadowColor),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: data.color.withAlpha(20),
                borderRadius: AppRadius.borderMd,
              ),
              child: Icon(data.icon, color: data.color, size: 22),
            ),
            AppSpacing.gapSm,
            Text(
              data.label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Announcement Card ──

class _AnnouncementCard extends StatelessWidget {
  final String authorName;
  final String snippet;
  final DateTime createdAt;
  final VoidCallback onTap;

  const _AnnouncementCard({
    required this.authorName,
    required this.snippet,
    required this.createdAt,
    required this.onTap,
  });

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  Color _avatarColor(String name, ThemeData theme) {
    final colors = [
      AppColors.primary,
      AppColors.physics,
      AppColors.literature,
      AppColors.streakFire,
      AppColors.computerScience,
    ];
    return colors[name.hashCode.abs() % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ext = theme.ext;
    final color = _avatarColor(authorName, theme);

    return Pressable(
      onTap: onTap,
      child: Container(
        padding: AppSpacing.paddingMd,
        decoration: BoxDecoration(
          color: ext.cardBackground,
          borderRadius: AppRadius.borderLg,
          border: Border.all(color: ext.cardBorder, width: 0.5),
          boxShadow: AppShadows.subtle(theme.shadowColor),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: color.withAlpha(25),
              child: Text(
                authorName.isNotEmpty ? authorName[0].toUpperCase() : '?',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            AppSpacing.hGapMd,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          authorName,
                          style: theme.textTheme.titleSmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        _timeAgo(createdAt),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  AppSpacing.gapXxs,
                  Text(
                    snippet,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
