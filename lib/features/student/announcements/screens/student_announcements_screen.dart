import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class StudentAnnouncementsScreen extends StatefulWidget {
  const StudentAnnouncementsScreen({super.key});

  @override
  State<StudentAnnouncementsScreen> createState() =>
      _StudentAnnouncementsScreenState();
}

class _StudentAnnouncementsScreenState
    extends State<StudentAnnouncementsScreen> {
  int _selectedFilter = 0;
  final List<String> _filters = ['All', 'Admin', 'Teacher', 'Calendar'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Column(
          children: [
            // App bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 20,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'Announcements',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(
                      Icons.notifications_outlined,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),

            // Filter chips
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: List.generate(_filters.length, (index) {
                  final isSelected = _selectedFilter == index;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedFilter = index),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color:
                              isSelected ? AppColors.primary : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color:
                                isSelected
                                    ? AppColors.primary
                                    : Colors.grey.shade300,
                          ),
                        ),
                        child: Text(
                          _filters[index],
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: isSelected ? Colors.white : Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 16),

            // Announcements list
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  // TODAY section
                  _SectionHeader(title: 'TODAY'),
                  const SizedBox(height: 10),
                  const _AnnouncementItem(
                    icon: Icons.warning_amber_rounded,
                    iconColor: Colors.red,
                    iconBgColor: Color(0xFFFEE2E2),
                    title: 'Campus Closure Alert',
                    subtitle: 'Administration',
                    time: '20m ago',
                    body:
                        'Due to severe weather conditions expected this afternoon, all campus...',
                  ),
                  const SizedBox(height: 10),
                  const _AnnouncementItem(
                    icon: Icons.calendar_today_rounded,
                    iconColor: AppColors.primary,
                    iconBgColor: Color(0xFFDBEAFE),
                    title: 'Final Exam Schedule',
                    subtitle: 'Registrar Office',
                    time: '2h ago',
                    body:
                        'The schedule for the Spring 2024 final exams has been posted. Please revie...',
                  ),
                  const SizedBox(height: 20),

                  // YESTERDAY section
                  _SectionHeader(title: 'YESTERDAY'),
                  const SizedBox(height: 10),
                  const _AnnouncementItem(
                    icon: Icons.school_rounded,
                    iconColor: Colors.amber,
                    iconBgColor: Color(0xFFFEF3C7),
                    title: 'Biology 101: Class Can...',
                    subtitle: 'Dr. Sarah Johnson',
                    time: 'Yesterday',
                    body:
                        'Due to an unforeseen emergency, today\'s lecture is cancelled. Please...',
                  ),
                  const SizedBox(height: 10),
                  const _AnnouncementItem(
                    icon: Icons.assignment_rounded,
                    iconColor: Colors.purple,
                    iconBgColor: Color(0xFFEDE9FE),
                    title: 'New Assignment Posted',
                    subtitle: 'Prof. Alan Turing',
                    time: 'Yesterday',
                    body:
                        'The project requirements for "Intro to Algorithms" have been uploaded...',
                  ),
                  const SizedBox(height: 10),
                  const _AnnouncementItem(
                    icon: Icons.menu_book_rounded,
                    iconColor: Colors.green,
                    iconBgColor: Color(0xFFD1FAE5),
                    title: 'Library Hours Extended',
                    subtitle: 'Student Services',
                    time: '2d ago',
                    body:
                        'To help with finals preparation, the main library will remain open 24/7...',
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: Text(
                      'You\'re all caught up',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Colors.grey.shade500,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _AnnouncementItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String title;
  final String subtitle;
  final String time;
  final String body;

  const _AnnouncementItem({
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.title,
    required this.subtitle,
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
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
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
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 6),
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
