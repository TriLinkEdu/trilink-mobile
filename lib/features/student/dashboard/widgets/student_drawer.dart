import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trilink_mobile/core/widgets/pressable.dart';
import '../../../../core/constants/asset_constants.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/routes/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../auth/cubit/auth_cubit.dart';
import 'student_shell_scope.dart';

class StudentDrawer extends StatelessWidget {
  final GlobalKey<NavigatorState> homeNavigatorKey;

  const StudentDrawer({super.key, required this.homeNavigatorKey});

  void _navigate(
    BuildContext context,
    String route, {
    Map<String, dynamic>? args,
    int? tabIndex,
  }) {
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
    final user = context.select((AuthCubit cubit) => cubit.currentUser);
    final displayName = user?.name ?? 'Student';
    final displayEmail = user?.email ?? '';
    final gradeSection = [
      if (user?.grade != null) user!.grade!,
      if (user?.section != null) user!.section!,
    ].join(' • ');

    return Drawer(
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _DrawerHeader(
            name: displayName,
            email: displayEmail,
            subtitle: gradeSection,
            avatarPath: user?.profileImagePath,
            onProfileTap: () {
              Navigator.of(context).pop();
              StudentShellScope.of(context).switchTab(3);
            },
            onSettingsTap: () => _navigate(context, RouteNames.studentSettings),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: [
                _SectionLabel('ACADEMICS'),
                _DrawerItem(
                  icon: Icons.leaderboard_rounded,
                  label: 'Grades',
                  color: theme.colorScheme.primary,
                  onTap: () {
                    Navigator.of(context).pop();
                    StudentShellScope.of(context).switchTab(1);
                  },
                ),
                _DrawerItem(
                  icon: Icons.assignment_rounded,
                  label: 'Assignments',
                  color: theme.colorScheme.secondary,
                  onTap: () =>
                      _navigate(context, RouteNames.studentAssignments),
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
                  color: theme.colorScheme.primary,
                  onTap: () => _navigate(context, RouteNames.studentCalendar),
                ),
                _DrawerItem(
                  icon: Icons.folder_open_rounded,
                  label: 'Courses',
                  color: theme.colorScheme.secondary,
                  onTap: () => _navigate(context, RouteNames.studentCourses),
                ),
                _DrawerItem(
                  icon: Icons.menu_book_rounded,
                  label: 'Resources',
                  color: theme.colorScheme.secondary,
                  onTap: () =>
                      _navigate(context, RouteNames.studentCourseResources),
                ),
                _DrawerItem(
                  icon: Icons.quiz_rounded,
                  label: 'Exams',
                  color: theme.colorScheme.primary,
                  onTap: () => _navigate(context, RouteNames.studentExams),
                ),
                _DrawerItem(
                  icon: Icons.flag_rounded,
                  label: 'Goals & Progress',
                  color: AppColors.achievementEmerald,
                  onTap: () => _navigate(context, RouteNames.studentGoals),
                ),

                AppSpacing.gapSm,
                _SectionLabel('ENGAGEMENT'),
                _DrawerItem(
                  icon: Icons.auto_awesome,
                  label: 'AI Tutor',
                  color: theme.colorScheme.primary,
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
                  color: theme.colorScheme.secondary,
                  onTap: () => _navigate(context, RouteNames.studentFeedback),
                ),
                _DrawerItem(
                  icon: Icons.chat_bubble_rounded,
                  label: 'Chat',
                  color: theme.colorScheme.secondary,
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
                  color: theme.colorScheme.secondary,
                  onTap: () =>
                      _navigate(context, RouteNames.studentAnnouncements),
                ),
                _DrawerItem(
                  icon: Icons.notifications_rounded,
                  label: 'Notifications',
                  color: theme.colorScheme.primary,
                  onTap: () =>
                      _navigate(context, RouteNames.studentNotifications),
                ),

                AppSpacing.gapSm,
                _SectionLabel('SYSTEM'),
                _DrawerItem(
                  icon: Icons.settings_rounded,
                  label: 'Settings',
                  color: theme.colorScheme.onSurfaceVariant,
                  onTap: () => _navigate(context, RouteNames.studentSettings),
                ),
                _DrawerItem(
                  icon: Icons.sync_rounded,
                  label: 'Sync Status',
                  color: theme.colorScheme.primary,
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
                  Navigator.of(
                    context,
                    rootNavigator: true,
                  ).pushNamedAndRemoveUntil(RouteNames.login, (_) => false);
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
  final String? avatarPath;
  final VoidCallback onProfileTap;
  final VoidCallback onSettingsTap;

  const _DrawerHeader({
    required this.name,
    required this.email,
    required this.subtitle,
    this.avatarPath,
    required this.onProfileTap,
    required this.onSettingsTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final headerForeground = theme.colorScheme.onPrimary;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 24,
        left: 20,
        right: 20,
        bottom: 20,
      ),
      decoration: BoxDecoration(gradient: theme.ext.heroGradient),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Pressable(
                onTap: onProfileTap,
                child: CircleAvatar(
                  radius: 28,
                  backgroundColor: headerForeground.withAlpha(40),
                  backgroundImage:
                      (avatarPath != null && avatarPath!.isNotEmpty)
                      ? NetworkImage('${ApiConstants.fileBaseUrl}$avatarPath')
                      : null,
                  child: (avatarPath == null || avatarPath!.isEmpty)
                      ? Icon(
                          Icons.person_rounded,
                          size: 30,
                          color: headerForeground,
                        )
                      : null,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: headerForeground.withAlpha(25),
                  borderRadius: AppRadius.borderFull,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      AssetConstants.logoPath,
                      width: 14,
                      height: 14,
                      fit: BoxFit.contain,
                    ),
                    AppSpacing.hGapXs,
                    Text(
                      'TriLink',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: headerForeground.withAlpha(220),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              AppSpacing.hGapXs,
              Pressable(
                onTap: onSettingsTap,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: headerForeground.withAlpha(25),
                    borderRadius: AppRadius.borderFull,
                  ),
                  child: Icon(
                    Icons.settings_rounded,
                    size: 16,
                    color: headerForeground,
                  ),
                ),
              ),
            ],
          ),
          AppSpacing.gapLg,
          Text(
            name,
            style: theme.textTheme.titleMedium?.copyWith(
              color: headerForeground,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (email.isNotEmpty) ...[
            AppSpacing.gapXxs,
            Text(
              email,
              style: theme.textTheme.labelSmall?.copyWith(
                color: headerForeground.withAlpha(180),
              ),
            ),
          ],
          if (subtitle.isNotEmpty) ...[
            AppSpacing.gapXs,
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: headerForeground.withAlpha(20),
                borderRadius: AppRadius.borderFull,
              ),
              child: Text(
                subtitle,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: headerForeground.withAlpha(200),
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
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
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
    final tileBg = Color.alphaBlend(
      color.withAlpha(22),
      theme.colorScheme.surface,
    );
    final iconColor =
        ThemeData.estimateBrightnessForColor(tileBg) == Brightness.dark
        ? Colors.white
        : color;

    return Pressable(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: tileBg,
                borderRadius: AppRadius.borderSm,
              ),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            AppSpacing.hGapMd,
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: isDestructive ? color : theme.colorScheme.onSurface,
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
    );
  }
}
