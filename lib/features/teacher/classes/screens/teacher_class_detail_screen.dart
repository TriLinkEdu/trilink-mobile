import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/api_service.dart';
import 'teacher_student_detail_screen.dart';

class TeacherClassDetailScreen extends StatefulWidget {
  final String classId;
  final String subjectId;
  final String subjectName;
  final String className;
  final String classPeriod;

  const TeacherClassDetailScreen({
    super.key,
    required this.classId,
    this.subjectId = '',
    this.subjectName = '',
    required this.className,
    required this.classPeriod,
  });

  @override
  State<TeacherClassDetailScreen> createState() =>
      _TeacherClassDetailScreenState();
}

class _TeacherClassDetailScreenState extends State<TeacherClassDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _students = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadStudents();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadStudents() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await ApiService().getClassStudents(widget.classId);
      if (!mounted) return;
      final students = (response['students'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();
      setState(() {
        _students = students.map((s) => {
              'id': s['studentId'] ?? '',
              'firstName': s['firstName'] ?? '',
              'lastName': s['lastName'] ?? '',
              'email': s['email'] ?? '',
              'phone': s['phone'] ?? '',
              'enrollmentId': s['enrollmentId'] ?? '',
            }).toList();
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
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.className,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
            if (widget.classPeriod.isNotEmpty)
              Text(
                widget.classPeriod,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                ),
              ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey.shade600,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          tabs: const [
            Tab(text: 'Students'),
            Tab(text: 'Schedule'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildStudentsTab(),
          _buildScheduleTab(),
        ],
      ),
    );
  }

  // ─── Students Tab ──────────────────────────────────────────────────────────

  Widget _buildStudentsTab() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              Text('Failed to load students',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700)),
              const SizedBox(height: 8),
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 13, color: Colors.grey.shade500)),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _loadStudents,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_students.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('No students enrolled',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600)),
            const SizedBox(height: 8),
            Text('This class has no enrolled students yet.',
                style: TextStyle(
                    fontSize: 13, color: Colors.grey.shade500)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadStudents,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary banner
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.people,
                        color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_students.length} Student${_students.length == 1 ? '' : 's'}',
                        style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary),
                      ),
                      Text(
                        'Tap a student to view grades & attendance',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'STUDENTS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade500,
                letterSpacing: 0.8,
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _students.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, index) =>
                  _buildStudentCard(_students[index], index),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentCard(Map<String, dynamic> student, int index) {
    final firstName = student['firstName'] as String? ?? '';
    final lastName = student['lastName'] as String? ?? '';
    final name = '$firstName $lastName'.trim();
    final email = student['email'] as String? ?? '';
    final studentId = student['id'] as String? ?? '';

    final initials = name
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0])
        .take(2)
        .join()
        .toUpperCase();

    final colors = [
      AppColors.primary,
      AppColors.secondary,
      const Color(0xFF7C4DFF),
      const Color(0xFFFF6D00),
      const Color(0xFF00BFA5),
    ];
    final color = colors[index % colors.length];

    final canNavigate =
        studentId.isNotEmpty && widget.subjectId.isNotEmpty;

    return GestureDetector(
      onTap: canNavigate
          ? () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TeacherStudentDetailScreen(
                    studentId: studentId,
                    studentName: name.isNotEmpty ? name : 'Student',
                    subjectId: widget.subjectId,
                    subjectName: widget.subjectName.isNotEmpty
                        ? widget.subjectName
                        : widget.className,
                  ),
                ),
              );
            }
          : null,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: CircleAvatar(
            radius: 24,
            backgroundColor: color.withValues(alpha: 0.12),
            child: Text(
              initials.isNotEmpty ? initials : '?',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          title: Text(
            name.isNotEmpty ? name : 'Unnamed Student',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: AppColors.textPrimary,
            ),
          ),
          subtitle: email.isNotEmpty
              ? Text(email,
                  style: TextStyle(
                      fontSize: 13, color: Colors.grey.shade600))
              : null,
          trailing: canNavigate
              ? Icon(Icons.chevron_right,
                  color: Colors.grey.shade400, size: 20)
              : null,
        ),
      ),
    );
  }

  // ─── Schedule Tab (Coming Soon) ────────────────────────────────────────────

  Widget _buildScheduleTab() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.calendar_month_outlined,
                size: 56,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Schedule',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Class schedule view is coming soon.\nYou\'ll be able to see timetable, room assignments, and session history here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.construction_outlined,
                      size: 16, color: AppColors.primary),
                  SizedBox(width: 8),
                  Text(
                    'Coming Soon',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
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
