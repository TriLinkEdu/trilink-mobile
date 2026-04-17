import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/offline_banner.dart';
import '../../../../core/services/api_service.dart';

class ParentAttendanceScreen extends StatefulWidget {
  final String? studentId;
  final String childName;

  const ParentAttendanceScreen({
    super.key,
    this.studentId,
    this.childName = '',
  });

  @override
  State<ParentAttendanceScreen> createState() => _ParentAttendanceScreenState();
}

class _ParentAttendanceScreenState extends State<ParentAttendanceScreen> {
  bool _loading = true;
  String? _error;

  int _selectedChildIndex = 0;
  List<Map<String, dynamic>> _linkedChildren = [];

  int _selectedSubject = 0;
  DateTime _currentMonth = DateTime.now();
  int _selectedDay = DateTime.now().day;

  List<String> _subjects = ['All Subjects'];
  Map<int, String> _attendanceData = {};
  List<_AttendanceRecord> _recentActivity = [];

  String _attendanceRate = '--';
  String _totalAbsences = '--';
  String _lateArrivals = '--';
  String _termLabel = '';
  String _termDates = '';

  String get _displayedChildName {
    if (_linkedChildren.isEmpty) return widget.childName;
    final c = _linkedChildren[_selectedChildIndex];
    return c['fullName'] as String? ??
        '${c['firstName'] ?? ''} ${c['lastName'] ?? ''}'.trim();
  }

  String get _currentStudentId {
    if (_linkedChildren.isNotEmpty) {
      final c = _linkedChildren[_selectedChildIndex];
      return c['studentId'] as String? ?? c['id'] as String? ?? '';
    }
    return widget.studentId ?? '';
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() { _loading = true; _error = null; });

      // Use new API to get children
      final children = await ApiService().getMyChildren();
      _linkedChildren = children.map<Map<String, dynamic>>((child) {
        final student = child['student'] as Map<String, dynamic>?;
        return {
          'id': child['id'],
          'studentId': student?['id'] ?? child['studentId'],
          'firstName': student?['firstName'] ?? child['firstName'],
          'lastName': student?['lastName'] ?? child['lastName'],
          'fullName': '${student?['firstName'] ?? ''} ${student?['lastName'] ?? ''}'.trim(),
        };
      }).toList();

      if (widget.studentId != null && _linkedChildren.isNotEmpty) {
        final idx = _linkedChildren.indexWhere(
            (c) => c['studentId'] == widget.studentId);
        if (idx >= 0) _selectedChildIndex = idx;
      }

