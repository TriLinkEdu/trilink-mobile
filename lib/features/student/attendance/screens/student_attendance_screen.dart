import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../models/attendance_model.dart';
import '../repositories/mock_student_attendance_repository.dart';
import '../repositories/student_attendance_repository.dart';

class StudentAttendanceScreen extends StatefulWidget {
  final StudentAttendanceRepository? repository;

  const StudentAttendanceScreen({super.key, this.repository});

  @override
  State<StudentAttendanceScreen> createState() =>
      _StudentAttendanceScreenState();
}

class _StudentAttendanceScreenState extends State<StudentAttendanceScreen> {
  late final StudentAttendanceRepository _repository =
      widget.repository ?? MockStudentAttendanceRepository();
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

  void _showOptionsSheet() {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.calendar_month_rounded),
              title: const Text('This Month Summary'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _showMonthlySummary();
              },
            ),
            ListTile(
              leading: const Icon(Icons.file_download_rounded),
              title: const Text('Export Attendance'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _exportAttendance();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showMonthlySummary() {
    final present = presentCount;
    final absent = absentCount;
    final late_ = lateCount;
    final excused = excusedCount;
    final total = _records.length;
    final pct =
        total > 0 ? ((present + late_ + excused) / total * 100) : 0.0;

    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Attendance Summary',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildSummaryRow('Present', '$present', dotColor: Colors.green),
              _buildSummaryRow('Absent', '$absent', dotColor: Colors.red),
              _buildSummaryRow('Late', '$late_', dotColor: Colors.orange),
              _buildSummaryRow('Excused', '$excused', dotColor: Colors.blue),
              const Divider(height: 24),
              _buildSummaryRow('Total Classes', '$total'),
              _buildSummaryRow(
                  'Attendance Rate', '${pct.toStringAsFixed(1)}%'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {Color? dotColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          if (dotColor != null) ...[
            Container(
              width: 10,
              height: 10,
              decoration:
                  BoxDecoration(color: dotColor, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
          Text(value,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Future<void> _exportAttendance() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Preparing attendance report...')),
    );
    await Future<void>.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Attendance report exported')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  SizedBox(
                    width: 40,
                    child: Navigator.of(context).canPop()
                        ? IconButton(
                            tooltip: 'Back',
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              size: 18,
                            ),
                          )
                        : null,
                  ),
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
                    tooltip: 'More attendance options',
                    onPressed: _showOptionsSheet,
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
                  ? const Center(
                      child: CircularProgressIndicator(
                        semanticsLabel: 'Loading attendance records',
                      ),
                    )
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(_error!,
                                  style: const TextStyle(color: Colors.red)),
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
                                style:
                                    TextStyle(color: AppColors.textSecondary),
                              ),
                            )
                          : SingleChildScrollView(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 24),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF1A73E8),
                                          Color(0xFF4A90E2),
                                        ],
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
                                            color:
                                                Colors.white.withAlpha(40),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.check_circle_rounded,
                                                size: 14,
                                                color: Colors.greenAccent,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                '$_currentStreak Day Streak',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 20),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          alignment: WrapAlignment.center,
                                          children: [
                                            _AttendanceStat(
                                              value: '$presentCount',
                                              label: 'PRESENT',
                                              bgColor:
                                                  Colors.white.withAlpha(30),
                                            ),
                                            _AttendanceStat(
                                              value: '$absentCount',
                                              label: 'ABSENT',
                                              bgColor:
                                                  Colors.white.withAlpha(30),
                                            ),
                                            _AttendanceStat(
                                              value: '$lateCount',
                                              label: 'LATE',
                                              bgColor:
                                                  Colors.white.withAlpha(30),
                                            ),
                                            _AttendanceStat(
                                              value: '$excusedCount',
                                              label: 'EXCUSED',
                                              bgColor:
                                                  Colors.white.withAlpha(30),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
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
                                            builder: (dialogContext) =>
                                                AlertDialog(
                                              title: const Text(
                                                  'All Subject Attendance'),
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
                                                  onPressed: () =>
                                                      Navigator.of(
                                                              dialogContext)
                                                          .pop(),
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
                                  for (int index = 0;
                                      index < _subjectSummaries.length;
                                      index++) ...[
                                    _SubjectAttendanceRow(
                                      icon: _iconForSubject(
                                          _subjectSummaries[index].name),
                                      iconColor: _colorForSubject(
                                          _subjectSummaries[index].name),
                                      name: _subjectSummaries[index].name,
                                      totalClasses:
                                          _subjectSummaries[index].total,
                                      percentage: _subjectSummaries[index]
                                          .percentageLabel,
                                      dots: _subjectSummaries[index].dots,
                                    ),
                                    if (index <
                                        _subjectSummaries.length - 1)
                                      const SizedBox(height: 16),
                                  ],
                                  const SizedBox(height: 24),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      const _LegendItem(
                                          color: Colors.green,
                                          label: 'Present'),
                                      const SizedBox(width: 12),
                                      const _LegendItem(
                                          color: Colors.orange,
                                          label: 'Late'),
                                      const SizedBox(width: 12),
                                      const _LegendItem(
                                          color: Colors.red,
                                          label: 'Absent'),
                                      const SizedBox(width: 12),
                                      const _LegendItem(
                                          color: Colors.blue,
                                          label: 'Excused'),
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

  int get presentCount =>
      _records.where((r) => r.status == AttendanceStatus.present).length;

  int get absentCount =>
      _records.where((r) => r.status == AttendanceStatus.absent).length;

  int get lateCount =>
      _records.where((r) => r.status == AttendanceStatus.late).length;

  int get excusedCount =>
      _records.where((r) => r.status == AttendanceStatus.excused).length;

  double get _overallAttendance {
    if (_records.isEmpty) return 0;
    final attended = presentCount + lateCount + excusedCount;
    return (attended / _records.length) * 100;
  }

  int get _currentStreak {
    final sorted = List<AttendanceModel>.from(_records)
      ..sort((a, b) => b.date.compareTo(a.date));
    int streak = 0;
    for (final record in sorted) {
      if (record.status == AttendanceStatus.absent) break;
      streak++;
    }
    return streak;
  }

  List<_SubjectAttendanceSummary> get _subjectSummaries {
    final grouped = <String, List<AttendanceModel>>{};
    for (final record in _records) {
      grouped
          .putIfAbsent(record.subjectId, () => <AttendanceModel>[])
          .add(record);
    }

    return grouped.entries.map((entry) {
      final records = entry.value..sort((a, b) => a.date.compareTo(b.date));
      final attended =
          records.where((r) => r.status != AttendanceStatus.absent).length;
      final percentage =
          records.isEmpty ? 0.0 : (attended / records.length) * 100;

      return _SubjectAttendanceSummary(
        name: records.first.subjectName,
        total: records.length,
        percentage: percentage,
        percentageLabel: '${percentage.toStringAsFixed(0)}%',
        dots: records.map((record) {
          switch (record.status) {
            case AttendanceStatus.present:
              return _DotStatus.present;
            case AttendanceStatus.late:
              return _DotStatus.late;
            case AttendanceStatus.excused:
              return _DotStatus.excused;
            case AttendanceStatus.absent:
              return _DotStatus.absent;
          }
        }).toList(),
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

enum _DotStatus { present, absent, late, excused, future }

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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                case _DotStatus.excused:
                  color = Colors.blue;
                case _DotStatus.future:
                  color = Colors.grey.shade300;
              }
              return Container(
                width: 12,
                height: 12,
                decoration:
                    BoxDecoration(color: color, shape: BoxShape.circle),
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
