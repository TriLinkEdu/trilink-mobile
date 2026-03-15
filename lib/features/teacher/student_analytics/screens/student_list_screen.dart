import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import 'student_analytics_screen.dart';

class StudentListScreen extends StatefulWidget {
  const StudentListScreen({super.key});

  @override
  State<StudentListScreen> createState() => _StudentListScreenState();
}

class _StudentListScreenState extends State<StudentListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<_StudentInfo> _students = [
    _StudentInfo(
      id: '99281',
      name: 'Sara Mekonnen',
      grade: '10th Grade',
      gpa: '3.2',
      avatarUrl: 'https://i.pravatar.cc/100?img=47',
      status: 'Honor Roll',
    ),
    _StudentInfo(
      id: '99282',
      name: 'Marcus Johnson',
      grade: '10th Grade',
      gpa: '3.8',
      avatarUrl: 'https://i.pravatar.cc/100?img=12',
      status: 'Honor Roll',
    ),
    _StudentInfo(
      id: '99283',
      name: 'Emily Chen',
      grade: '10th Grade',
      gpa: '2.9',
      avatarUrl: 'https://i.pravatar.cc/100?img=20',
      status: 'At Risk',
    ),
    _StudentInfo(
      id: '99284',
      name: 'David Brown',
      grade: '10th Grade',
      gpa: '3.5',
      avatarUrl: 'https://i.pravatar.cc/100?img=15',
      status: 'Good Standing',
    ),
    _StudentInfo(
      id: '99285',
      name: 'Alex Lee',
      grade: '10th Grade',
      gpa: '3.1',
      avatarUrl: '',
      status: 'Good Standing',
    ),
    _StudentInfo(
      id: '99286',
      name: 'Jane Doe',
      grade: '10th Grade',
      gpa: '3.6',
      avatarUrl: 'https://i.pravatar.cc/100?img=5',
      status: 'Honor Roll',
    ),
  ];

  List<_StudentInfo> get _filteredStudents {
    if (_searchQuery.isEmpty) return _students;
    return _students
        .where(
          (s) => s.name.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Students',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: 'Search students...',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: Colors.grey.shade500,
                    size: 20,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _filteredStudents.length,
              separatorBuilder: (context, index) => Divider(
                color: Colors.grey.shade200,
                height: 1,
              ),
              itemBuilder: (context, index) {
                final student = _filteredStudents[index];
                return _StudentListTile(
                  student: student,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StudentAnalyticsScreen(
                          studentId: student.id,
                          studentName: student.name,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StudentInfo {
  final String id;
  final String name;
  final String grade;
  final String gpa;
  final String avatarUrl;
  final String status;

  _StudentInfo({
    required this.id,
    required this.name,
    required this.grade,
    required this.gpa,
    required this.avatarUrl,
    required this.status,
  });
}

class _StudentListTile extends StatelessWidget {
  final _StudentInfo student;
  final VoidCallback onTap;

  const _StudentListTile({required this.student, required this.onTap});

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    switch (student.status) {
      case 'Honor Roll':
        statusColor = AppColors.primary;
        break;
      case 'At Risk':
        statusColor = AppColors.error;
        break;
      default:
        statusColor = AppColors.secondary;
    }

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            _buildAvatar(),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${student.grade} • GPA: ${student.gpa}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                student.status,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    if (student.avatarUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 22,
        backgroundImage: NetworkImage(student.avatarUrl),
      );
    }
    final initials = student.name
        .split(' ')
        .map((w) => w[0])
        .take(2)
        .join()
        .toUpperCase();
    return CircleAvatar(
      radius: 22,
      backgroundColor: AppColors.primary.withValues(alpha: 0.15),
      child: Text(
        initials,
        style: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