      await _loadAttendance();
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _loadAttendance() async {
    try {
      final report =
          await ApiService().getStudentAttendanceReport(_currentStudentId);
      if (!mounted) return;

      final records = (report['records'] as List<dynamic>?) ?? [];
      final Map<int, String> calData = {};
      for (final r in records) {
        final date = DateTime.tryParse(r['date'] as String? ?? '');
        if (date != null && date.month == _currentMonth.month && date.year == _currentMonth.year) {
          calData[date.day] = r['status'] as String? ?? 'present';
        }
      }

      final subjectList = <String>['All Subjects'];
      final subjectsRaw = report['subjects'] as List<dynamic>?;
      if (subjectsRaw != null) {
        for (final s in subjectsRaw) {
          subjectList.add(s as String);
        }
      }

      final recent = (report['recentActivity'] as List<dynamic>?) ?? [];
      final recentRecords = recent.map<_AttendanceRecord>((a) {
        final status = a['status'] as String? ?? '';
        Color color;
        switch (status.toLowerCase()) {
          case 'absent':
            color = AppColors.error;
          case 'late':
          case 'late arrival':
            color = Colors.orange;
          default:
            color = AppColors.secondary;
        }
        return _AttendanceRecord(
          status: status,
          date: a['date'] as String? ?? '',
          subjects: a['subjects'] as String? ?? '',
          color: color,
        );
      }).toList();

      setState(() {
        _attendanceData = calData;
        _subjects = subjectList;
        _recentActivity = recentRecords;
        _attendanceRate = report['attendanceRate']?.toString() ?? '--';
        _totalAbsences = report['totalAbsences']?.toString() ?? '--';
        _lateArrivals = report['lateArrivals']?.toString() ?? '--';
        _termLabel = report['termLabel'] as String? ?? 'Term Overview';
        _termDates = report['termDates'] as String? ?? '';
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Attendance Record',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
        centerTitle: false,
      ),
      body: OfflineBanner(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!,
                            style: const TextStyle(color: AppColors.error)),
                        const SizedBox(height: 12),
                        ElevatedButton(
                            onPressed: _loadData,
                            child: const Text('Retry')),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSubjectFilters(),
                        const SizedBox(height: 16),
                        _buildCalendarSection(),
                        const SizedBox(height: 12),
                        _buildLegend(),
                        const SizedBox(height: 24),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildTermOverview(),
                              const SizedBox(height: 24),
                              _buildRecentActivitySection(),
                              const SizedBox(height: 16),
                              _buildViewFullHistory(),
                              const SizedBox(height: 32),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildSubjectFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(_subjects.length, (index) {
            final isSelected = _selectedSubject == index;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => setState(() => _selectedSubject = index),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color:
                        isSelected ? AppColors.textPrimary : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.textPrimary
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: Text(
                    _subjects[index],
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isSelected
                          ? Colors.white
                          : Colors.grey.shade700,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildCalendarSection() {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    final daysOfWeek = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    final firstDay = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final daysInMonth = DateTime(
      _currentMonth.year,
      _currentMonth.month + 1,
      0,
    ).day;
    final startWeekday = firstDay.weekday % 7;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    _currentMonth = DateTime(
                      _currentMonth.year,
                      _currentMonth.month - 1,
                    );
                  });
                  _loadAttendance();
                },
                child: const Icon(Icons.chevron_left),
              ),
              const SizedBox(width: 16),
              Text(
                '${months[_currentMonth.month - 1]} ${_currentMonth.year}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _currentMonth = DateTime(
                      _currentMonth.year,
                      _currentMonth.month + 1,
                    );
                  });
                  _loadAttendance();
                },
                child: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: daysOfWeek
                .map(
                  (d) => Expanded(
                    child: Center(
                      child: Text(
                        d,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),
          ...List.generate(
            ((startWeekday + daysInMonth) / 7).ceil(),
            (week) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: List.generate(7, (day) {
                    final dayNum = week * 7 + day - startWeekday + 1;
                    if (dayNum < 1 || dayNum > daysInMonth) {
                      return const Expanded(child: SizedBox(height: 40));
                    }
                    final status = _attendanceData[dayNum];
                    return _buildDayCell(dayNum, status);
                  }),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDayCell(int day, String? status) {
    final isSelected = day == _selectedDay;
    Color? dotColor;
    if (status == 'present') dotColor = AppColors.secondary;
    if (status == 'late') dotColor = Colors.orange;
    if (status == 'absent') dotColor = AppColors.error;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedDay = day),
        child: Container(
          height: 40,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$day',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w400,
                  color: isSelected
                      ? Colors.white
                      : (status == 'absent'
                          ? AppColors.error
                          : AppColors.textPrimary),
                ),
              ),
              if (dotColor != null && !isSelected)
                Container(
                  width: 4,
                  height: 4,
                  margin: const EdgeInsets.only(top: 2),
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _LegendDot(color: AppColors.secondary, label: 'Present'),
          const SizedBox(width: 20),
          _LegendDot(color: Colors.orange, label: 'Late'),
          const SizedBox(width: 20),
          _LegendDot(color: AppColors.error, label: 'Absent'),
        ],
      ),
    );
  }

  Widget _buildTermOverview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _termLabel.isEmpty ? 'Term Overview' : _termLabel,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            if (_termDates.isNotEmpty)
              Text(
                _termDates,
                style:
                    TextStyle(fontSize: 13, color: Colors.grey.shade500),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _TermStat(
                value: _attendanceRate.contains('%')
                    ? _attendanceRate
                    : '$_attendanceRate%',
                label: 'Attendance\nRate',
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _TermStat(
                value: _totalAbsences,
                label: 'Total\nAbsences',
                color: AppColors.error,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _TermStat(
                value: _lateArrivals,
                label: 'Late\nArrivals',
                color: Colors.orange,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentActivitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Activity',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        if (_recentActivity.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text('No recent activity',
                  style: TextStyle(color: Colors.grey.shade500)),
            ),
          ),
        ..._recentActivity.map((r) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          r.status,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: r.color,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          r.date,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    r.subjects,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildViewFullHistory() {
    return Center(
      child: TextButton(
        onPressed: () {},
        child: const Text(
          'View Full History',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }
}

class _TermStat extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _TermStat({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
        ),
      ],
    );
  }
}

class _AttendanceRecord {
  final String status;
  final String date;
  final String subjects;
  final Color color;

  _AttendanceRecord({
    required this.status,
    required this.date,
    required this.subjects,
    required this.color,
  });
}
