import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/routes/route_names.dart';
import '../../../../features/auth/services/auth_service.dart';
import 'teacher_dashboard_screen.dart';
import '../../classes/screens/class_list_screen.dart';
import '../../student_analytics/screens/student_list_screen.dart';
import '../../calendar/screens/teacher_calendar_screen.dart';
import '../../settings/screens/teacher_settings_screen.dart';

class TeacherMainScreen extends StatefulWidget {
  const TeacherMainScreen({super.key});

  @override
  State<TeacherMainScreen> createState() => _TeacherMainScreenState();
}

class _TeacherMainScreenState extends State<TeacherMainScreen> {
  int _currentIndex = 0;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<Widget> _screens = const [
    TeacherDashboardScreen(),
    ClassListScreen(),
    StudentListScreen(),
    TeacherCalendarScreen(),
    TeacherSettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildDrawer(context, user, isDark),
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.grey.shade900 : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: isDark ? Colors.grey.shade900 : Colors.white,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: Colors.grey.shade400,
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
              icon: Icon(Icons.people_outline),
              activeIcon: Icon(Icons.people),
              label: 'Students',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today_outlined),
              activeIcon: Icon(Icons.calendar_today),
              label: 'Calendar',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, dynamic user, bool isDark) {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, Color(0xFF1A237E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  child: Text(
                    user?.firstName?.isNotEmpty == true
                        ? user!.firstName[0].toUpperCase()
                        : 'T',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
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
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user?.subject ?? 'Teacher',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        user?.email ?? '',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
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
                    setState(() => _currentIndex = 3);
                  },
                ),
                const Divider(height: 1),
                _DrawerSection(title: 'TEACHING'),
                _DrawerItem(
                  icon: Icons.fact_check_outlined,
                  label: 'Attendance',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, RouteNames.teacherAttendance);
                  },
                ),
                _DrawerItem(
                  icon: Icons.bar_chart_outlined,
                  label: 'Attendance Analytics',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, RouteNames.teacherAttendanceAnalytics);
                  },
                ),
                _DrawerItem(
                  icon: Icons.quiz_outlined,
                  label: 'Exams',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, RouteNames.teacherExams);
                  },
                ),
                _DrawerItem(
                  icon: Icons.add_circle_outline,
                  label: 'Create Exam',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, RouteNames.teacherCreateExam);
                  },
                ),
                _DrawerItem(
                  icon: Icons.library_books_outlined,
                  label: 'Question Bank',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, RouteNames.teacherExamBank);
                  },
                ),
                _DrawerItem(
                  icon: Icons.grading_outlined,
                  label: 'Evaluate Submissions',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, RouteNames.teacherEvaluateSubmissions);
                  },
                ),
                const Divider(height: 1),
                _DrawerSection(title: 'COMMUNICATION'),
                _DrawerItem(
                  icon: Icons.campaign_outlined,
                  label: 'Announcements',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, RouteNames.teacherAnnouncements);
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
                    Navigator.pushNamed(context, RouteNames.teacherNotifications);
                  },
                ),
                const Divider(height: 1),
                _DrawerSection(title: 'TOOLS'),
                _DrawerItem(
                  icon: Icons.people_outline,
                  label: 'Student Analytics',
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => _currentIndex = 2);
                  },
                ),
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
                    setState(() => _currentIndex = 4);
                  },
                ),
                _DrawerItem(
                  icon: Icons.logout,
                  label: 'Logout',
                  color: Colors.red.shade600,
                  onTap: () async {
                    Navigator.pop(context);
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Logout'),
                        content: const Text('Are you sure you want to logout?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Logout', style: TextStyle(color: Colors.red))),
                        ],
                      ),
                    );
                    if (confirm == true && mounted) {
                      await AuthService().logout();
                      if (mounted) Navigator.pushReplacementNamed(context, RouteNames.login);
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.grey.shade500,
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
    return ListTile(
      dense: true,
      leading: Icon(icon, size: 22, color: color ?? Colors.grey.shade700),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: color ?? Colors.grey.shade800,
        ),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      horizontalTitleGap: 8,
    );
  }
}
