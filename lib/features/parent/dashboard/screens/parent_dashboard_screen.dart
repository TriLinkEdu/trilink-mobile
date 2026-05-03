import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/routes/route_names.dart';
import '../../../../core/widgets/offline_banner.dart';
import '../../../../core/services/api_service.dart';
import '../../../../features/auth/services/auth_service.dart';
import '../../student_info/screens/parent_student_info_screen.dart';
import '../../student_info/screens/parent_results_screen.dart';
import '../../student_info/screens/parent_subject_list_screen.dart';
import '../../student_info/screens/parent_teachers_screen.dart';
import '../../attendance/screens/parent_attendance_screen.dart';
import '../../chat/screens/parent_chat_screen.dart';
import '../../chat/screens/parent_child_chat_history_screen.dart';
import '../../announcements/screens/parent_announcements_screen.dart';
import '../../feedback/screens/parent_feedback_screen.dart';
import '../../reports/screens/weekly_report_screen.dart';
import '../../notifications/screens/parent_notifications_screen.dart';
import '../../profile_settings/screens/parent_settings_screen.dart';
import '../../profile_settings/screens/parent_profile_screen.dart';
import '../../../shared/widgets/role_page_background.dart';
import '../../home/screens/parent_home_screen.dart';

class ParentDashboardScreen extends StatefulWidget {
  final String? initialChildId;

  const ParentDashboardScreen({super.key, this.initialChildId});

  @override
  State<ParentDashboardScreen> createState() => _ParentDashboardScreenState();
}

