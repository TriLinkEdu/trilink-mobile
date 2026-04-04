import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/routes/route_names.dart';
import '../../../../core/routes/student_shell_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/celebration_overlay.dart';
import '../../../student/chat/screens/student_chat_screen.dart';
import '../../../student/grades/screens/student_grades_screen.dart';
import '../../../student/profile/screens/student_profile_screen.dart';
import '../widgets/student_drawer.dart';
import '../widgets/student_shell_scope.dart';
import 'student_dashboard_screen.dart';

class StudentMainScreen extends StatefulWidget {
  const StudentMainScreen({super.key});

  @override
  State<StudentMainScreen> createState() => _StudentMainScreenState();
}

class _StudentMainScreenState extends State<StudentMainScreen> {
  int _currentIndex = 0;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _navigatorKeys = List.generate(4, (_) => GlobalKey<NavigatorState>());

  static const _tabTitles = ['Home', 'Grades', 'Chat', 'Profile'];

  static const _tabRoots = <Widget>[
    StudentDashboardScreen(),
    StudentGradesScreen(),
    StudentChatScreen(),
    StudentProfileScreen(),
  ];

  late final List<_ShellRouteObserver> _routeObservers;
  final _titleNotifier = ValueNotifier<String>('Home');

  @override
  void initState() {
    super.initState();
    _routeObservers = List.generate(
      4,
      (i) => _ShellRouteObserver(
        rootTitle: _tabTitles[i],
        onTitleChanged: (title) {
          if (i == _currentIndex) _titleNotifier.value = title;
        },
      ),
    );
  }

  @override
  void dispose() {
    _titleNotifier.dispose();
    super.dispose();
  }

  void _onTap(int index) {
    if (index == _currentIndex) {
      _navigatorKeys[index].currentState?.popUntil((route) => route.isFirst);
    } else {
      HapticFeedback.selectionClick();
      setState(() => _currentIndex = index);
      _titleNotifier.value = _routeObservers[index].currentTitle;
    }
  }

