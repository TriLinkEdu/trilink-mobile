import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/routes/route_names.dart';
import '../../../../core/utils/app_exit_helper.dart';
import '../../../../features/auth/services/auth_service.dart';
import '../../../shared/widgets/role_page_background.dart';
import 'teacher_dashboard_screen.dart';
import '../../classes/screens/class_list_screen.dart';
import '../../settings/screens/teacher_settings_screen.dart';
import '../../profile/screens/teacher_profile_screen.dart';
import '../../attendance/screens/teacher_attendance_screen.dart';

class TeacherMainScreen extends StatefulWidget {
  const TeacherMainScreen({super.key});

  @override
  State<TeacherMainScreen> createState() => _TeacherMainScreenState();
}

class _TeacherMainScreenState extends State<TeacherMainScreen> {
  int _currentIndex = 0;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<String> _screenTitles = const [
    'Dashboard',
    'My Classes',
    'Attendance',
    'Profile',
  ];

  List<Widget> get _screens => [
    TeacherDashboardScreen(
      onSwitchToAttendance: () => setState(() => _currentIndex = 2),
      onSwitchToClasses: () => setState(() => _currentIndex = 1),
    ),
    ClassListScreen(),
    TeacherAttendanceScreen(),
    TeacherProfileScreen(),
  ];

