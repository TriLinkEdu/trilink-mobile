import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import '../../../../core/routes/route_names.dart';
import '../../../../core/theme/app_colors.dart';

class StudentDashboardScreen extends StatelessWidget {
  const StudentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateStr = intl.DateFormat('MMM dd, EEEE').format(now);
    final hour = now.hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
        ? 'Good afternoon'
        : 'Good evening';

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
                    '$greeting, Sara',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.primary,
                    child: Icon(
                      Icons.person_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Stats Row
              const Row(
                children: [
                  Expanded(
                    child: _StatChip(
                      icon: Icons.local_fire_department,
                      iconColor: Colors.green,
                      value: '12',
                      label: 'Day Streak',
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: _StatChip(
                      icon: Icons.star_rounded,
                      iconColor: Colors.amber,
                      value: '850',
                      label: 'Total XP',
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: _StatChip(
                      icon: Icons.emoji_events_rounded,
                      iconColor: AppColors.primary,
                      value: 'Lvl 5',
                      label: 'Scholar',
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
                    onPressed: () => Navigator.of(
                      context,
                    ).pushNamed(RouteNames.studentCalendar),
                    child: const Text(
                      'View Calendar',
                      style: TextStyle(color: AppColors.primary, fontSize: 13),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _NextUpCard(
                onPrepareTap: () => Navigator.of(context).pushNamed(
                  RouteNames.studentSubjectGrades,
                  arguments: {
                    'subjectId': 'physics',
                    'subjectName': 'Physics',
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
                    onTap: () => Navigator.of(
                      context,
                    ).pushNamed(RouteNames.studentGamification),
                  ),
                  _QuickActionTile(
                    icon: Icons.menu_book_rounded,
                    label: 'AI Assistant',
                    color: Colors.orange,
                    onTap: () => Navigator.of(
                      context,
                    ).pushNamed(RouteNames.studentAiAssistant),
                  ),
                  _QuickActionTile(
                    icon: Icons.feedback_rounded,
                    label: 'Feedback',
                    color: Colors.green,
                    onTap: () => Navigator.of(
                      context,
                    ).pushNamed(RouteNames.studentFeedback),
                  ),
                  _QuickActionTile(
                    icon: Icons.bar_chart_rounded,
                    label: 'Grades',
                    color: Colors.purple,
                    onTap: () => Navigator.of(
                      context,
                    ).pushNamed(RouteNames.studentGrades),
                  ),
                  _QuickActionTile(
                    icon: Icons.notifications_rounded,
                    label: 'Notifications',
                    color: Colors.redAccent,
                    onTap: () => Navigator.of(
                      context,
                    ).pushNamed(RouteNames.studentNotifications),
                  ),
                  _QuickActionTile(
                    icon: Icons.chat_rounded,
                    label: 'Chat',
                    color: Colors.teal,
                    onTap: () => Navigator.of(
                      context,
                    ).pushNamed(RouteNames.studentChat),
                  ),
                  _QuickActionTile(
                    icon: Icons.calendar_month_rounded,
                    label: 'Calendar',
                    color: Colors.indigo,
                    onTap: () => Navigator.of(
                      context,
                    ).pushNamed(RouteNames.studentCalendar),
                  ),
                  _QuickActionTile(
                    icon: Icons.settings_rounded,
                    label: 'Settings',
                    color: Colors.blueGrey,
                    onTap: () => Navigator.of(
                      context,
                    ).pushNamed(RouteNames.studentSettings),
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
                    onPressed: () {
                      Navigator.of(
                        context,
                      ).pushNamed(RouteNames.studentAnnouncements);
                    },
                    child: const Text(
                      'See All',
                      style: TextStyle(color: AppColors.primary, fontSize: 13),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const _AnnouncementTile(
                avatar: Icons.business_rounded,
                avatarColor: AppColors.primary,
                title: 'Admin Office',
                time: '10m ago',
                body:
                    'School will be closed tomorrow due to heavy maintenance work in the main block. Onlin...',
              ),
              const SizedBox(height: 10),
              const _AnnouncementTile(
                avatar: Icons.person_rounded,
                avatarColor: Colors.brown,
                title: 'Mr. Abebe',
                time: '2h ago',
                body:
                    'Assignment 3 grades have been released. Please check your grades section for...',
              ),
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
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  const _StatChip({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
  }
}

class _NextUpCard extends StatelessWidget {
  final VoidCallback onPrepareTap;

  const _NextUpCard({required this.onPrepareTap});

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
                    const Text(
                      'Physics Quiz',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
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
                        'Due in 2h 15m',
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
                  'Chapter 4: Thermodynamics',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    // Student avatars
                    SizedBox(
                      width: 60,
                      height: 24,
                      child: Stack(
                        children: List.generate(2, (i) {
                          return Positioned(
                            left: i * 18.0,
                            child: CircleAvatar(
                              radius: 12,
                              backgroundColor: i == 0
                                  ? Colors.orange
                                  : Colors.teal,
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
                      '+12',
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
  final IconData avatar;
  final Color avatarColor;
  final String title;
  final String time;
  final String body;

  const _AnnouncementTile({
    required this.avatar,
    required this.avatarColor,
    required this.title,
    required this.time,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
            child: Icon(avatar, color: avatarColor, size: 20),
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
    );
  }
}
