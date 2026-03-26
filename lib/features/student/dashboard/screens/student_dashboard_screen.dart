import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import '../../../../core/routes/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/services/auth_service.dart';
import '../models/dashboard_data_model.dart';
import '../repositories/student_dashboard_repository.dart';
import '../repositories/mock_student_dashboard_repository.dart';

class StudentDashboardScreen extends StatefulWidget {
  final StudentDashboardRepository? repository;

  const StudentDashboardScreen({super.key, this.repository});

  @override
  State<StudentDashboardScreen> createState() =>
      _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  late final StudentDashboardRepository _repo;
  DashboardDataModel? _data;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? MockStudentDashboardRepository();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await _repo.fetchDashboardData();
      if (mounted) setState(() { _data = data; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  String _dueIn(DateTime dt) {
    final diff = dt.difference(DateTime.now());
    if (diff.isNegative) return 'Overdue';
    if (diff.inMinutes < 60) return 'Due in ${diff.inMinutes}m';
    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;
    if (minutes == 0) return 'Due in ${hours}h';
    return 'Due in ${hours}h ${minutes}m';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.grey.shade50,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: Colors.grey.shade50,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    final data = _data!;
    final now = DateTime.now();
    final dateStr = intl.DateFormat('MMM dd, EEEE').format(now);
    final hour = now.hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';
    final userName = AuthService().currentUser?.name ?? 'Student';
    final firstName = userName.split(' ').first;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                dateStr,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$greeting, $firstName',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context)
                        .pushNamed(RouteNames.studentProfile),
                    child: const CircleAvatar(
                      radius: 22,
                      backgroundColor: AppColors.primary,
                      child: Icon(
                        Icons.person_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Stats Row
              Row(
                children: [
                  Expanded(
                    child: _StatChip(
                      icon: Icons.local_fire_department,
                      iconColor: Colors.green,
                      value: '${data.stats.streakDays}',
                      label: 'Day Streak',
                      onTap: () => Navigator.of(context)
                          .pushNamed(RouteNames.studentGamification),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatChip(
                      icon: Icons.star_rounded,
                      iconColor: Colors.amber,
                      value: '${data.stats.totalXp}',
                      label: 'Total XP',
                      onTap: () => Navigator.of(context)
                          .pushNamed(RouteNames.studentGamification),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatChip(
                      icon: Icons.emoji_events_rounded,
                      iconColor: AppColors.primary,
                      value: 'Lvl ${data.stats.level}',
                      label: data.stats.levelTitle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Next Up
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Next Up',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context)
                        .pushNamed(RouteNames.studentCalendar),
                    child: const Text(
                      'View Calendar',
                      style: TextStyle(color: AppColors.primary, fontSize: 13),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (data.nextUp != null)
                _NextUpCard(
                  title: data.nextUp!.title,
                  subtitle: data.nextUp!.subtitle,
                  dueText: _dueIn(data.nextUp!.dueAt),
                  participantCount: data.nextUp!.participantCount,
                  onPrepareTap: () => Navigator.of(context).pushNamed(
                    RouteNames.studentSubjectGrades,
                    arguments: {
                      'subjectId': data.nextUp!.subjectId,
                      'subjectName': data.nextUp!.subjectName,
                    },
                  ),
                ),
              const SizedBox(height: 28),

              // Quick Actions
              const Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 14),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 2.8,
                children: [
                  _QuickActionTile(
                    icon: Icons.quiz_rounded,
                    label: 'Gamification',
                    color: AppColors.primary,
                    onTap: () => Navigator.of(context)
                        .pushNamed(RouteNames.studentGamification),
                  ),
                  _QuickActionTile(
                    icon: Icons.menu_book_rounded,
                    label: 'AI Assistant',
                    color: Colors.orange,
                    onTap: () => Navigator.of(context)
                        .pushNamed(RouteNames.studentAiAssistant),
                  ),
                  _QuickActionTile(
                    icon: Icons.feedback_rounded,
                    label: 'Feedback',
                    color: Colors.green,
                    onTap: () => Navigator.of(context)
                        .pushNamed(RouteNames.studentFeedback),
                  ),
                  _QuickActionTile(
                    icon: Icons.bar_chart_rounded,
                    label: 'Grades',
                    color: Colors.purple,
                    onTap: () => Navigator.of(context)
                        .pushNamed(RouteNames.studentGrades),
                  ),
                  _QuickActionTile(
                    icon: Icons.notifications_rounded,
                    label: 'Notifications',
                    color: Colors.redAccent,
                    onTap: () => Navigator.of(context)
                        .pushNamed(RouteNames.studentNotifications),
                  ),
                  _QuickActionTile(
                    icon: Icons.chat_rounded,
                    label: 'Chat',
                    color: Colors.teal,
                    onTap: () => Navigator.of(context)
                        .pushNamed(RouteNames.studentChat),
                  ),
                  _QuickActionTile(
                    icon: Icons.calendar_month_rounded,
                    label: 'Calendar',
                    color: Colors.indigo,
                    onTap: () => Navigator.of(context)
                        .pushNamed(RouteNames.studentCalendar),
                  ),
                  _QuickActionTile(
                    icon: Icons.settings_rounded,
                    label: 'Settings',
                    color: Colors.blueGrey,
                    onTap: () => Navigator.of(context)
                        .pushNamed(RouteNames.studentSettings),
                  ),
                  _QuickActionTile(
                    icon: Icons.assignment_rounded,
                    label: 'Assignments',
                    color: Colors.deepOrange,
                    onTap: () => Navigator.of(context)
                        .pushNamed(RouteNames.studentAssignments),
                  ),
                  _QuickActionTile(
                    icon: Icons.folder_open_rounded,
                    label: 'Resources',
                    color: Colors.lightBlue,
                    onTap: () => Navigator.of(context)
                        .pushNamed(RouteNames.studentCourseResources),
                  ),
                  _QuickActionTile(
                    icon: Icons.fact_check_rounded,
                    label: 'Exam Attempt',
                    color: Colors.pink,
                    onTap: () => Navigator.of(context)
                        .pushNamed(RouteNames.studentExamAttempt),
                  ),
                  _QuickActionTile(
                    icon: Icons.sync_rounded,
                    label: 'Sync Status',
                    color: Colors.green,
                    onTap: () => Navigator.of(context)
                        .pushNamed(RouteNames.studentSyncStatus),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Announcements
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Announcements',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context)
                        .pushNamed(RouteNames.studentAnnouncements),
                    child: const Text(
                      'See All',
                      style: TextStyle(color: AppColors.primary, fontSize: 13),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...data.recentAnnouncements.map((a) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _AnnouncementTile(
                    avatarColor: _authorColor(a.authorName),
                    title: a.authorName,
                    time: _timeAgo(a.createdAt),
                    body: a.snippet,
                    onTap: () => Navigator.of(context).pushNamed(
                      RouteNames.studentAnnouncementDetail,
                      arguments: {'announcementId': a.id},
                    ),
                  ),
                );
              }),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Open AI Assistant',
        onPressed: () =>
            Navigator.of(context).pushNamed(RouteNames.studentAiAssistant),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.auto_awesome, color: Colors.white),
      ),
    );
  }

  static Color _authorColor(String name) {
    const colors = [
      AppColors.primary,
      Colors.brown,
      Colors.teal,
      Colors.deepPurple,
      Colors.orange,
      Colors.indigo,
    ];
    return colors[name.hashCode.abs() % colors.length];
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  final VoidCallback? onTap;

  const _StatChip({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final child = Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: child);
    }
    return child;
  }
}

class _NextUpCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String dueText;
  final int participantCount;
  final VoidCallback onPrepareTap;

  const _NextUpCard({
    required this.title,
    required this.subtitle,
    required this.dueText,
    required this.participantCount,
    required this.onPrepareTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.quiz_rounded,
              color: Colors.red.shade400,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        dueText,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.red.shade400,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    SizedBox(
                      width: 60,
                      height: 24,
                      child: Stack(
                        children: List.generate(2, (i) {
                          return Positioned(
                            left: i * 18.0,
                            child: CircleAvatar(
                              radius: 12,
                              backgroundColor:
                                  i == 0 ? Colors.orange : Colors.teal,
                              child: const Icon(
                                Icons.person,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                    Text(
                      '+$participantCount',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const Spacer(),
                    InkWell(
                      onTap: onPrepareTap,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Prepare',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(
                              Icons.arrow_forward,
                              color: Colors.white,
                              size: 14,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withAlpha(25),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AnnouncementTile extends StatelessWidget {
  final Color avatarColor;
  final String title;
  final String time;
  final String body;
  final VoidCallback? onTap;

  const _AnnouncementTile({
    required this.avatarColor,
    required this.title,
    required this.time,
    required this.body,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(8),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: avatarColor.withAlpha(30),
              child: Icon(Icons.person_rounded, color: avatarColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        time,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    body,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
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
