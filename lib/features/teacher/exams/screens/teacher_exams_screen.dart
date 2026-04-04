import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/api_service.dart';
import 'live_exam_monitoring_screen.dart';
import 'exam_analytics_screen.dart';

class TeacherExamsScreen extends StatefulWidget {
  const TeacherExamsScreen({super.key});

  @override
  State<TeacherExamsScreen> createState() => _TeacherExamsScreenState();
}

class _TeacherExamsScreenState extends State<TeacherExamsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _loading = true;
  String? _error;

  List<_ExamItem> _upcomingExams = [];
  List<_ExamItem> _completedExams = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final exams = await ApiService().getExams();
      final upcoming = <_ExamItem>[];
      final completed = <_ExamItem>[];

      for (final e in exams) {
        final item = _ExamItem.fromJson(e as Map<String, dynamic>);
        switch (item.status.toLowerCase()) {
          case 'completed':
          case 'graded':
            completed.add(item);
            break;
          default:
            upcoming.add(item);
        }
      }

      setState(() {
        _upcomingExams = upcoming;
        _completedExams = completed;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
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
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline,
                          size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text(_error!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade600)),
                      const SizedBox(height: 16),
                      OutlinedButton(
                        onPressed: _loadData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildExamList(_upcomingExams, _ExamTab.upcoming),
                    _buildExamList(_completedExams, _ExamTab.completed),
                  ],
                ),
    );
  }

  Widget _buildExamList(List<_ExamItem> exams, _ExamTab tab) {
    if (exams.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.quiz_outlined, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              'No exams found',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
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
      ),
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
    }
  }
}

enum _ExamTab { upcoming, completed }

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

  factory _ExamItem.fromJson(Map<String, dynamic> json) {
    final status = (json['status'] as String?) ?? 'scheduled';
    Color statusColor;
    switch (status.toLowerCase()) {
      case 'completed':
      case 'graded':
        statusColor = AppColors.secondary;
        break;
      case 'draft':
        statusColor = Colors.grey;
        break;
      default:
        statusColor = AppColors.primary;
    }

    final durationMin = json['durationMinutes'] ?? json['duration'] ?? 0;

    return _ExamItem(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      subject: json['subject']?['name'] ?? json['subjectName'] ?? '',
      date: json['scheduledAt'] ?? json['date'] ?? 'Not scheduled',
      duration: '$durationMin min',
      studentCount: (json['studentCount'] ?? json['totalStudents'] ?? 0) as int,
      status: status[0].toUpperCase() + status.substring(1),
      statusColor: statusColor,
    );
  }
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
          _CardAction('Monitor', Icons.monitor_outlined, AppColors.primary),
        ];
      case _ExamTab.completed:
        return [
          _CardAction('Analytics', Icons.bar_chart, AppColors.primary),
          _CardAction('Results', Icons.assignment_outlined, AppColors.secondary),
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
