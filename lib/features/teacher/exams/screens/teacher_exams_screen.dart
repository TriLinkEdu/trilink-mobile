import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import 'live_exam_monitoring_screen.dart';
import 'exam_analytics_screen.dart';
import 'create_exam_screen.dart';

class TeacherExamsScreen extends StatefulWidget {
  const TeacherExamsScreen({super.key});

  @override
  State<TeacherExamsScreen> createState() => _TeacherExamsScreenState();
}

class _TeacherExamsScreenState extends State<TeacherExamsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<_ExamItem> _upcomingExams = [
    _ExamItem(
      id: 'exam_1',
      title: 'Calculus II Midterm',
      subject: 'Mathematics',
      date: 'Mar 28, 2026 • 9:00 AM',
      duration: '90 min',
      studentCount: 32,
      status: 'Scheduled',
      statusColor: AppColors.primary,
    ),
    _ExamItem(
      id: 'exam_2',
      title: 'Physics 101 Final',
      subject: 'Physics',
      date: 'Apr 2, 2026 • 10:30 AM',
      duration: '120 min',
      studentCount: 28,
      status: 'Scheduled',
      statusColor: AppColors.primary,
    ),
    _ExamItem(
      id: 'exam_3',
      title: 'Linear Algebra Quiz 4',
      subject: 'Mathematics',
      date: 'Apr 5, 2026 • 2:00 PM',
      duration: '45 min',
      studentCount: 35,
      status: 'Scheduled',
      statusColor: AppColors.primary,
    ),
  ];

  final List<_ExamItem> _completedExams = [
    _ExamItem(
      id: 'exam_4',
      title: 'Physics 101 Midterm',
      subject: 'Physics',
      date: 'Mar 10, 2026',
      duration: '90 min',
      studentCount: 30,
      status: 'Completed',
      statusColor: AppColors.secondary,
    ),
    _ExamItem(
      id: 'exam_5',
      title: 'Calculus II Quiz 3',
      subject: 'Mathematics',
      date: 'Mar 5, 2026',
      duration: '30 min',
      studentCount: 32,
      status: 'Completed',
      statusColor: AppColors.secondary,
    ),
  ];

  final List<_ExamItem> _draftExams = [
    _ExamItem(
      id: 'exam_6',
      title: 'Thermodynamics Test',
      subject: 'Physics',
      date: 'Not scheduled',
      duration: '60 min',
      studentCount: 0,
      status: 'Draft',
      statusColor: Colors.grey,
    ),
    _ExamItem(
      id: 'exam_7',
      title: 'Differential Equations Final',
      subject: 'Mathematics',
      date: 'Not scheduled',
      duration: '120 min',
      studentCount: 0,
      status: 'Draft',
      statusColor: Colors.grey,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Exams & Assessments',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w400,
            fontSize: 14,
          ),
          tabs: [
            Tab(text: 'Upcoming (${_upcomingExams.length})'),
            Tab(text: 'Completed (${_completedExams.length})'),
            Tab(text: 'Drafts (${_draftExams.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildExamList(_upcomingExams, _ExamTab.upcoming),
          _buildExamList(_completedExams, _ExamTab.completed),
          _buildExamList(_draftExams, _ExamTab.drafts),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreateExamScreen()),
        ),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'New Exam',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildExamList(List<_ExamItem> exams, _ExamTab tab) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: exams.length,
      itemBuilder: (context, index) {
        return _ExamCard(
          exam: exams[index],
          tab: tab,
          onTap: () => _onExamTap(exams[index], tab),
          onAction: (action) => _onAction(exams[index], tab, action),
        );
      },
    );
  }

  void _onExamTap(_ExamItem exam, _ExamTab tab) {
    switch (tab) {
      case _ExamTab.upcoming:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LiveExamMonitoringScreen(
              examTitle: exam.title,
              section: exam.subject,
              totalStudents: exam.studentCount,
            ),
          ),
        );
        break;
      case _ExamTab.completed:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ExamAnalyticsScreen(examId: exam.id),
          ),
        );
        break;
      case _ExamTab.drafts:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreateExamScreen()),
        );
        break;
    }
  }

  void _onAction(_ExamItem exam, _ExamTab tab, String action) {
    switch (action) {
      case 'Monitor':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LiveExamMonitoringScreen(
              examTitle: exam.title,
              section: exam.subject,
              totalStudents: exam.studentCount,
            ),
          ),
        );
        break;
      case 'Results':
      case 'Analytics':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ExamAnalyticsScreen(examId: exam.id),
          ),
        );
        break;
      case 'Edit':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreateExamScreen()),
        );
        break;
    }
  }
}

enum _ExamTab { upcoming, completed, drafts }

class _ExamItem {
  final String id;
  final String title;
  final String subject;
  final String date;
  final String duration;
  final int studentCount;
  final String status;
  final Color statusColor;

  _ExamItem({
    required this.id,
    required this.title,
    required this.subject,
    required this.date,
    required this.duration,
    required this.studentCount,
    required this.status,
    required this.statusColor,
  });
}

class _ExamCard extends StatelessWidget {
  final _ExamItem exam;
  final _ExamTab tab;
  final VoidCallback onTap;
  final ValueChanged<String> onAction;

  const _ExamCard({
    required this.exam,
    required this.tab,
    required this.onTap,
    required this.onAction,
  });

  List<_CardAction> get _actions {
    switch (tab) {
      case _ExamTab.upcoming:
        return [
          _CardAction('Edit', Icons.edit_outlined, AppColors.textSecondary),
          _CardAction('Monitor', Icons.monitor_outlined, AppColors.primary),
        ];
      case _ExamTab.completed:
        return [
          _CardAction('Analytics', Icons.bar_chart, AppColors.primary),
          _CardAction('Results', Icons.assignment_outlined, AppColors.secondary),
        ];
      case _ExamTab.drafts:
        return [
          _CardAction('Edit', Icons.edit_outlined, AppColors.primary),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exam.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        exam.subject,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: exam.statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    exam.status,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: exam.statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text(
                  exam.date,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(width: 16),
                Icon(Icons.access_time, size: 14, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text(
                  exam.duration,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                if (exam.studentCount > 0) ...[
                  const SizedBox(width: 16),
                  Icon(Icons.people_outline, size: 14, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Text(
                    '${exam.studentCount} students',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Divider(height: 1, color: Colors.grey.shade200),
            const SizedBox(height: 10),
            Row(
              children: _actions.map((action) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: OutlinedButton.icon(
                    onPressed: () => onAction(action.label),
                    icon: Icon(action.icon, size: 16),
                    label: Text(
                      action.label,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: action.color,
                      side: BorderSide(
                        color: action.color.withValues(alpha: 0.4),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardAction {
  final String label;
  final IconData icon;
  final Color color;

  _CardAction(this.label, this.icon, this.color);
}