  Future<bool> _onWillPop() async {
    // Close drawer if open
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.of(context).pop();
      return false;
    }
    // Go back to first tab instead of popping
    if (_currentIndex != 0) {
      setState(() => _currentIndex = 0);
      return false;
    }
    // On root tab — ask for exit confirmation
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Exit App'),
        content: const Text('Are you sure you want to exit?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
    return shouldExit ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          await AppExitHelper.exitApp();
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        drawer: _buildDrawer(context, user),
        appBar: AppBar(
          title: Text(_screenTitles[_currentIndex]),
          leading: IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            tooltip: 'Menu',
          ),
        ),
        body: RolePageBackground(
          flavor: RoleThemeFlavor.teacher,
          child: IndexedStack(index: _currentIndex, children: _screens),
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withOpacity(0.18),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            type: BottomNavigationBarType.fixed,
            backgroundColor: Theme.of(context).colorScheme.surface,
            selectedItemColor: Theme.of(context).colorScheme.primary,
            unselectedItemColor: Theme.of(context).colorScheme.onSurfaceVariant,
            selectedFontSize: 12,
            unselectedFontSize: 12,
            elevation: 0,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard_outlined),
                activeIcon: Icon(Icons.dashboard),
                label: 'Dashboard',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.class_outlined),
                activeIcon: Icon(Icons.class_),
                label: 'Classes',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.fact_check_outlined),
                activeIcon: Icon(Icons.fact_check),
                label: 'Attendance',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, dynamic user) {
    final theme = Theme.of(context);
    final drawerSurface = Color.alphaBlend(
      theme.colorScheme.primary.withAlpha(
        theme.brightness == Brightness.dark ? 18 : 10,
      ),
      theme.colorScheme.surface,
    );
    return Drawer(
      backgroundColor: drawerSurface,
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(gradient: theme.ext.heroGradient),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: theme.colorScheme.onPrimary.withOpacity(
                    0.18,
                  ),
                  child: Text(
                    user?.firstName?.isNotEmpty == true
                        ? user!.firstName[0].toUpperCase()
                        : 'T',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.fullName ?? 'Teacher',
                        style: TextStyle(
                          color: theme.colorScheme.onPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user?.subject ?? 'Teacher',
                        style: TextStyle(
                          color: theme.colorScheme.onPrimary.withOpacity(0.82),
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        user?.email ?? '',
                        style: TextStyle(
                          color: theme.colorScheme.onPrimary.withOpacity(0.64),
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _DrawerSection(title: 'MAIN'),
                _DrawerItem(
                  icon: Icons.dashboard_outlined,
                  label: 'Dashboard',
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => _currentIndex = 0);
                  },
                ),
                _DrawerItem(
                  icon: Icons.class_outlined,
                  label: 'My Classes',
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => _currentIndex = 1);
                  },
                ),
                _DrawerItem(
                  icon: Icons.calendar_today_outlined,
                  label: 'Calendar',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, RouteNames.teacherCalendar);
                  },
                ),
                _DrawerItem(
                  icon: Icons.event_note_outlined,
                  label: 'Schedule',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, RouteNames.teacherSchedule);
                  },
                ),
                const Divider(height: 1),
                _DrawerSection(title: 'TEACHING'),
                _DrawerItem(
                  icon: Icons.fact_check_outlined,
                  label: 'Attendance',
                  onTap: () {
                    Navigator.pop(context); // Close drawer
                    setState(
                      () => _currentIndex = 2,
                    ); // Switch to attendance tab
                  },
                ),
                _DrawerItem(
                  icon: Icons.bar_chart_outlined,
                  label: 'Attendance Analytics',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(
                      context,
                      RouteNames.teacherAttendanceAnalytics,
                    );
                  },
                ),
                _DrawerItem(
                  icon: Icons.grading_outlined,
                  label: 'Grade Analytics',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(
                      context,
                      RouteNames.teacherGradeAnalytics,
                    );
                  },
                ),
                _DrawerItem(
                  icon: Icons.assignment_outlined,
                  label: 'Assignments',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, RouteNames.teacherAssignments);
                  },
                ),
                _DrawerItem(
                  icon: Icons.grading_outlined,
                  label: 'Gradebook',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, RouteNames.teacherGradebook);
                  },
                ),
                _DrawerItem(
                  icon: Icons.school_outlined,
                  label: 'Homeroom',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, RouteNames.teacherHomeroom);
                  },
                ),

                const Divider(height: 1),
                _DrawerSection(title: 'COMMUNICATION'),
                _DrawerItem(
                  icon: Icons.campaign_outlined,
                  label: 'Announcements',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(
                      context,
                      RouteNames.teacherAnnouncements,
                    );
                  },
                ),
                _DrawerItem(
                  icon: Icons.chat_outlined,
                  label: 'Messages',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, RouteNames.teacherMessages);
                  },
                ),
                _DrawerItem(
                  icon: Icons.notifications_outlined,
                  label: 'Notifications',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(
                      context,
                      RouteNames.teacherNotifications,
                    );
                  },
                ),
                _DrawerItem(
                  icon: Icons.feedback_outlined,
                  label: 'Feedback',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, RouteNames.teacherFeedback);
                  },
                ),
                const Divider(height: 1),
                _DrawerSection(title: 'TOOLS'),
                _DrawerItem(
                  icon: Icons.smart_toy_outlined,
                  label: 'AI Assistant',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, RouteNames.teacherAiAssistant);
                  },
                ),
                const Divider(height: 1),
                _DrawerItem(
                  icon: Icons.settings_outlined,
                  label: 'Settings',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TeacherSettingsScreen(),
                      ),
                    );
                  },
                ),
                _DrawerItem(
                  icon: Icons.logout,
                  label: 'Logout',
                  color: theme.colorScheme.error,
                  onTap: () async {
                    Navigator.pop(context);
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Logout'),
                        content: const Text('Are you sure you want to logout?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: Text(
                              'Logout',
                              style: TextStyle(color: theme.colorScheme.error),
                            ),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true && mounted) {
                      await AuthService().logout();
                      if (!mounted) {
                        return;
                      }
                      Navigator.pushReplacementNamed(
                        this.context,
                        RouteNames.login,
                      );
                    }
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void openDrawer() => _scaffoldKey.currentState?.openDrawer();
}

class _DrawerSection extends StatelessWidget {
  final String title;
  const _DrawerSection({required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: theme.colorScheme.onSurfaceVariant,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      dense: true,
      leading: Icon(
        icon,
        size: 22,
        color: color ?? theme.colorScheme.onSurfaceVariant,
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: color ?? theme.colorScheme.onSurface,
        ),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      horizontalTitleGap: 8,
    );
  }
}
