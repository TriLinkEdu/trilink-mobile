import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/routes/route_names.dart';
import '../../../../core/services/api_service.dart';
import '../../../../features/auth/services/auth_service.dart';
import '../../../shared/widgets/role_page_background.dart';
import '../../dashboard/screens/parent_dashboard_screen.dart';
import '../../notifications/screens/parent_notifications_screen.dart';
import '../../profile_settings/screens/parent_settings_screen.dart';

class ParentHomeScreen extends StatefulWidget {
  const ParentHomeScreen({super.key});

  @override
  State<ParentHomeScreen> createState() => _ParentHomeScreenState();
}

class _ParentHomeScreenState extends State<ParentHomeScreen> {
  int _currentIndex = 0;
  bool _loading = true;
  List<Map<String, dynamic>> _linkedChildren = [];
  int _unreadNotifications = 0;

  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final data = await ApiService().getParentDashboard();
      if (!mounted) return;
      final linked = data['linkedChildren'];
      setState(() {
        if (linked is List) {
          _linkedChildren = linked.cast<Map<String, dynamic>>();
        } else if (linked is int) {
          _linkedChildren = List.generate(
            linked,
            (i) => {
              'id': 'child-$i',
              'studentId': 'child-$i',
              'firstName': i == 0 ? 'Ali' : 'Leila',
              'lastName': 'Hassan',
              'grade': i == 0 ? 'Grade 9' : 'Grade 7',
            },
          );
        }
        _unreadNotifications =
            (data['unreadNotifications'] as num?)?.toInt() ?? 0;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    final firstName = user?.firstName ?? 'Parent';

    final screens = <Widget>[
      _buildHomeBody(firstName),
      const ParentNotificationsScreen(),
      const ParentSettingsScreen(),
    ];

    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildDrawer(context, user),
      body: RolePageBackground(
        flavor: RoleThemeFlavor.parent,
        child: IndexedStack(index: _currentIndex, children: screens),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
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
          onTap: (i) => setState(() => _currentIndex = i),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Theme.of(context).colorScheme.surface,
          selectedItemColor: Theme.of(context).colorScheme.primary,
          unselectedItemColor: Theme.of(context).colorScheme.onSurfaceVariant,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          elevation: 0,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Badge(
                isLabelVisible: _unreadNotifications > 0,
                label: Text(
                  '$_unreadNotifications',
                  style: const TextStyle(fontSize: 10),
                ),
                child: const Icon(Icons.notifications_outlined),
              ),
              activeIcon: const Icon(Icons.notifications),
              label: 'Alerts',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Account',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeBody(String firstName) {
    return SafeArea(
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildHeader(),
                const Spacer(flex: 1),
                _buildGreeting(firstName),
                const SizedBox(height: 36),
                _buildChildCards(context),
                const SizedBox(height: 28),
                _buildAddChild(),
                const Spacer(flex: 2),
              ],
            ),
    );
  }

  Widget _buildHeader() {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => _scaffoldKey.currentState?.openDrawer(),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.menu,
                color: theme.colorScheme.onSurfaceVariant,
                size: 22,
              ),
            ),
          ),
          Text(
            'TriLink',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          Stack(
            children: [
              GestureDetector(
                onTap: () => setState(() => _currentIndex = 2),
                child: Icon(
                  Icons.settings_outlined,
                  color: theme.colorScheme.onSurfaceVariant,
                  size: 24,
                ),
              ),
              if (_unreadNotifications > 0)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGreeting(String firstName) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          '${_getGreeting()}, $firstName',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _linkedChildren.isEmpty
              ? 'No children linked yet.\nAdd a child to get started.'
              : "Which child's progress would you like to\nview?",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildChildCards(BuildContext context) {
    if (_linkedChildren.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 20,
        runSpacing: 16,
        children: _linkedChildren.map<Widget>((child) {
          final name =
              child['firstName'] as String? ??
              child['fullName'] as String? ??
              child['name'] as String? ??
              'Child';
          final grade = child['grade'] as String? ?? '';
          final studentId =
              child['studentId'] as String? ?? child['id'] as String? ?? '';
          return _ChildCard(
            name: name,
            grade: grade,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      ParentDashboardScreen(initialChildId: studentId),
                ),
              );
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAddChild() {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () {},
      child: Container(
        width: 110,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.add,
                color: theme.colorScheme.onSurfaceVariant,
                size: 28,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Add Child',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
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
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  child: Text(
                    user?.firstName?.isNotEmpty == true
                        ? user!.firstName[0].toUpperCase()
                        : 'P',
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
                        user?.fullName ?? 'Parent',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Parent',
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
                  icon: Icons.home_outlined,
                  label: 'Home',
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => _currentIndex = 0);
                  },
                ),
                _DrawerItem(
                  icon: Icons.dashboard_outlined,
                  label: 'Dashboard',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, RouteNames.parentDashboard);
                  },
                ),
                const Divider(height: 1),
                _DrawerSection(title: 'CHILD'),
                _DrawerItem(
                  icon: Icons.person_search_outlined,
                  label: 'Student Info',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, RouteNames.parentStudentInfo);
                  },
                ),
                _DrawerItem(
                  icon: Icons.school_outlined,
                  label: 'Results & Grades',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, RouteNames.parentResults);
                  },
                ),
                _DrawerItem(
                  icon: Icons.fact_check_outlined,
                  label: 'Attendance',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, RouteNames.parentAttendance);
                  },
                ),
                const Divider(height: 1),
                _DrawerSection(title: 'COMMUNICATION'),
                _DrawerItem(
                  icon: Icons.chat_outlined,
                  label: 'Chat',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, RouteNames.parentChat);
                  },
                ),
                _DrawerItem(
                  icon: Icons.campaign_outlined,
                  label: 'Announcements',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(
                      context,
                      RouteNames.parentAnnouncements,
                    );
                  },
                ),
                _DrawerItem(
                  icon: Icons.notifications_outlined,
                  label: 'Notifications',
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => _currentIndex = 1);
                  },
                ),
                _DrawerItem(
                  icon: Icons.feedback_outlined,
                  label: 'Feedback',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, RouteNames.parentFeedback);
                  },
                ),
                const Divider(height: 1),
                _DrawerSection(title: 'REPORTS'),
                _DrawerItem(
                  icon: Icons.assessment_outlined,
                  label: 'Weekly Report',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(
                      context,
                      RouteNames.parentWeeklyReport,
                      arguments: {'childName': 'Ali'},
                    );
                  },
                ),
                _DrawerItem(
                  icon: Icons.compare_arrows,
                  label: 'Compare Reports',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(
                      context,
                      RouteNames.parentReportComparison,
                    );
                  },
                ),
                const Divider(height: 1),
                _DrawerItem(
                  icon: Icons.person_outline,
                  label: 'Profile',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, RouteNames.parentProfile);
                  },
                ),
                _DrawerItem(
                  icon: Icons.settings_outlined,
                  label: 'Settings',
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => _currentIndex = 2);
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
                            child: const Text(
                              'Logout',
                              style: TextStyle(color: Colors.red),
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
}

class _ChildCard extends StatelessWidget {
  final String name;
  final String grade;
  final VoidCallback onTap;

  const _ChildCard({
    required this.name,
    required this.grade,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: theme.colorScheme.outlineVariant),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: theme.colorScheme.surfaceContainerLow,
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              name,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              grade,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
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
