import 'package:flutter/material.dart';
import 'dart:async';
import '../../../../core/theme/app_colors.dart';

class LiveExamMonitoringScreen extends StatefulWidget {
  final String examTitle;
  final String section;
  final int totalStudents;

  const LiveExamMonitoringScreen({
    super.key,
    this.examTitle = 'Physics 101 Mid-Term',
    this.section = 'Section B',
    this.totalStudents = 30,
  });

  @override
  State<LiveExamMonitoringScreen> createState() =>
      _LiveExamMonitoringScreenState();
}

class _LiveExamMonitoringScreenState extends State<LiveExamMonitoringScreen> {
  int _selectedFilter = 0;
  late Timer _timer;
  int _remainingSeconds = 2712; // 00:45:12

  final List<String> _filters = ['All', 'Flagged', 'Idle', 'Subm'];
  final List<int> _filterCounts = [30, 2, 3, 4];

  final List<_ExamStudent> _students = [
    _ExamStudent(
      name: 'Mike Ross',
      id: 'ID: 992831',
      avatarUrl: 'https://i.pravatar.cc/100?img=33',
      status: StudentExamStatus.flagged,
      statusLabel: 'Flagged',
      badge: 'IP MISMATCH',
      badgeColor: AppColors.error,
      progress: 2,
      totalQuestions: 10,
      actions: ['View Logs', 'Force Submit'],
    ),
    _ExamStudent(
      name: 'Jessica Pearson',
      id: 'ID: 883921',
      avatarUrl: 'https://i.pravatar.cc/100?img=45',
      status: StudentExamStatus.idle,
      statusLabel: 'Away',
      badge: 'IDLE 5M',
      badgeColor: Colors.orange,
      progress: 5,
      totalQuestions: 10,
      actions: ['Message', 'Force Submit'],
    ),
    _ExamStudent(
      name: 'Sarah Jenkins',
      id: 'ID: 112049',
      avatarUrl: 'https://i.pravatar.cc/100?img=9',
      status: StudentExamStatus.active,
      statusLabel: 'Active',
      progress: 8,
      totalQuestions: 10,
      actions: [],
    ),
    _ExamStudent(
      name: 'James Liu',
      id: 'ID: 442910',
      avatarUrl: '',
      status: StudentExamStatus.active,
      statusLabel: 'Active',
      progress: 6,
      totalQuestions: 10,
      actions: [],
    ),
    _ExamStudent(
      name: 'Robert Zane',
      id: 'ID: 552100',
      avatarUrl: 'https://i.pravatar.cc/100?img=51',
      status: StudentExamStatus.submitted,
      statusLabel: 'Finished at 10:45 AM',
      progress: 10,
      totalQuestions: 10,
      actions: [],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String get _formattedTime {
    final h = (_remainingSeconds ~/ 3600).toString().padLeft(2, '0');
    final m = ((_remainingSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return '$h  $m  $s';
  }

  List<_ExamStudent> get _filteredStudents {
    if (_selectedFilter == 0) return _students;
    switch (_selectedFilter) {
      case 1:
        return _students
            .where((s) => s.status == StudentExamStatus.flagged)
            .toList();
      case 2:
        return _students
            .where((s) => s.status == StudentExamStatus.idle)
            .toList();
      case 3:
        return _students
            .where((s) => s.status == StudentExamStatus.submitted)
            .toList();
      default:
        return _students;
    }
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
        title: Column(
          children: [
            Text(
              widget.examTitle,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
            Text(
              '${widget.section} • ${widget.totalStudents} Students',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: AppColors.textPrimary),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          _buildTimerSection(),
          _buildFilterChips(),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filteredStudents.length,
              itemBuilder: (context, index) {
                return _StudentExamCard(student: _filteredStudents[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TIME REMAINING',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade500,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _formattedTime,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  letterSpacing: 4,
                ),
              ),
            ],
          ),
          TextButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('End Exam'),
                  content: const Text(
                    'Are you sure you want to end the exam for all students?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'End Exam',
                        style: TextStyle(color: AppColors.error),
                      ),
                    ),
                  ],
                ),
              );
            },
            child: const Text(
              'End Exam',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: List.generate(_filters.length, (index) {
          final isSelected = _selectedFilter == index;
          Color chipColor;
          switch (index) {
            case 1:
              chipColor = AppColors.error;
              break;
            case 2:
              chipColor = Colors.orange;
              break;
            case 3:
              chipColor = AppColors.secondary;
              break;
            default:
              chipColor = AppColors.primary;
          }
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedFilter = index),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? chipColor.withValues(alpha: 0.12)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? chipColor : Colors.grey.shade300,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (index > 0)
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(
                          color: chipColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    Text(
                      '${_filters[index]} ${_filterCounts[index]}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected ? chipColor : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

enum StudentExamStatus { active, flagged, idle, submitted }

class _ExamStudent {
  final String name;
  final String id;
  final String avatarUrl;
  final StudentExamStatus status;
  final String statusLabel;
  final String? badge;
  final Color? badgeColor;
  final int progress;
  final int totalQuestions;
  final List<String> actions;

  _ExamStudent({
    required this.name,
    required this.id,
    required this.avatarUrl,
    required this.status,
    required this.statusLabel,
    this.badge,
    this.badgeColor,
    required this.progress,
    required this.totalQuestions,
    required this.actions,
  });
}

class _StudentExamCard extends StatelessWidget {
  final _ExamStudent student;
  const _StudentExamCard({required this.student});

  @override
  Widget build(BuildContext context) {
    final isSubmitted = student.status == StudentExamStatus.submitted;
    final progressPercent = student.progress / student.totalQuestions;

    return Container(
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
        children: [
          Row(
            children: [
              _buildAvatar(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          student.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (student.badge != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: student.badgeColor
                                      ?.withValues(alpha: 0.12) ??
                                  Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: student.badgeColor ?? Colors.grey,
                                width: 0.5,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (student.status ==
                                    StudentExamStatus.flagged)
                                  Icon(
                                    Icons.warning_amber,
                                    size: 10,
                                    color: student.badgeColor,
                                  ),
                                const SizedBox(width: 2),
                                Text(
                                  student.badge!,
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: student.badgeColor,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          student.id,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '• ${student.statusLabel}',
                          style: TextStyle(
                            fontSize: 13,
                            color: _statusColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (isSubmitted)
                Icon(
                  Icons.check_circle,
                  color: AppColors.secondary,
                  size: 22,
                )
              else
                Icon(
                  Icons.access_time,
                  color: Colors.grey.shade400,
                  size: 22,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'Progress',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progressPercent,
                    backgroundColor: Colors.grey.shade200,
                    color: _progressColor,
                    minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${student.progress}/${student.totalQuestions} Answered',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
          if (student.actions.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: student.actions.map((action) {
                final isForceSubmit = action == 'Force Submit';
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      foregroundColor:
                          isForceSubmit ? AppColors.error : AppColors.primary,
                      side: BorderSide(
                        color: isForceSubmit
                            ? AppColors.error.withValues(alpha: 0.5)
                            : AppColors.primary.withValues(alpha: 0.5),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      action,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
          if (isSubmitted) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Completed',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade500,
                  ),
                ),
                const Text(
                  'Submitted',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    if (student.avatarUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 24,
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
      radius: 24,
      backgroundColor: AppColors.primary.withValues(alpha: 0.15),
      child: Text(
        initials,
        style: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  Color get _statusColor {
    switch (student.status) {
      case StudentExamStatus.active:
        return AppColors.secondary;
      case StudentExamStatus.flagged:
        return AppColors.error;
      case StudentExamStatus.idle:
        return Colors.orange;
      case StudentExamStatus.submitted:
        return AppColors.secondary;
    }
  }

  Color get _progressColor {
    switch (student.status) {
      case StudentExamStatus.active:
        return AppColors.primary;
      case StudentExamStatus.flagged:
        return AppColors.primary;
      case StudentExamStatus.idle:
        return Colors.orange;
      case StudentExamStatus.submitted:
        return AppColors.secondary;
    }
  }
}