class _ParentDashboardScreenState extends State<ParentDashboardScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _loading = true;
  String? _error;
  int _selectedChildIndex = 0;
  List<Map<String, dynamic>> _children = [];
  Map<String, dynamic> _childDashboard = {};
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadUnreadCount();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });

      // Load children list using new API
      final children = await ApiService().getMyChildren();

      if (children.isEmpty) {
        if (!mounted) return;
        setState(() {
          _children = [];
          _loading = false;
        });
        return;
      }

      // Convert to proper format
      _children = children.map<Map<String, dynamic>>((child) {
        final student = child['student'] as Map<String, dynamic>?;
        return {
          'id': child['id'],
          'studentId': student?['id'] ?? child['studentId'],
          'firstName': student?['firstName'] ?? child['firstName'],
          'lastName': student?['lastName'] ?? child['lastName'],
          'fullName':
              '${student?['firstName'] ?? ''} ${student?['lastName'] ?? ''}'
                  .trim(),
          'grade': student?['grade'] ?? child['grade'],
          'section': student?['section'] ?? child['section'],
          'avatar': '',
        };
      }).toList();

      if (widget.initialChildId != null) {
        final idx = _children.indexWhere(
          (c) => c['studentId'] == widget.initialChildId,
        );
        if (idx >= 0) _selectedChildIndex = idx;
      }

      await _loadChildSummary();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _loadUnreadCount() async {
    try {
      final notifications = await ApiService().getNotifications();
      if (!mounted) return;
      final unread = notifications.where((n) => n['readAt'] == null).length;
      setState(() => _unreadCount = unread);
    } catch (e) {
      // Silently fail
    }
  }

  Future<void> _loadChildSummary() async {
    try {
      final child = _children[_selectedChildIndex];
      final studentId =
          child['studentId'] as String? ?? child['id'] as String? ?? '';
      final dashboard = await ApiService().getChildDashboard(studentId);
      if (!mounted) return;
      setState(() {
        _childDashboard = dashboard;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  String get _childName {
    if (_children.isEmpty) return '';
    final c = _children[_selectedChildIndex];
    return c['fullName'] as String? ??
        '${c['firstName'] ?? ''} ${c['lastName'] ?? ''}'.trim();
  }

  String get _childAvatar {
    if (_children.isEmpty) return '';
    return _children[_selectedChildIndex]['avatar'] as String? ?? '';
  }

  Future<bool> _onWillPop() async {
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.of(context).pop();
      return false;
    }
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
    final theme = Theme.of(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).maybePop();
        }
      },
      child: Scaffold(
      key: _scaffoldKey,
      drawer: _buildDrawer(context),
      body: RolePageBackground(
        flavor: RoleThemeFlavor.parent,
        child: OfflineBanner(
          child: SafeArea(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _error!,
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _loadData,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(context),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 20),
                              _buildOverviewSection(),
                              const SizedBox(height: 24),
                              _buildGradesBySubject(),
                              const SizedBox(height: 24),
                              _buildUpcomingTasks(),
                              const SizedBox(height: 24),
                              _buildFeatureGrid(context),
                              const SizedBox(height: 24),
                              _buildContactTeacher(),
                              const SizedBox(height: 24),
                              _buildRecentActivity(),
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 20, 0),
      child: Row(
        children: [
          Builder(
            builder: (context) => IconButton(
              icon: Icon(
                Icons.menu,
                color: theme.colorScheme.onSurface,
                size: 24,
              ),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          const SizedBox(width: 4),
          _childAvatar.isNotEmpty
              ? CircleAvatar(
                  radius: 18,
                  backgroundImage: NetworkImage(_childAvatar),
                )
              : CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: Text(
                    _childName.isNotEmpty ? _childName[0] : '?',
                    style: const TextStyle(color: AppColors.primary),
                  ),
                ),
          const SizedBox(width: 8),
          Text(
            _childName,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const Spacer(),
          Stack(
            clipBehavior: Clip.none,
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ParentNotificationsScreen(),
                    ),
                  ).then((_) {
                    // Refresh unread count when returning
                    _loadUnreadCount();
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.notifications_outlined,
                    color: theme.colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                ),
              ),
              if (_unreadCount > 0)
                Positioned(
                  right: 2,
                  top: 2,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      _unreadCount > 99 ? '99+' : '$_unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final theme = Theme.of(context);
    final user = AuthService().currentUser;
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
                    (user?.firstName ?? '').isNotEmpty
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
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ParentHomeScreen(),
                      ),
                    );
                  },
                ),
                _DrawerItem(
                  icon: Icons.dashboard_outlined,
                  label: 'Dashboard',
                  onTap: () => Navigator.pop(context),
                ),
                const Divider(height: 1),
                _DrawerSection(title: 'CHILD'),
                _DrawerItem(
                  icon: Icons.person_search_outlined,
                  label: 'Student Info',
                  onTap: () {
                    Navigator.pop(context);
                    final childId = _children.isNotEmpty
                        ? (_children[_selectedChildIndex]['studentId']
                                  as String? ??
                              _children[_selectedChildIndex]['id'] as String? ??
                              '')
                        : '';
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ParentStudentInfoScreen(
                          childName: _childName,
                          studentUserId: childId,
                        ),
                      ),
                    );
                  },
                ),
                _DrawerItem(
                  icon: Icons.school_outlined,
                  label: 'Results & Grades',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ParentResultsScreen(),
                      ),
                    );
                  },
                ),
                _DrawerItem(
                  icon: Icons.fact_check_outlined,
                  label: 'Attendance',
                  onTap: () {
                    Navigator.pop(context);
                    final childId = _children.isNotEmpty
                        ? (_children[_selectedChildIndex]['studentId']
                                  as String? ??
                              _children[_selectedChildIndex]['id'] as String? ??
                              '')
                        : '';
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ParentAttendanceScreen(
                          studentId: childId,
                          childName: _childName,
                        ),
                      ),
                    );
                  },
                ),
                _DrawerItem(
                  icon: Icons.people_outline,
                  label: 'Teachers',
                  onTap: () {
                    Navigator.pop(context);
                    final childId = _children.isNotEmpty
                        ? (_children[_selectedChildIndex]['studentId']
                                  as String? ??
                              _children[_selectedChildIndex]['id'] as String? ??
                              '')
                        : '';
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ParentTeachersScreen(
                          studentId: childId,
                          childName: _childName,
                        ),
                      ),
                    );
                  },
                ),
                _DrawerItem(
                  icon: Icons.book_outlined,
                  label: 'Subjects',
                  onTap: () {
                    Navigator.pop(context);
                    final childId = _children.isNotEmpty
                        ? (_children[_selectedChildIndex]['studentId']
                                  as String? ??
                              _children[_selectedChildIndex]['id'] as String? ??
                              '')
                        : '';
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ParentSubjectListScreen(
                          studentId: childId,
                          childName: _childName,
                        ),
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                _DrawerSection(title: 'COMMUNICATION'),
                _DrawerItem(
                  icon: Icons.chat_outlined,
                  label: 'Chat',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ParentChatScreen(),
                      ),
                    );
                  },
                ),
                _DrawerItem(
                  icon: Icons.history_edu_outlined,
                  label: 'Chat History',
                  onTap: () {
                    Navigator.pop(context);
                    final childId = _children.isNotEmpty
                        ? (_children[_selectedChildIndex]['studentId']
                                  as String? ??
                              _children[_selectedChildIndex]['id'] as String? ??
                              '')
                        : '';
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ParentChildChatHistoryScreen(
                          studentId: childId,
                          childName: _childName,
                        ),
                      ),
                    );
                  },
                ),
                _DrawerItem(
                  icon: Icons.campaign_outlined,
                  label: 'Announcements',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ParentAnnouncementsScreen(),
                      ),
                    );
                  },
                ),
                _DrawerItem(
                  icon: Icons.notifications_outlined,
                  label: 'Notifications',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ParentNotificationsScreen(),
                      ),
                    );
                  },
                ),
                _DrawerItem(
                  icon: Icons.feedback_outlined,
                  label: 'Feedback',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ParentFeedbackScreen(),
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                _DrawerSection(title: 'REPORTS'),
                _DrawerItem(
                  icon: Icons.assessment_outlined,
                  label: 'Weekly Report',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            WeeklyReportScreen(childName: _childName),
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                _DrawerItem(
                  icon: Icons.person_outline,
                  label: 'Profile',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ParentProfileScreen(),
                      ),
                    );
                  },
                ),
                _DrawerItem(
                  icon: Icons.settings_outlined,
                  label: 'Settings',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ParentSettingsScreen(),
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
                      if (!mounted) return;
                      Navigator.pushReplacementNamed(context, RouteNames.login);
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

  Widget _buildOverviewSection() {
    final theme = Theme.of(context);
    final grades = _childDashboard['grades'] as Map<String, dynamic>? ?? {};
    final attendance = _childDashboard['attendance'] as Map<String, dynamic>? ?? {};
    final upcoming = _childDashboard['upcoming'] as Map<String, dynamic>? ?? {};
    final upcomingSummary = upcoming['summary'] as Map<String, dynamic>? ?? {};

    final overallAvg = grades['overallAveragePercent'] as num?;
    final attOverall = attendance['overall'] as Map<String, dynamic>? ?? {};
    final attPercent = attOverall['attendancePercent'] as num?;
    final pendingAssignments = upcomingSummary['assignmentsPending'] as int? ?? 0;
    final availableExams = upcomingSummary['examsAvailable'] as int? ?? 0;
    final pendingTasks = pendingAssignments + availableExams;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'OVERVIEW',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
                letterSpacing: 0.8,
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => WeeklyReportScreen(childName: _childName),
                  ),
                );
              },
              child: Text(
                'View Report',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _OverviewCard(
                icon: Icons.trending_up,
                iconColor: AppColors.secondary,
                label: 'AVERAGE',
                value: overallAvg != null
                    ? '${overallAvg.toStringAsFixed(1)}%'
                    : '--',
                subtitle: 'All subjects',
                subtitleColor: AppColors.secondary,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _OverviewCard(
                icon: Icons.check_circle_outline,
                iconColor: AppColors.primary,
                label: 'ATTENDANCE',
                value: attPercent != null
                    ? '${attPercent.toStringAsFixed(1)}%'
                    : '--',
                subtitle: '${attOverall['absent'] ?? 0} absences',
                subtitleColor: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _OverviewCard(
                icon: Icons.assignment_outlined,
                iconColor: Colors.orange,
                label: 'TASKS',
                value: '$pendingTasks',
                subtitle: 'Due Soon',
                subtitleColor: AppColors.error,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGradesBySubject() {
    final theme = Theme.of(context);
    final grades = _childDashboard['grades'] as Map<String, dynamic>? ?? {};
    final bySubject = (grades['bySubject'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();

    if (bySubject.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'GRADES BY SUBJECT',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
                letterSpacing: 0.8,
              ),
            ),
            GestureDetector(
              onTap: () {
                final childId = _children.isNotEmpty
                    ? (_children[_selectedChildIndex]['studentId'] as String? ??
                        _children[_selectedChildIndex]['id'] as String? ?? '')
                    : '';
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ParentSubjectListScreen(
                      studentId: childId,
                      childName: _childName,
                    ),
                  ),
                );
              },
              child: Text(
                'View All',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Column(
            children: bySubject.asMap().entries.map((entry) {
              final i = entry.key;
              final s = entry.value;
              final name = s['subjectName'] as String? ?? 'Subject';
              final avg = s['averagePercent'] as num?;
              final graded = s['gradedEntries'] as int? ?? 0;

              final colors = [
                AppColors.primary,
                AppColors.secondary,
                const Color(0xFF7C4DFF),
                const Color(0xFFFF6D00),
                const Color(0xFF00BFA5),
              ];
              final color = colors[i % colors.length];
              final pct = avg ?? 0;
              final barWidth = (pct / 100).clamp(0.0, 1.0);

              return Column(
                children: [
                  if (i > 0)
                    Divider(height: 1, color: theme.colorScheme.outlineVariant),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              name.isNotEmpty ? name[0] : '?',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    name,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                  Text(
                                    avg != null
                                        ? '${avg.toStringAsFixed(1)}%'
                                        : '--',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: avg != null
                                          ? (avg >= 80
                                              ? Colors.green
                                              : avg >= 60
                                                  ? Colors.orange
                                                  : AppColors.error)
                                          : theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: barWidth,
                                  backgroundColor:
                                      color.withValues(alpha: 0.12),
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(color),
                                  minHeight: 6,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$graded graded entries',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildUpcomingTasks() {
    final theme = Theme.of(context);
    final upcoming =
        _childDashboard['upcoming'] as Map<String, dynamic>? ?? {};
    final exams = (upcoming['exams'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    final assignments = (upcoming['assignments'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();

    if (exams.isEmpty && assignments.isEmpty) return const SizedBox.shrink();

    String _formatDeadline(String? iso) {
      if (iso == null) return '';
      try {
        final d = DateTime.parse(iso).toLocal();
        final diff = d.difference(DateTime.now());
        if (diff.inDays == 0) return 'Today';
        if (diff.inDays == 1) return 'Tomorrow';
        if (diff.inDays < 7) return 'In ${diff.inDays} days';
        return '${d.month}/${d.day}';
      } catch (_) {
        return '';
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'UPCOMING',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurfaceVariant,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 12),
        ...exams.take(3).map((exam) {
          final status = exam['status'] as String? ?? '';
          final isAvailable = status == 'available';
          return _UpcomingTaskCard(
            icon: Icons.quiz_outlined,
            iconColor: isAvailable ? AppColors.error : AppColors.primary,
            title: exam['title'] as String? ?? 'Exam',
            subtitle: isAvailable ? 'Available now' : 'Exam',
            deadline: _formatDeadline(exam['opensAt'] as String?),
            tag: isAvailable ? 'OPEN' : 'UPCOMING',
            tagColor: isAvailable ? AppColors.error : AppColors.primary,
          );
        }),
        ...assignments.take(3).map((asgn) {
          final status = asgn['status'] as String? ?? '';
          return _UpcomingTaskCard(
            icon: Icons.assignment_outlined,
            iconColor: Colors.orange,
            title: asgn['title'] as String? ?? 'Assignment',
            subtitle: 'Assignment',
            deadline: _formatDeadline(asgn['deadline'] as String?),
            tag: status.toUpperCase(),
            tagColor: status == 'pending' ? Colors.orange : Colors.green,
          );
        }),
      ],
    );
  }

  Widget _buildFeatureGrid(BuildContext context) {
    final theme = Theme.of(context);
    final childId = _children.isNotEmpty
        ? (_children[_selectedChildIndex]['studentId'] as String? ??
              _children[_selectedChildIndex]['id'] as String? ??
              '')
        : '';

    // Only show 4 main quick actions
    final features = <_FeatureItem>[
      _FeatureItem(
        icon: Icons.person_outline,
        label: 'Student\nInfo',
        color: const Color(0xFF7C4DFF),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ParentStudentInfoScreen(
              childName: _childName,
              studentUserId: childId,
            ),
          ),
        ),
      ),
      _FeatureItem(
        icon: Icons.grade_outlined,
        label: 'Academic\nResults',
        color: AppColors.primary,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ParentResultsScreen()),
        ),
      ),
      _FeatureItem(
        icon: Icons.event_available_outlined,
        label: 'Attendance\nRecord',
        color: AppColors.secondary,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ParentAttendanceScreen(
              studentId: childId,
              childName: _childName,
            ),
          ),
        ),
      ),
      _FeatureItem(
        icon: Icons.book_outlined,
        label: 'Subjects\nInfo',
        color: const Color(0xFF00BFA5),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ParentSubjectListScreen(
              studentId: childId,
              childName: _childName,
            ),
          ),
        ),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'QUICK ACCESS',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurfaceVariant,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: features.map((f) {
            return Expanded(
              child: GestureDetector(
                onTap: f.onTap,
                child: Column(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: f.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(f.icon, color: f.color, size: 26),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      f.label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildContactTeacher() {
    final childId = _children.isNotEmpty
        ? (_children[_selectedChildIndex]['studentId'] as String? ??
              _children[_selectedChildIndex]['id'] as String? ??
              '')
        : '';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                ParentTeachersScreen(studentId: childId, childName: _childName),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1A73E8), Color(0xFF4A9AF5)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Contact Teacher',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'View and message your child\'s teachers.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.arrow_forward,
                color: Colors.white,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    final theme = Theme.of(context);

    // Fetch notifications instead of using summary activities
    return FutureBuilder<List<dynamic>>(
      future: ApiService().getNotifications(),
      builder: (context, snapshot) {
        final notifications = snapshot.data ?? [];
        final displayNotifications = notifications.take(3).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'RECENT ACTIVITY',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurfaceVariant,
                    letterSpacing: 0.8,
                  ),
                ),
                if (notifications.length > 3)
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ParentNotificationsScreen(),
                        ),
                      );
                    },
                    child: Text(
                      'View All',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (snapshot.connectionState == ConnectionState.waiting)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (displayNotifications.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'No recent activity',
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
              )
            else
              ...displayNotifications.map<Widget>((notification) {
                final type = notification['type'] as String? ?? '';
                final category = notification['category'] as String? ?? '';
                IconData icon;
                Color iconColor;
                Color iconBgColor;

                // Determine icon based on type or category
                if (type.contains('grade') || category.contains('grade')) {
                  icon = Icons.grade;
                  iconColor = AppColors.primary;
                  iconBgColor = AppColors.primary.withValues(alpha: 0.1);
                } else if (type.contains('attendance') ||
                    category.contains('attendance')) {
                  icon = Icons.event_available;
                  iconColor = AppColors.secondary;
                  iconBgColor = AppColors.secondary.withValues(alpha: 0.1);
                } else if (type.contains('assignment') ||
                    category.contains('assignment')) {
                  icon = Icons.assignment;
                  iconColor = Colors.orange;
                  iconBgColor = Colors.orange.withValues(alpha: 0.1);
                } else if (type.contains('announcement') ||
                    category.contains('announcement')) {
                  icon = Icons.campaign;
                  iconColor = Colors.purple;
                  iconBgColor = Colors.purple.withValues(alpha: 0.1);
                } else {
                  icon = Icons.notifications;
                  iconColor = Colors.blue;
                  iconBgColor = Colors.blue.withValues(alpha: 0.1);
                }

                return _ActivityItem(
                  icon: icon,
                  iconBgColor: iconBgColor,
                  iconColor: iconColor,
                  title: notification['title'] as String? ?? 'Notification',
                  subtitle:
                      notification['message'] as String? ??
                      notification['body'] as String? ??
                      '',
                  time: _formatNotificationTime(
                    notification['createdAt'] as String?,
                  ),
                  tag: notification['isRead'] == false ? 'NEW' : null,
                );
              }),
          ],
        );
      },
    );
  }

  String _formatNotificationTime(String? timestamp) {
    if (timestamp == null) return '';
    try {
      final date = DateTime.parse(timestamp);
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inMinutes < 60) {
        return '${diff.inMinutes}m ago';
      } else if (diff.inHours < 24) {
        return '${diff.inHours}h ago';
      } else if (diff.inDays < 7) {
        return '${diff.inDays}d ago';
      } else {
        return '${date.month}/${date.day}';
      }
    } catch (e) {
      return '';
    }
  }

  Widget _buildBottomNav() {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: theme.colorScheme.primary,
        unselectedItemColor: theme.colorScheme.onSurfaceVariant,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        elevation: 0,
        onTap: (index) {
          if (index == 0) return;
          Widget? screen;
          switch (index) {
            case 1:
              screen = const ParentChatScreen();
            case 2:
              screen = const ParentAnnouncementsScreen();
            case 3:
              screen = const ParentSettingsScreen();
          }
          if (screen != null) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => screen!));
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.campaign_outlined),
            label: 'Announcements',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class _DrawerSection extends StatelessWidget {
  final String title;
  const _DrawerSection({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade500,
          letterSpacing: 0.8,
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
    final itemColor = color ?? theme.colorScheme.onSurface;

    return ListTile(
      leading: Icon(icon, color: itemColor, size: 22),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: itemColor,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      minLeadingWidth: 24,
    );
  }
}

class _OverviewCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String subtitle;
  final Color subtitleColor;

  const _OverviewCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.subtitle,
    required this.subtitleColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: subtitleColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String time;
  final String? teacher;
  final String? tag;

  const _ActivityItem({
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.time,
    this.teacher,
    this.tag,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      time,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
                if (teacher != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 10,
                        backgroundColor: AppColors.secondary.withValues(
                          alpha: 0.15,
                        ),
                        child: const Icon(
                          Icons.person,
                          size: 12,
                          color: AppColors.secondary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        teacher!,
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
                if (tag != null) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      tag!,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureItem {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  _FeatureItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}

class _UpcomingTaskCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String deadline;
  final String tag;
  final Color tagColor;

  const _UpcomingTaskCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.deadline,
    required this.tag,
    required this.tagColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: theme.colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: tagColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  tag,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: tagColor,
                  ),
                ),
              ),
              if (deadline.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  deadline,
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
