import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/offline_banner.dart';
import '../../../../core/services/api_service.dart';
import '../../student_info/screens/parent_student_info_screen.dart';
import '../../student_info/screens/parent_results_screen.dart';
import '../../attendance/screens/parent_attendance_screen.dart';
import '../../chat/screens/parent_chat_screen.dart';
import '../../announcements/screens/parent_announcements_screen.dart';
import '../../feedback/screens/parent_feedback_screen.dart';
import '../../reports/screens/weekly_report_screen.dart';
import '../../notifications/screens/parent_notifications_screen.dart';
import '../../profile_settings/screens/parent_settings_screen.dart';
import '../../../shared/widgets/role_page_background.dart';

class ParentDashboardScreen extends StatefulWidget {
  final String? initialChildId;

  const ParentDashboardScreen({super.key, this.initialChildId});

  @override
  State<ParentDashboardScreen> createState() => _ParentDashboardScreenState();
}

class _ParentDashboardScreenState extends State<ParentDashboardScreen> {
  bool _loading = true;
  String? _error;
  int _selectedChildIndex = 0;
  List<Map<String, dynamic>> _children = [];
  Map<String, dynamic> _currentSummary = {};

  @override
  void initState() {
    super.initState();
    _loadData();
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
          'fullName': '${student?['firstName'] ?? ''} ${student?['lastName'] ?? ''}'.trim(),
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

  Future<void> _loadChildSummary() async {
    try {
      final child = _children[_selectedChildIndex];
      final studentId =
          child['studentId'] as String? ?? child['id'] as String? ?? '';
      final summary = await ApiService().getChildSummary(studentId);
      if (!mounted) return;
      setState(() {
        _currentSummary = summary;
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
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
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 20, 0),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new,
              color: theme.colorScheme.onSurface,
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
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
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ParentNotificationsScreen(),
              ),
            ),
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
        ],
      ),
    );
  }

  Widget _buildOverviewSection() {
    final theme = Theme.of(context);
    final average = _currentSummary['average']?.toString() ?? '--';
    final avgDelta = _currentSummary['avgDelta']?.toString() ?? '';
    final attendance = _currentSummary['attendance']?.toString() ?? '--';
    final absences = _currentSummary['absences']?.toString() ?? '--';
    final tasks =
        _currentSummary['pendingTasks']?.toString() ??
        _currentSummary['tasks']?.toString() ??
        '0';

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
            Text(
              'View Report',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
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
                value: average.contains('%') ? average : '$average%',
                subtitle: avgDelta,
                subtitleColor: AppColors.secondary,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _OverviewCard(
                icon: Icons.check_circle_outline,
                iconColor: AppColors.primary,
                label: 'ATTENDANCE',
                value: attendance.contains('%') ? attendance : '$attendance%',
                subtitle: absences,
                subtitleColor: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _OverviewCard(
                icon: Icons.assignment_outlined,
                iconColor: Colors.orange,
                label: 'TASKS',
                value: tasks,
                subtitle: 'Due Soon',
                subtitleColor: AppColors.error,
              ),
            ),
          ],
        ),
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
        icon: Icons.chat_bubble_outline,
        label: 'Messages',
        color: const Color(0xFF00BFA5),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ParentChatScreen()),
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
    return Container(
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
                  'Reach out to your child\'s teacher.',
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
            child: const Icon(Icons.chat_bubble, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    final theme = Theme.of(context);
    final activities =
        (_currentSummary['recentActivity'] as List<dynamic>?) ?? [];
    
    // Show only top 3 activities
    final displayActivities = activities.take(3).toList();
    
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
            if (activities.length > 3)
              GestureDetector(
                onTap: () {
                  // Navigate to notifications screen to see all
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
        if (displayActivities.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                'No recent activity',
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
          ),
        ...displayActivities.map<Widget>((a) {
          final type = a['type'] as String? ?? '';
          IconData icon;
          Color iconColor;
          Color iconBgColor;
          switch (type) {
            case 'quiz':
            case 'exam':
            case 'grade':
              icon = Icons.quiz;
              iconColor = AppColors.primary;
              iconBgColor = AppColors.primary.withValues(alpha: 0.1);
            case 'submission':
            case 'assignment':
              icon = Icons.description;
              iconColor = Colors.grey.shade600;
              iconBgColor = Colors.grey.shade100;
            case 'attendance':
              icon = Icons.access_time;
              iconColor = AppColors.secondary;
              iconBgColor = AppColors.secondary.withValues(alpha: 0.1);
            default:
              icon = Icons.menu_book;
              iconColor = Colors.purple;
              iconBgColor = Colors.purple.withValues(alpha: 0.1);
          }
          return _ActivityItem(
            icon: icon,
            iconBgColor: iconBgColor,
            iconColor: iconColor,
            title: a['title'] as String? ?? '',
            subtitle: a['description'] as String? ?? '',
            time: a['time'] as String? ?? a['date'] as String? ?? '',
            teacher: a['teacher'] as String?,
            tag: a['tag'] as String?,
          );
        }),
      ],
    );
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
