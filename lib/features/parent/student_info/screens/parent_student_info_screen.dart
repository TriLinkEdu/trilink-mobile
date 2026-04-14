import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/api_service.dart';
import '../../attendance/screens/parent_attendance_screen.dart';
import '../screens/parent_results_screen.dart';
import '../../feedback/screens/parent_feedback_screen.dart';

class ParentStudentInfoScreen extends StatefulWidget {
  final String childName;
  final String? studentUserId;

  const ParentStudentInfoScreen({
    super.key,
    required this.childName,
    this.studentUserId,
  });

  @override
  State<ParentStudentInfoScreen> createState() =>
      _ParentStudentInfoScreenState();
}

class _ParentStudentInfoScreenState extends State<ParentStudentInfoScreen> {
  bool _loading = true;
  String? _error;

  String _studentName = '';
  String _gradeSection = '';
  String _studentIdLabel = '';
  List<_ClassItem> _classes = [];
  List<_TeacherInfo> _teachers = [];

  String get _initials {
    final parts = _studentName.split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}';
    return parts.isNotEmpty && parts[0].isNotEmpty ? parts[0][0] : '?';
  }

  @override
  void initState() {
    super.initState();
    _studentName = widget.childName;
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });

      String userId = widget.studentUserId ?? '';
      if (userId.isEmpty) {
        // Get first child from myChildren
        final children = await ApiService().getMyChildren();
        if (children.isNotEmpty) {
          final student = children[0]['student'] as Map<String, dynamic>?;
          userId = student?['id'] as String? ?? children[0]['studentId'] as String? ?? '';
        }
      }

      if (userId.isEmpty) {
        if (!mounted) return;
        setState(() {
          _loading = false;
        });
        return;
      }

      // Load enrollments (classes) for the student
      final enrollments = await ApiService().getChildEnrollments(userId);
      
      if (!mounted) return;

      final colors = [
        AppColors.primary,
        AppColors.secondary,
        const Color(0xFF7C4DFF),
        const Color(0xFFFF6D00),
        const Color(0xFF00BFA5),
      ];
      final icons = [
        Icons.calculate_outlined,
        Icons.science_outlined,
        Icons.menu_book_outlined,
        Icons.translate_outlined,
        Icons.computer_outlined,
      ];

      setState(() {
        _studentName = widget.childName;
        
        // Extract grade and section from first enrollment
        if (enrollments.isNotEmpty) {
          final first = enrollments[0] as Map<String, dynamic>;
          final grade = first['grade'] as String? ?? '';
          final section = first['section'] as String? ?? '';
          _gradeSection = section.isNotEmpty ? '$grade • Section $section' : grade;
        }

        _classes = enrollments.asMap().entries.map((entry) {
          final e = entry.value as Map<String, dynamic>;
          final subject = e['subject'] as Map<String, dynamic>?;
          final teacher = e['teacher'] as Map<String, dynamic>?;
          
          return _ClassItem(
            subject: subject?['name'] as String? ?? '',
            teacher: '${teacher?['firstName'] ?? ''} ${teacher?['lastName'] ?? ''}'.trim(),
            schedule: e['schedule'] as String? ?? '',
            room: e['room'] as String? ?? '',
            color: colors[entry.key % colors.length],
            icon: icons[entry.key % icons.length],
          );
        }).toList();

        // Extract unique teachers
        final teacherSet = <String, _TeacherInfo>{};
        for (var i = 0; i < enrollments.length; i++) {
          final e = enrollments[i] as Map<String, dynamic>;
          final teacher = e['teacher'] as Map<String, dynamic>?;
          if (teacher != null) {
            final firstName = teacher['firstName'] as String? ?? '';
            final lastName = teacher['lastName'] as String? ?? '';
            final fullName = '$firstName $lastName'.trim();
            final initials = '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}'.toUpperCase();
            
            if (!teacherSet.containsKey(fullName)) {
              teacherSet[fullName] = _TeacherInfo(
                name: fullName,
                initials: initials,
                color: colors[teacherSet.length % colors.length],
              );
            }
          }
        }
        _teachers = teacherSet.values.toList();

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        title: Text(
          _studentName,
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_error!, style: const TextStyle(color: AppColors.error)),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _loadData,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileHeader(),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Current Classes'),
                  const SizedBox(height: 12),
                  if (_classes.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: Text(
                          'No classes found',
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      ),
                    ),
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
            _studentName,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _gradeSection,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          if (_studentIdLabel.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Student ID: $_studentIdLabel',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            ),
          ],
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
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.schedule}  •  ${item.room}',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
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
    if (_teachers.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Text(
            'No teachers found',
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ),
      );
    }
    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _teachers.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
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
    final studentId = widget.studentUserId ?? '';
    return Row(
      children: [
        _buildQuickLinkButton(
          icon: Icons.event_available_outlined,
          label: 'View Attendance',
          color: AppColors.secondary,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ParentAttendanceScreen(
                studentId: studentId,
                childName: _studentName,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        _buildQuickLinkButton(
          icon: Icons.grade_outlined,
          label: 'View Grades',
          color: AppColors.primary,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ParentResultsScreen()),
          ),
        ),
        const SizedBox(width: 10),
        _buildQuickLinkButton(
          icon: Icons.feedback_outlined,
          label: 'Send Feedback',
          color: AppColors.accent,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ParentFeedbackScreen()),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickLinkButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
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
