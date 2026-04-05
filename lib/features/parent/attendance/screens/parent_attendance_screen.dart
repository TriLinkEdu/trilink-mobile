import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
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

  DateTime _currentMonth = DateTime.now();

  // date string → status  e.g. '2026-04-15' → 'present'
  Map<String, String> _calendarData = {};

  // summary counts
  int _totalPresent = 0;
  int _totalLate = 0;
  int _totalAbsent = 0;
  int _totalExcused = 0;
  int _totalMarks = 0;

  // recent marks sorted newest-first
  List<Map<String, dynamic>> _recentMarks = [];

  String get _currentStudentId => widget.studentId ?? '';

  double get _attendanceRate {
    if (_totalMarks == 0) return 0;
    return (_totalPresent + _totalLate) / _totalMarks * 100;
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _loading = true; _error = null; });
    try {
      String sid = _currentStudentId;
      if (sid.isEmpty) {
        final children = await ApiService().getMyChildren();
        if (children.isNotEmpty) {
          final s = children[0]['student'] as Map<String, dynamic>?;
          sid = s?['id'] as String? ?? children[0]['studentId'] as String? ?? '';
        }
      }
      if (sid.isEmpty) {
        setState(() => _loading = false);
        return;
      }

      // GET /reports/attendance/student/:studentId
      // returns { studentId, marks: [{status, sessionDate, classOfferingId}] }
      final report = await ApiService().getStudentAttendanceReport(sid);
      if (!mounted) return;

      final marks = (report['marks'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();

      // Build calendar map and counts
      final Map<String, String> cal = {};
      int present = 0, late = 0, absent = 0, excused = 0;

      for (final m in marks) {
        final date = m['sessionDate'] as String? ?? '';
        final status = (m['status'] as String? ?? '').toLowerCase();
        if (date.isNotEmpty) cal[date] = status;
        switch (status) {
          case 'present': present++; break;
          case 'late': late++; break;
          case 'absent': absent++; break;
          case 'excused': excused++; break;
        }
      }

      // Sort newest-first for recent list
      final sorted = List<Map<String, dynamic>>.from(marks)
        ..sort((a, b) {
          final da = a['sessionDate'] as String? ?? '';
          final db = b['sessionDate'] as String? ?? '';
          return db.compareTo(da);
        });

      setState(() {
        _calendarData = cal;
        _totalPresent = present;
        _totalLate = late;
        _totalAbsent = absent;
        _totalExcused = excused;
        _totalMarks = present + late + absent + excused;
        _recentMarks = sorted.take(10).toList();
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
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.childName.isNotEmpty
              ? '${widget.childName}\'s Attendance'
              : 'Attendance Record',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSummaryCards(),
                        const SizedBox(height: 20),
                        _buildCalendarCard(),
                        const SizedBox(height: 20),
                        _buildRecentActivity(),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(_error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh, size: 16),
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

  Widget _buildSummaryCards() {
    final rate = _attendanceRate;
    final rateColor = rate >= 80
        ? AppColors.success
        : rate >= 60
            ? AppColors.warning
            : AppColors.error;

    return Column(
      children: [
        // Big attendance rate card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [rateColor, rateColor.withValues(alpha: 0.75)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: rateColor.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4)),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Attendance Rate',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${rate.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 38,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$_totalMarks total sessions recorded',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.event_available_outlined,
                    color: Colors.white, size: 28),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // 4 stat chips
        Row(
          children: [
            _buildStatChip('Present', _totalPresent, AppColors.success),
            const SizedBox(width: 8),
            _buildStatChip('Late', _totalLate, AppColors.warning),
            const SizedBox(width: 8),
            _buildStatChip('Absent', _totalAbsent, AppColors.error),
            const SizedBox(width: 8),
            _buildStatChip('Excused', _totalExcused, Colors.blueGrey),
          ],
        ),
      ],
    );
  }

  Widget _buildStatChip(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 4,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarCard() {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    final daysOfWeek = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    final firstDay =
        DateTime(_currentMonth.year, _currentMonth.month, 1);
    final daysInMonth =
        DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    final startWeekday = firstDay.weekday % 7;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          // Month nav
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, size: 22),
                onPressed: () => setState(() {
                  _currentMonth = DateTime(
                      _currentMonth.year, _currentMonth.month - 1);
                }),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 12),
              Text(
                '${months[_currentMonth.month - 1]} ${_currentMonth.year}',
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(Icons.chevron_right, size: 22),
                onPressed: () => setState(() {
                  _currentMonth = DateTime(
                      _currentMonth.year, _currentMonth.month + 1);
                }),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Day headers
          Row(
            children: daysOfWeek
                .map((d) => Expanded(
                      child: Center(
                        child: Text(d,
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade500)),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),
          // Day cells
          ...List.generate(
            ((startWeekday + daysInMonth) / 7).ceil(),
            (week) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: List.generate(7, (day) {
                  final dayNum = week * 7 + day - startWeekday + 1;
                  if (dayNum < 1 || dayNum > daysInMonth) {
                    return const Expanded(child: SizedBox(height: 36));
                  }
                  final dateStr =
                      '${_currentMonth.year}-${_currentMonth.month.toString().padLeft(2, '0')}-${dayNum.toString().padLeft(2, '0')}';
                  final status = _calendarData[dateStr];
                  return _buildDayCell(dayNum, status);
                }),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendDot(AppColors.success, 'Present'),
              const SizedBox(width: 16),
              _buildLegendDot(AppColors.warning, 'Late'),
              const SizedBox(width: 16),
              _buildLegendDot(AppColors.error, 'Absent'),
              const SizedBox(width: 16),
              _buildLegendDot(Colors.blueGrey, 'Excused'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDayCell(int day, String? status) {
    Color? bg;
    Color textColor = AppColors.textPrimary;
    switch (status) {
      case 'present':
        bg = AppColors.success.withValues(alpha: 0.15);
        textColor = AppColors.success;
        break;
      case 'late':
        bg = AppColors.warning.withValues(alpha: 0.15);
        textColor = AppColors.warning;
        break;
      case 'absent':
        bg = AppColors.error.withValues(alpha: 0.15);
        textColor = AppColors.error;
        break;
      case 'excused':
        bg = Colors.blueGrey.withValues(alpha: 0.15);
        textColor = Colors.blueGrey;
        break;
    }

    return Expanded(
      child: Container(
        height: 36,
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            '$day',
            style: TextStyle(
              fontSize: 13,
              fontWeight:
                  status != null ? FontWeight.w600 : FontWeight.w400,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
      ],
    );
  }

  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Activity',
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary),
        ),
        const SizedBox(height: 10),
        if (_recentMarks.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                Icon(Icons.event_note_outlined,
                    size: 36, color: Colors.grey.shade300),
                const SizedBox(height: 8),
                Text('No attendance records yet',
                    style: TextStyle(
                        color: Colors.grey.shade500, fontSize: 13)),
              ],
            ),
          )
        else
          ...(_recentMarks.map((m) {
            final status =
                (m['status'] as String? ?? '').toLowerCase();
            final date = m['sessionDate'] as String? ?? '';
            Color statusColor;
            IconData statusIcon;
            switch (status) {
              case 'present':
                statusColor = AppColors.success;
                statusIcon = Icons.check_circle_outline;
                break;
              case 'late':
                statusColor = AppColors.warning;
                statusIcon = Icons.access_time_outlined;
                break;
              case 'absent':
                statusColor = AppColors.error;
                statusIcon = Icons.cancel_outlined;
                break;
              case 'excused':
                statusColor = Colors.blueGrey;
                statusIcon = Icons.info_outline;
                break;
              default:
                statusColor = Colors.grey;
                statusIcon = Icons.circle_outlined;
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 2)),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(statusIcon,
                        color: statusColor, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          status[0].toUpperCase() + status.substring(1),
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: statusColor,
                          ),
                        ),
                        if (date.isNotEmpty)
                          Text(
                            _formatDate(date),
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          })),
      ],
    );
  }

  String _formatDate(String iso) {
    try {
      final d = DateTime.parse(iso);
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${months[d.month - 1]} ${d.day}, ${d.year}';
    } catch (_) {
      return iso;
    }
  }
}
