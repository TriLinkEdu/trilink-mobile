import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/offline_banner.dart';

class ParentDashboardScreen extends StatefulWidget {
  const ParentDashboardScreen({super.key});

  @override
  State<ParentDashboardScreen> createState() => _ParentDashboardScreenState();
}

class _ParentDashboardScreenState extends State<ParentDashboardScreen> {
  int _selectedChildIndex = 0;

  final List<Map<String, String>> _children = [
    {'name': 'Ahmed Al-Rashid', 'id': '99281', 'avatar': 'https://i.pravatar.cc/80?img=47'},
    {'name': 'Sara Al-Rashid', 'id': '99282', 'avatar': 'https://i.pravatar.cc/80?img=32'},
  ];

  final List<Map<String, String>> _overviewData = [
    {'average': '89%', 'avgDelta': '+2.1%', 'attendance': '96%', 'absences': '2 Absences', 'tasks': '3'},
    {'average': '92%', 'avgDelta': '+3.5%', 'attendance': '98%', 'absences': '1 Absence', 'tasks': '1'},
  ];

  String get _childName => _children[_selectedChildIndex]['name']!;
  String get _childAvatar => _children[_selectedChildIndex]['avatar']!;

  void _showChildPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Select Child', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            ...List.generate(_children.length, (i) {
              final child = _children[i];
              return ListTile(
                leading: CircleAvatar(backgroundImage: NetworkImage(child['avatar']!)),
                title: Text(child['name']!),
                trailing: _selectedChildIndex == i
                    ? const Icon(Icons.check_circle, color: AppColors.primary)
                    : null,
                onTap: () {
                  setState(() => _selectedChildIndex = i);
                  Navigator.pop(ctx);
                },
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: OfflineBanner(
        child: SafeArea(
          child: SingleChildScrollView(
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
                      const SizedBox(height: 16),
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
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          const Icon(Icons.menu, color: AppColors.textPrimary),
          const SizedBox(width: 12),
          CircleAvatar(
            radius: 18,
            backgroundImage: NetworkImage(_childAvatar),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _showChildPicker,
            child: Row(
              children: [
                Text(
                  _childName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Icon(Icons.keyboard_arrow_down, size: 20),
              ],
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.notifications_outlined,
              color: Colors.grey.shade700,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewSection() {
    final data = _overviewData[_selectedChildIndex];
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
                color: Colors.grey.shade500,
                letterSpacing: 0.8,
              ),
            ),
            const Text(
              'View Report',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
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
                value: data['average']!,
                subtitle: data['avgDelta']!,
                subtitleColor: AppColors.secondary,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _OverviewCard(
                icon: Icons.check_circle_outline,
                iconColor: AppColors.primary,
                label: 'ATTENDANCE',
                value: data['attendance']!,
                subtitle: data['absences']!,
                subtitleColor: Colors.grey.shade500,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _OverviewCard(
                icon: Icons.assignment_outlined,
                iconColor: Colors.orange,
                label: 'TASKS',
                value: data['tasks']!,
                subtitle: 'Due Soon',
                subtitleColor: AppColors.error,
              ),
            ),
          ],
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
                  'Mr. Davis is available for a chat.',
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
                color: Colors.grey.shade500,
                letterSpacing: 0.8,
              ),
            ),
            Icon(Icons.tune, size: 18, color: Colors.grey.shade500),
          ],
        ),
        const SizedBox(height: 12),
        _ActivityItem(
          icon: Icons.quiz,
          iconBgColor: AppColors.primary.withValues(alpha: 0.1),
          iconColor: AppColors.primary,
          title: 'Algebra II Quiz',
          subtitle:
              '"Great job on the polynomials section, keep it up!"',
          teacher: 'Mr. Davis',
          time: '2h ago',
        ),
        _ActivityItem(
          icon: Icons.description,
          iconBgColor: Colors.grey.shade100,
          iconColor: Colors.grey.shade600,
          title: 'History Essay',
          subtitle: 'Draft submitted successfully. Pending review.',
          time: '5h ago',
          tag: 'Submission',
        ),
        _ActivityItem(
          icon: Icons.access_time,
          iconBgColor: AppColors.secondary.withValues(alpha: 0.1),
          iconColor: AppColors.secondary,
          title: 'Late Arrival',
          subtitle: 'Arrived at 8:45 AM. Reason: Medical Appointment.',
          time: 'Yesterday',
          tag: 'Excused',
          tagColor: AppColors.secondary,
        ),
        _ActivityItem(
          icon: Icons.menu_book,
          iconBgColor: Colors.purple.withValues(alpha: 0.1),
          iconColor: Colors.purple,
          title: 'English Reading',
          subtitle:
              'Chapter 4-5 assigned for weekend reading.',
          time: '2d ago',
        ),
      ],
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
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
        backgroundColor: Colors.white,
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
            icon: Icon(Icons.chat_bubble_outline),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
            label: 'Calendar',
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
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade500,
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
  final Color? tagColor;

  const _ActivityItem({
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.time,
    this.teacher,
    this.tag,
    this.tagColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
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
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      time,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                ),
                if (teacher != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 10,
                        backgroundColor: AppColors.secondary.withValues(alpha: 0.15),
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
                          color: Colors.grey.shade600,
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
                      color: (tagColor ?? AppColors.primary)
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      tag!,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: tagColor ?? AppColors.primary,
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
