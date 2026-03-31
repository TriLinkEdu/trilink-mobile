import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class ParentStudentInfoScreen extends StatefulWidget {
  final String childName;

  const ParentStudentInfoScreen({super.key, required this.childName});

  @override
  State<ParentStudentInfoScreen> createState() =>
      _ParentStudentInfoScreenState();
}

class _ParentStudentInfoScreenState extends State<ParentStudentInfoScreen> {
  final List<_ClassItem> _classes = [
    _ClassItem(
      subject: 'Mathematics',
      teacher: 'Mr. Ahmed Hassan',
      schedule: 'Sun, Tue, Thu • 8:00 AM',
      room: 'Room 201',
      color: AppColors.primary,
      icon: Icons.calculate_outlined,
    ),
    _ClassItem(
      subject: 'Science',
      teacher: 'Ms. Fatima Ali',
      schedule: 'Mon, Wed • 9:30 AM',
      room: 'Lab 3',
      color: AppColors.secondary,
      icon: Icons.science_outlined,
    ),
    _ClassItem(
      subject: 'English',
      teacher: 'Mrs. Sarah Johnson',
      schedule: 'Sun, Tue, Thu • 10:00 AM',
      room: 'Room 105',
      color: const Color(0xFF7C4DFF),
      icon: Icons.menu_book_outlined,
    ),
    _ClassItem(
      subject: 'Arabic',
      teacher: 'Mr. Khalid Omar',
      schedule: 'Mon, Wed • 11:00 AM',
      room: 'Room 302',
      color: const Color(0xFFFF6D00),
      icon: Icons.translate_outlined,
    ),
    _ClassItem(
      subject: 'Computer Science',
      teacher: 'Dr. Nour Haddad',
      schedule: 'Tue, Thu • 1:00 PM',
      room: 'Lab 1',
      color: const Color(0xFF00BFA5),
      icon: Icons.computer_outlined,
    ),
  ];

  final List<_TeacherInfo> _teachers = [
    _TeacherInfo(name: 'Mr. Ahmed', initials: 'AH', color: AppColors.primary),
    _TeacherInfo(
        name: 'Ms. Fatima', initials: 'FA', color: AppColors.secondary),
    _TeacherInfo(
        name: 'Mrs. Sarah', initials: 'SJ', color: const Color(0xFF7C4DFF)),
    _TeacherInfo(
        name: 'Mr. Khalid', initials: 'KO', color: const Color(0xFFFF6D00)),
    _TeacherInfo(
        name: 'Dr. Nour', initials: 'NH', color: const Color(0xFF00BFA5)),
  ];

  String get _initials {
    final parts = widget.childName.split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}';
    return parts[0][0];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          widget.childName,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileHeader(),
            const SizedBox(height: 24),
            _buildSectionTitle('Current Classes'),
            const SizedBox(height: 12),
            ..._classes.map(_buildClassCard),
            const SizedBox(height: 24),
            _buildSectionTitle('Teachers'),
            const SizedBox(height: 12),
            _buildTeachersRow(),
            const SizedBox(height: 24),
            _buildQuickLinks(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 44,
            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
            child: Text(
              _initials,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            widget.childName,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Grade 10 • Section A',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Student ID: STU-2026-04821',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildClassCard(_ClassItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(item.icon, color: item.color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.subject,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.teacher,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.schedule}  •  ${item.room}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 20),
        ],
      ),
    );
  }

  Widget _buildTeachersRow() {
    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _teachers.length,
        separatorBuilder: (_, _) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final teacher = _teachers[index];
          return Column(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: teacher.color.withValues(alpha: 0.12),
                child: Text(
                  teacher.initials,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: teacher.color,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                teacher.name,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildQuickLinks() {
    return Row(
      children: [
        _buildQuickLinkButton(
          icon: Icons.event_available_outlined,
          label: 'View Attendance',
          color: AppColors.secondary,
        ),
        const SizedBox(width: 10),
        _buildQuickLinkButton(
          icon: Icons.grade_outlined,
          label: 'View Grades',
          color: AppColors.primary,
        ),
        const SizedBox(width: 10),
        _buildQuickLinkButton(
          icon: Icons.feedback_outlined,
          label: 'Send Feedback',
          color: AppColors.accent,
        ),
      ],
    );
  }

  Widget _buildQuickLinkButton({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$label coming soon'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClassItem {
  final String subject;
  final String teacher;
  final String schedule;
  final String room;
  final Color color;
  final IconData icon;

  _ClassItem({
    required this.subject,
    required this.teacher,
    required this.schedule,
    required this.room,
    required this.color,
    required this.icon,
  });
}

class _TeacherInfo {
  final String name;
  final String initials;
  final Color color;

  _TeacherInfo({
    required this.name,
    required this.initials,
    required this.color,
  });
}
