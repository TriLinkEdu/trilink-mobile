import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/routes/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../auth/cubit/auth_cubit.dart';
import 'student_shell_scope.dart';

class StudentDrawer extends StatelessWidget {
  final GlobalKey<NavigatorState> homeNavigatorKey;

  const StudentDrawer({super.key, required this.homeNavigatorKey});

  void _navigate(BuildContext context, String route,
      {Map<String, dynamic>? args, int? tabIndex}) {
    Navigator.of(context).pop(); // close drawer
    final scope = StudentShellScope.of(context);
    if (tabIndex != null) {
      scope.switchTab(tabIndex);
    } else {
      scope.switchTab(0);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        homeNavigatorKey.currentState?.pushNamed(route, arguments: args);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final user = context.read<AuthCubit>().currentUser;
    final displayName = user?.name ?? 'Student';
    final displayEmail = user?.email ?? '';
    final gradeSection = [
      if (user?.grade != null) user!.grade!,
      if (user?.section != null) user!.section!,
    ].join(' • ');

    return Drawer(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _DrawerHeader(
            name: displayName,
            email: displayEmail,
            subtitle: gradeSection,
            isDark: isDark,
            onProfileTap: () {
              Navigator.of(context).pop();
              StudentShellScope.of(context).switchTab(3);
            },
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: [
                _SectionLabel('ACADEMICS'),
                _DrawerItem(
                  icon: Icons.leaderboard_rounded,
                  label: 'Grades',
                  color: AppColors.primary,
                  onTap: () {
                    Navigator.of(context).pop();
                    StudentShellScope.of(context).switchTab(1);
                  },
                ),
                _DrawerItem(
                  icon: Icons.assignment_rounded,
                  label: 'Assignments',
                  color: AppColors.streakFire,
                  onTap: () => _navigate(context, RouteNames.studentAssignments),
                ),
                _DrawerItem(
                  icon: Icons.fact_check_rounded,
                  label: 'Attendance',
                  color: AppColors.achievementEmerald,
                  onTap: () => _navigate(context, RouteNames.studentAttendance),
                ),
                _DrawerItem(
                  icon: Icons.calendar_month_rounded,
                  label: 'Calendar',
                  color: AppColors.physics,
                  onTap: () => _navigate(context, RouteNames.studentCalendar),
                ),
                _DrawerItem(
                  icon: Icons.folder_open_rounded,
                  label: 'Courses & Resources',
                  color: AppColors.computerScience,
                  onTap: () =>
                      _navigate(context, RouteNames.studentCourseResources),
                ),
                _DrawerItem(
                  icon: Icons.quiz_rounded,
                  label: 'Exams',
                  color: AppColors.mathematics,
                  onTap: () =>
                      _navigate(context, RouteNames.studentExamAttempt),
                ),

                AppSpacing.gapSm,
                _SectionLabel('ENGAGEMENT'),
                _DrawerItem(
                  icon: Icons.auto_awesome,
                  label: 'AI Tutor',
                  color: AppColors.levelPurple,
                  onTap: () =>
                      _navigate(context, RouteNames.studentAiAssistant),
                ),
                _DrawerItem(
                  icon: Icons.emoji_events_rounded,
                  label: 'Gamification',
                  color: AppColors.xpGold,
                  onTap: () =>
                      _navigate(context, RouteNames.studentGamification),
                ),
                _DrawerItem(
                  icon: Icons.rate_review_rounded,
                  label: 'Feedback',
                  color: AppColors.literature,
                  onTap: () => _navigate(context, RouteNames.studentFeedback),
                ),
                _DrawerItem(
                  icon: Icons.chat_bubble_rounded,
                  label: 'Chat',
                  color: AppColors.secondary,
                  onTap: () {
                    Navigator.of(context).pop();
                    StudentShellScope.of(context).switchTab(2);
                  },
                ),

                AppSpacing.gapSm,
                _SectionLabel('INFO'),
                _DrawerItem(
                  icon: Icons.campaign_rounded,
                  label: 'Announcements',
                  color: AppColors.biology,
                  onTap: () =>
                      _navigate(context, RouteNames.studentAnnouncements),
                ),
                _DrawerItem(
                  icon: Icons.notifications_rounded,
                  label: 'Notifications',
                  color: AppColors.info,
                  onTap: () =>
                      _navigate(context, RouteNames.studentNotifications),
                ),

                AppSpacing.gapSm,
                _SectionLabel('SYSTEM'),
                _DrawerItem(
                  icon: Icons.settings_rounded,
                  label: 'Settings',
                  color: AppColors.darkSurfaceBright,
                  onTap: () => _navigate(context, RouteNames.studentSettings),
                ),
                _DrawerItem(
                  icon: Icons.sync_rounded,
                  label: 'Sync Status',
                  color: AppColors.primary,
                  onTap: () => _navigate(context, RouteNames.studentSyncStatus),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            thickness: 0.5,
            color: theme.colorScheme.outlineVariant,
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: _DrawerItem(
                icon: Icons.logout_rounded,
                label: 'Log Out',
                color: theme.colorScheme.error,
                isDestructive: true,
                onTap: () async {
                  Navigator.of(context).pop();
                  await context.read<AuthCubit>().logout();
                  if (!context.mounted) return;
                  Navigator.of(context, rootNavigator: true)
                      .pushNamedAndRemoveUntil(RouteNames.login, (_) => false);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Drawer Header ──

class _DrawerHeader extends StatelessWidget {
  final String name;
  final String email;
  final String subtitle;
  final bool isDark;
  final VoidCallback onProfileTap;

  const _DrawerHeader({
    required this.name,
    required this.email,
    required this.subtitle,
    required this.isDark,
    required this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 24,
        left: 20,
        right: 20,
        bottom: 20,
      ),
      decoration: BoxDecoration(
        gradient: isDark
            ? const LinearGradient(
                colors: [Color(0xFF1E3A5F), Color(0xFF0F172A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : AppGradients.primaryHero,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: onProfileTap,
                child: CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white.withAlpha(40),
                  child: const Icon(
                    Icons.person_rounded,
                    size: 30,
                    color: Colors.white,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(25),
                  borderRadius: AppRadius.borderFull,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.school_rounded, size: 14, color: Colors.white),
                    AppSpacing.hGapXs,
                    Text(
                      'TriLink',
                      style: TextStyle(
                        color: Colors.white.withAlpha(220),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          AppSpacing.gapLg,
          Text(
            name,
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (email.isNotEmpty) ...[
            AppSpacing.gapXxs,
            Text(
              email,
              style: TextStyle(
                color: Colors.white.withAlpha(180),
                fontSize: 12,
              ),
            ),
          ],
          if (subtitle.isNotEmpty) ...[
            AppSpacing.gapXs,
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(20),
                borderRadius: AppRadius.borderFull,
              ),
              child: Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withAlpha(200),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Section Label ──

class _SectionLabel extends StatelessWidget {
  final String title;
  const _SectionLabel(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

// ── Drawer Item ──

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool isDestructive;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      borderRadius: AppRadius.borderMd,
      child: InkWell(
        borderRadius: AppRadius.borderMd,
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: (isDestructive ? color : color).withAlpha(18),
                  borderRadius: AppRadius.borderSm,
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              AppSpacing.hGapMd,
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDestructive
                        ? color
                        : theme.colorScheme.onSurface,
                  ),
                ),
              ),
              if (!isDestructive)
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: theme.colorScheme.onSurfaceVariant.withAlpha(120),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