  Future<bool> _onWillPop() async {
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.of(context).pop();
      return false;
    }
    final navState = _navigatorKeys[_currentIndex].currentState;
    if (navState != null && navState.canPop()) {
      navState.pop();
      return false;
    }
    if (_currentIndex != 0) {
      setState(() => _currentIndex = 0);
      _titleNotifier.value = _routeObservers[0].currentTitle;
      return false;
    }
    return true;
  }

  void _openInCurrentTab(String route, {Object? arguments}) {
    final nav = _navigatorKeys[_currentIndex].currentState;
    nav?.pushNamed(route, arguments: arguments);
  }

  @override
  Widget build(BuildContext context) {
    return StudentShellScope(
      openDrawer: () => _scaffoldKey.currentState?.openDrawer(),
      switchTab: (i) {
        setState(() => _currentIndex = i);
        _titleNotifier.value = _routeObservers[i].currentTitle;
      },
      pushInCurrentTab: _openInCurrentTab,
      currentTabIndex: _currentIndex,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) async {
          if (didPop) return;
          final shouldPop = await _onWillPop();
          if (shouldPop && context.mounted) {
            Navigator.of(context).maybePop();
          }
        },
        child: CelebrationOverlay(
          child: Scaffold(
            key: _scaffoldKey,
            drawer: StudentDrawer(homeNavigatorKey: _navigatorKeys[0]),
            body: Column(
              children: [
                _ShellTopBar(
                  titleNotifier: _titleNotifier,
                  onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
                  onNotificationsTap: () =>
                      _openInCurrentTab(RouteNames.studentNotifications),
                ),
                Expanded(
                  child: IndexedStack(
                    index: _currentIndex,
                    children: List.generate(
                      4,
                      (i) => _TabNavigator(
                        navigatorKey: _navigatorKeys[i],
                        root: _tabRoots[i],
                        observer: _routeObservers[i],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            bottomNavigationBar: _GlassNavBar(
              currentIndex: _currentIndex,
              onTap: _onTap,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Route-to-Title Mapping ──

const _routeTitleMap = <String, String>{
  RouteNames.studentGrades: 'Grades',
  RouteNames.studentSubjectGrades: 'Subject Grades',
  RouteNames.studentAnnouncements: 'Announcements',
  RouteNames.studentAnnouncementDetail: 'Announcement',
  RouteNames.studentAttendance: 'Attendance',
  RouteNames.studentNotifications: 'Notifications',
  RouteNames.studentChat: 'Chat',
  RouteNames.studentChatConversation: 'Conversation',
  RouteNames.studentProfile: 'Profile',
  RouteNames.studentProfileEdit: 'Edit Profile',
  RouteNames.studentCalendar: 'Calendar',
  RouteNames.studentCalendarEventDetail: 'Event Details',
  RouteNames.studentSettings: 'Settings',
  RouteNames.studentAiAssistant: 'AI Tutor',
  RouteNames.studentLearningPath: 'Learning Path',
  RouteNames.studentResourceRecommendation: 'Resources',
  RouteNames.studentEvaluateMe: 'Evaluate Me',
  RouteNames.studentGamification: 'Gamification',
  RouteNames.studentLeaderboard: 'Leaderboard',
  RouteNames.studentAchievements: 'Achievements',
  RouteNames.studentQuiz: 'Quiz',
  RouteNames.studentFeedback: 'Feedback',
  RouteNames.studentSubmitFeedback: 'Submit Feedback',
  RouteNames.studentAssignments: 'Assignments',
  RouteNames.studentAssignmentDetail: 'Assignment',
  RouteNames.studentCourses: 'My Courses',
  RouteNames.studentCourseDetail: 'Course Details',
  RouteNames.studentCourseResources: 'Resources',
  RouteNames.studentCourseResourceDetail: 'Resource',
  RouteNames.studentExams: 'Exams',
  RouteNames.studentExamAttempt: 'Exam',
  RouteNames.studentSyncStatus: 'Sync Status',
  RouteNames.studentWeeklySnapshot: 'Weekly Snapshot',
  RouteNames.studentActionPlan: 'Action Plan',
  RouteNames.studentPerformanceTrends: 'Performance Trends',
};

// ── Navigator Observer for Title Tracking ──

class _ShellRouteObserver extends NavigatorObserver {
  final String rootTitle;
  final ValueChanged<String> onTitleChanged;
  String currentTitle;

  _ShellRouteObserver({required this.rootTitle, required this.onTitleChanged})
    : currentTitle = rootTitle;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _update(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (previousRoute != null) _update(previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (newRoute != null) _update(newRoute);
  }

  void _update(Route<dynamic> route) {
    final name = route.settings.name;
    currentTitle = _routeTitleMap[name] ?? rootTitle;
    onTitleChanged(currentTitle);
  }
}

// ── Shell Top Bar ──

class _ShellTopBar extends StatelessWidget {
  final ValueNotifier<String> titleNotifier;
  final VoidCallback onMenuTap;
  final VoidCallback onNotificationsTap;

  const _ShellTopBar({
    required this.titleNotifier,
    required this.onMenuTap,
    required this.onNotificationsTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final top = MediaQuery.of(context).padding.top;

    return Container(
      padding: EdgeInsets.only(top: top),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? Colors.white.withAlpha(12)
                : Colors.black.withAlpha(8),
            width: 0.5,
          ),
        ),
      ),
      child: SizedBox(
        height: 52,
        child: Row(
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                HapticFeedback.lightImpact();
                onMenuTap();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Icon(
                  Icons.menu_rounded,
                  size: 22,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Expanded(
              child: ValueListenableBuilder<String>(
                valueListenable: titleNotifier,
                builder: (_, title, _) {
                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Text(
                      title,
                      key: ValueKey(title),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                },
              ),
            ),
            IconButton(
              icon: const Icon(Icons.notifications_outlined, size: 22),
              onPressed: onNotificationsTap,
              tooltip: 'Notifications',
            ),
          ],
        ),
      ),
    );
  }
}

// ── Per-Tab Navigator ──

class _TabNavigator extends StatelessWidget {
  final GlobalKey<NavigatorState> navigatorKey;
  final Widget root;
  final NavigatorObserver observer;

  const _TabNavigator({
    required this.navigatorKey,
    required this.root,
    required this.observer,
  });

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      observers: [observer],
      onGenerateRoute: (settings) {
        if (settings.name == '/' || settings.name == null) {
          return MaterialPageRoute(builder: (_) => root, settings: settings);
        }
        return StudentShellRoutes.onGenerateRoute(settings);
      },
    );
  }
}

// ── Bottom Nav ──

class _GlassNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _GlassNavBar({required this.currentIndex, required this.onTap});

  static const _items = [
    _NavItemData(
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'Home',
    ),
    _NavItemData(
      icon: Icons.leaderboard_outlined,
      activeIcon: Icons.leaderboard_rounded,
      label: 'Grades',
    ),
    _NavItemData(
      icon: Icons.chat_bubble_outline_rounded,
      activeIcon: Icons.chat_bubble_rounded,
      label: 'Chat',
    ),
    _NavItemData(
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      label: 'Profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bottom = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.sm,
        right: AppSpacing.sm,
        top: AppSpacing.sm,
        bottom: bottom + AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withAlpha(12)
                : Colors.black.withAlpha(8),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(_items.length, (i) {
          return _AnimatedNavItem(
            data: _items[i],
            isSelected: currentIndex == i,
            onTap: () => onTap(i),
          );
        }),
      ),
    );
  }
}

class _NavItemData {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItemData({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

class _AnimatedNavItem extends StatelessWidget {
  final _NavItemData data;
  final bool isSelected;
  final VoidCallback onTap;

  const _AnimatedNavItem({
    required this.data,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 16 : 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withAlpha(20)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isSelected ? data.activeIcon : data.icon,
                key: ValueKey(isSelected),
                size: 22,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              child: isSelected
                  ? Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text(
                        data.label,
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
