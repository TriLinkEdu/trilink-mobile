import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../models/attendance_model.dart';
import '../repositories/mock_student_attendance_repository.dart';
import '../repositories/student_attendance_repository.dart';

class StudentAttendanceScreen extends StatefulWidget {
  const StudentAttendanceScreen({super.key});

  @override
  State<StudentAttendanceScreen> createState() =>
      _StudentAttendanceScreenState();
}

class _StudentAttendanceScreenState extends State<StudentAttendanceScreen> {
  final StudentAttendanceRepository _repository =
      MockStudentAttendanceRepository();
  bool _isLoading = true;
  String? _error;
  List<AttendanceModel> _records = const [];

  @override
  void initState() {
    super.initState();
    _loadAttendance();
  }

  Future<void> _loadAttendance() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final records = await _repository.fetchAttendanceRecords();
      if (!mounted) return;
      setState(() {
        _records = records;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Unable to load attendance records.';
        _isLoading = false;
      });
    }
  }

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
                  const SizedBox(width: 40),
                  const Expanded(
                    child: Text(
                      'Attendance Record',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      showModalBottomSheet<void>(
                        context: context,
                        builder: (_) => SafeArea(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ListTile(
                                leading: const Icon(Icons.calendar_month_rounded),
                                title: const Text('This Month Summary'),
                                onTap: () {
                                  Navigator.of(context).pop();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Showing this month attendance summary.'),
                                    ),
                                  );
                                },
                              ),
                              ListTile(
                                leading: const Icon(Icons.file_download_rounded),
                                title: const Text('Export Attendance'),
                                onTap: () {
                                  Navigator.of(context).pop();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Attendance export is being prepared.'),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.more_vert,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_error!, style: const TextStyle(color: Colors.red)),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: _loadAttendance,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : _records.isEmpty
                  ? const Center(
                      child: Text(
                        'No attendance records yet.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                    // Overall Attendance Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1A73E8), Color(0xFF4A90E2)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Overall Attendance',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${_overallAttendance.toStringAsFixed(0)}%',
                            style: const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(40),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle_rounded,
                                  size: 14,
                                  color: Colors.greenAccent,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  '12 Day Streak',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Stats row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _AttendanceStat(
                                value: '$presentCount',
                                label: 'PRESENT',
                                bgColor: Colors.white.withAlpha(30),
                              ),
                              _AttendanceStat(
                                value: '$absentCount',
                                label: 'ABSENT',
                                bgColor: Colors.white.withAlpha(30),
                              ),
                              _AttendanceStat(
                                value: '$lateCount',
                                label: 'LATE',
                                bgColor: Colors.white.withAlpha(30),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Subject Breakdown Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Subject Breakdown',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            showDialog<void>(
                              context: context,
                              builder: (dialogContext) => AlertDialog(
                                title: const Text('All Subject Attendance'),
                                content: Text(
                                  _subjectSummaries
                                      .map(
                                        (summary) =>
                                            '${summary.name} ${summary.percentageLabel}',
                                      )
                                      .join('\n'),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(dialogContext).pop(),
                                    child: const Text('Close'),
                                  ),
                                ],
                              ),
                            );
                          },
                          child: const Text(
                            'View All',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Subject rows
                    for (int index = 0; index < _subjectSummaries.length; index++) ...[
                      _SubjectAttendanceRow(
                        icon: _iconForSubject(_subjectSummaries[index].name),
                        iconColor: _colorForSubject(_subjectSummaries[index].name),
                        name: _subjectSummaries[index].name,
                        totalClasses: _subjectSummaries[index].total,
                        percentage: _subjectSummaries[index].percentageLabel,
                        dots: _subjectSummaries[index].dots,
                      ),
                      if (index < _subjectSummaries.length - 1)
                        const SizedBox(height: 16),
                    ],
                    const SizedBox(height: 24),

                    // Legend
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _LegendItem(color: Colors.green, label: 'Present'),
                        const SizedBox(width: 16),
                        _LegendItem(color: Colors.orange, label: 'Late'),
                        const SizedBox(width: 16),
                        _LegendItem(color: Colors.red, label: 'Absent'),
                        const SizedBox(width: 16),
                        _LegendItem(
                          color: Colors.grey.shade300,
                          label: 'Future',
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  int get presentCount => _records.where((record) => record.isPresent).length;

  int get absentCount => _records.length - presentCount;

  int get lateCount => 0;

  double get _overallAttendance {
    if (_records.isEmpty) return 0;
    return (presentCount / _records.length) * 100;
  }

  List<_SubjectAttendanceSummary> get _subjectSummaries {
    final grouped = <String, List<AttendanceModel>>{};
    for (final record in _records) {
      grouped.putIfAbsent(record.subjectId, () => <AttendanceModel>[]).add(record);
    }

    return grouped.entries.map((entry) {
      final records = entry.value..sort((a, b) => a.date.compareTo(b.date));
      final present = records.where((record) => record.isPresent).length;
      final percentage = records.isEmpty ? 0.0 : (present / records.length) * 100;

      return _SubjectAttendanceSummary(
        name: records.first.subjectName,
        total: records.length,
        percentage: percentage,
        percentageLabel: '${percentage.toStringAsFixed(0)}%',
        dots: records
            .map((record) => record.isPresent ? _DotStatus.present : _DotStatus.absent)
            .toList(),
      );
    }).toList()
      ..sort((a, b) => b.percentage.compareTo(a.percentage));
  }

  IconData _iconForSubject(String subjectName) {
    return switch (subjectName.toLowerCase()) {
      'mathematics' => Icons.calculate_rounded,
      'physics' => Icons.science_rounded,
      'english literature' || 'literature' => Icons.auto_stories_rounded,
      _ => Icons.school_rounded,
    };
  }

  Color _colorForSubject(String subjectName) {
    return switch (subjectName.toLowerCase()) {
      'mathematics' => AppColors.primary,
      'physics' => Colors.purple,
      'english literature' || 'literature' => Colors.orange,
      _ => Colors.grey,
    };
  }
}

class _SubjectAttendanceSummary {
  final String name;
  final int total;
  final double percentage;
  final String percentageLabel;
  final List<_DotStatus> dots;

  const _SubjectAttendanceSummary({
    required this.name,
    required this.total,
    required this.percentage,
    required this.percentageLabel,
    required this.dots,
  });
}

enum _DotStatus { present, absent, late, future }

class _AttendanceStat extends StatelessWidget {
  final String value;
  final String label;
  final Color bgColor;

  const _AttendanceStat({
    required this.value,
    required this.label,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _SubjectAttendanceRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String name;
  final int totalClasses;
  final String percentage;
  final List<_DotStatus> dots;

  const _SubjectAttendanceRow({
    required this.icon,
    required this.iconColor,
    required this.name,
    required this.totalClasses,
    required this.percentage,
    required this.dots,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Total Classes: $totalClasses',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                percentage,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Dots
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: dots.map((dot) {
              Color color;
              switch (dot) {
                case _DotStatus.present:
                  color = Colors.green;
                case _DotStatus.absent:
                  color = Colors.red;
                case _DotStatus.late:
                  color = Colors.orange;
                case _DotStatus.future:
                  color = Colors.grey.shade300;
              }
              return Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
      ],
    );
  }
}
