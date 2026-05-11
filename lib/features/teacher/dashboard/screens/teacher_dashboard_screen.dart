import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/offline_banner.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/routes/route_names.dart';
import '../../../auth/services/auth_service.dart';
import '../../attendance/screens/teacher_attendance_screen.dart';
import '../../announcements/screens/create_announcement_screen.dart';
import '../../classes/screens/class_list_screen.dart';
import '../../notifications/screens/teacher_notifications_screen.dart';

class TeacherDashboardScreen extends StatefulWidget {
  const TeacherDashboardScreen({super.key});

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen> {
  bool _loading = true;
  String? _error;

  int _totalClasses = 0;
  int _classesToday = 0;
  int _pendingGrading = 0;
  int _unreadNotifications = 0;
  double _attendanceRate = 0;
  int _publishedExams = 0;
  List<Map<String, dynamic>> _notifications = [];

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

      final today = DateTime.now();
      final todayStr =
          '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      final results = await Future.wait([
        ApiService().getTeacherDashboard(),
        ApiService().getNotifications(),
        ApiService().getCalendarEvents(from: todayStr, to: todayStr),
        ApiService().getTeacherAssignments(),
      ]);
      if (!mounted) return;
      final data = results[0] as Map<String, dynamic>;
      final notifs = results[1] as List<dynamic>;
      final todaysEvents = results[2] as List<dynamic>;
      final assignments = results[3] as List<dynamic>;

      // Count today's class-related events (class sessions)
      final todaysClassEvents = todaysEvents.where((e) {
        final m = e as Map<String, dynamic>;
        final type = (m['type'] as String? ?? '').toLowerCase();
        return type == 'class' ||
            type == 'lecture' ||
            type == 'session' ||
            m['classOfferingId'] != null;
      }).length;

      // Pending grades = backend approx + ungraded assignment submissions
      final backendPending = (data['pendingGradingApprox'] as num?)?.toInt() ?? 0;
      int pendingFromAssignments = 0;
      for (final a in assignments) {
        final m = a as Map<String, dynamic>;
        final submitted =
            (m['submissionCount'] as num? ?? m['totalSubmissions'] as num? ?? 0)
                .toInt();
        final graded =
            (m['gradedCount'] as num? ?? m['totalGraded'] as num? ?? 0)
                .toInt();
        if (submitted > graded) pendingFromAssignments += (submitted - graded);
      }

      setState(() {
        _totalClasses = (data['myClasses'] as num?)?.toInt() ?? 0;
        _classesToday = todaysClassEvents;
        _pendingGrading = backendPending + pendingFromAssignments;
        _unreadNotifications =
            (data['unreadNotifications'] as num?)?.toInt() ?? 0;
        _attendanceRate =
            (data['attendanceRate'] as num?)?.toDouble() ?? 0.0;
        _publishedExams = (data['publishedExams'] as num?)?.toInt() ?? 0;
        _notifications = notifs.cast<Map<String, dynamic>>();
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

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String get _teacherName {
    final user = AuthService().currentUser;
    if (user == null) return 'Teacher';
    return user.firstName;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Note: This screen is embedded in TeacherMainScreen which provides the AppBar
    // So we don't need our own Scaffold here
    return OfflineBanner(
      child: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? _buildErrorState(theme)
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildGreetingHeader(),
                    const SizedBox(height: 24),
                    _buildUpNextCard(context),
                    const SizedBox(height: 20),
                    _buildStatsRow(),
                    const SizedBox(height: 28),
                    _buildQuickActions(context),
                    const SizedBox(height: 28),
                    _buildRecentActivity(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load dashboard',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? '',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGreetingHeader() {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final dateStr = DateFormat('EEEE, MMM d').format(now);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dateStr,
                style: TextStyle(
                  fontSize: 13,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                '$_greeting, $_teacherName',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const TeacherNotificationsScreen(),
              ),
            );
            // Refresh unread count on return
            _loadData();
          },
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: theme.shadowColor.withOpacity(0.16),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Badge(
              isLabelVisible: _unreadNotifications > 0,
              label: Text(
                _unreadNotifications > 99 ? '99+' : '$_unreadNotifications',
              ),
              child: Icon(
                Icons.notifications_outlined,
                color: theme.colorScheme.onSurfaceVariant,
                size: 22,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUpNextCard(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'UP NEXT',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurfaceVariant,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: theme.ext.heroGradient,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onPrimary.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$_classesToday classes today',
                      style: TextStyle(
                        color: theme.colorScheme.onPrimary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onPrimary.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.school,
                      color: theme.colorScheme.onPrimary,
                      size: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                AuthService().currentUser?.subject ?? 'My Subject',
                style: TextStyle(
                  color: theme.colorScheme.onPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    Icons.person,
                    color: theme.colorScheme.onPrimary.withOpacity(0.8),
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    AuthService().currentUser?.fullName ?? '',
                    style: TextStyle(
                      color: theme.colorScheme.onPrimary.withOpacity(0.8),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    final theme = Theme.of(context);
    final ratePct = (_attendanceRate * 100).clamp(0.0, 100.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.class_outlined,
                iconColor: theme.colorScheme.secondary,
                label: 'Total Classes',
                value: '$_totalClasses',
                subtitle: 'assigned',
                subtitleColor: theme.colorScheme.secondary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.assignment_outlined,
                iconColor: Colors.purple.shade400,
                label: 'Pending Grades',
                value: '$_pendingGrading',
                subtitle: 'to grade',
                subtitleColor: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _InfoChip(
                icon: Icons.fact_check_outlined,
                label: 'Attendance',
                value: '${ratePct.toStringAsFixed(0)}%',
                color: ratePct >= 80
                    ? Colors.green
                    : ratePct >= 60
                        ? Colors.orange
                        : Colors.red,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _InfoChip(
                icon: Icons.quiz_outlined,
                label: 'Exams Published',
                value: '$_publishedExams',
                color: theme.colorScheme.tertiary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        // 2×2 grid of quick actions
        Row(
          children: [
            Expanded(
              child: _QuickActionButton(
                icon: Icons.fact_check_outlined,
                label: 'Take\nAttendance',
                color: theme.colorScheme.primary,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const TeacherAttendanceScreen(),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionButton(
                icon: Icons.class_outlined,
                label: 'My\nClasses',
                color: theme.colorScheme.secondary,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ClassListScreen()),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionButton(
                icon: Icons.campaign_outlined,
                label: 'New\nPost',
                color: Colors.purple,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CreateAnnouncementScreen(),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionButton(
                icon: Icons.feedback_outlined,
                label: 'My\nFeedback',
                color: AppColors.subjectOrange,
                onTap: () =>
                    Navigator.pushNamed(context, RouteNames.teacherFeedback),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentActivity() {
    final theme = Theme.of(context);
    final top3 = _notifications.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Activity',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            TextButton(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const TeacherNotificationsScreen(),
                  ),
                );
                _loadData();
              },
              child: Text(
                'View All',
                style: TextStyle(color: theme.colorScheme.primary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (top3.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.notifications_none,
                  size: 36,
                  color: theme.colorScheme.outlineVariant,
                ),
                const SizedBox(height: 8),
                Text(
                  'No recent activity',
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          )
        else
          ...top3.asMap().entries.map((entry) {
            final i = entry.key;
            final n = entry.value;
            final type = n['type'] as String? ?? '';
            final title = n['title'] as String? ?? 'Notification';
            final body = n['body'] as String? ?? '';
            final createdAt = n['createdAt'] as String?;
            final isRead = n['readAt'] != null;

            final iconData = _iconForType(type);
            final iconColor = _colorForType(context, type);

            return Padding(
              padding: EdgeInsets.only(bottom: i < top3.length - 1 ? 12 : 0),
              child: _ActivityTile(
                icon: iconData,
                iconBgColor: iconColor.withOpacity(0.1),
                iconColor: iconColor,
                title: title,
                subtitle: body,
                time: _timeAgo(createdAt),
                isUnread: !isRead,
              ),
            );
          }),
      ],
    );
  }

  IconData _iconForType(String type) {
    switch (type.toLowerCase()) {
      case 'badge':
        return Icons.emoji_events;
      case 'broadcast':
        return Icons.campaign;
      case 'weekly_digest':
        return Icons.summarize;
      case 'attendance':
        return Icons.event_available;
      case 'announcement':
        return Icons.announcement;
      case 'exam_result':
      case 'grade':
        return Icons.grade;
      case 'exam_submission':
        return Icons.assignment_turned_in;
      case 'assignment':
        return Icons.assignment;
      case 'alert':
      case 'system':
        return Icons.warning_amber_rounded;
      default:
        return Icons.notifications;
    }
  }

  Color _colorForType(BuildContext context, String type) {
    final theme = Theme.of(context);
    switch (type.toLowerCase()) {
      case 'badge':
        return Colors.amber;
      case 'broadcast':
        return theme.colorScheme.primary;
      case 'weekly_digest':
        return Colors.blue;
      case 'attendance':
        return theme.colorScheme.secondary;
      case 'announcement':
        return theme.colorScheme.tertiary;
      case 'exam_result':
      case 'grade':
        return Colors.green;
      case 'exam_submission':
        return Colors.purple;
      case 'assignment':
        return theme.colorScheme.primary;
      case 'alert':
      case 'system':
        return theme.colorScheme.error;
      default:
        return theme.colorScheme.onSurfaceVariant;
    }
  }

  String _timeAgo(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      final diff = DateTime.now().difference(date);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${date.month}/${date.day}';
    } catch (_) {
      return '';
    }
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String subtitle;
  final Color subtitleColor;

  const _StatCard({
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.5),
        ),
        boxShadow: [
          BoxShadow(
              color: theme.shadowColor.withOpacity(0.08), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: subtitleColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String time;
  final bool isUnread;

  const _ActivityTile({
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.time,
    this.isUnread = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: theme.shadowColor.withOpacity(0.1), blurRadius: 8),
        ],
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
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontWeight: isUnread
                              ? FontWeight.bold
                              : FontWeight.w600,
                          fontSize: 14,
                          color: theme.colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
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
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (isUnread) ...[
            const SizedBox(width: 8),
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
