import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/api_service.dart';

class AttendanceAnalyticsScreen extends StatefulWidget {
  const AttendanceAnalyticsScreen({super.key});

  @override
  State<AttendanceAnalyticsScreen> createState() =>
      _AttendanceAnalyticsScreenState();
}

class _AttendanceAnalyticsScreenState extends State<AttendanceAnalyticsScreen> {
  bool _loadingClasses = true;
  bool _loadingReport = false;
  String? _error;

  List<Map<String, dynamic>> _classOfferings = [];
  String? _selectedClassId;

  double _averageAttendance = 0;
  int _totalAbsences = 0;
  int _lateArrivals = 0;
  List<_WeekData> _weeklyData = [];
  List<_AbsentStudent> _mostAbsent = [];
  List<_DayAttendance> _dailyBreakdown = [];

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    try {
      setState(() {
        _loadingClasses = true;
        _error = null;
      });

      final yearData = await ApiService().getActiveAcademicYear();
      final yearId = yearData['id'] as String;
      final offerings = await ApiService().getMyClassOfferings(yearId);

      if (!mounted) return;
      setState(() {
        _classOfferings = offerings.cast<Map<String, dynamic>>();
        _loadingClasses = false;
        if (_classOfferings.isNotEmpty) {
          _selectedClassId = _classOfferings.first['id'] as String?;
          _loadReport();
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loadingClasses = false;
      });
    }
  }

  Future<void> _loadReport() async {
    if (_selectedClassId == null) return;
    try {
      setState(() {
        _loadingReport = true;
        _error = null;
      });

      final report = await ApiService().getClassAttendanceReport(
        _selectedClassId!,
      );

      if (!mounted) return;
      setState(() {
        _averageAttendance =
            (report['averageAttendance'] as num?)?.toDouble() ?? 0;
        _totalAbsences = (report['totalAbsences'] as num?)?.toInt() ?? 0;
        _lateArrivals = (report['lateArrivals'] as num?)?.toInt() ?? 0;

        final weekly = report['weeklyTrends'] as List<dynamic>? ?? [];
        _weeklyData = weekly.map((w) {
          final m = w as Map<String, dynamic>;
          return _WeekData(
            label: m['label']?.toString() ?? '',
            percentage: (m['percentage'] as num?)?.toDouble() ?? 0,
          );
        }).toList();

        final absent = report['mostAbsent'] as List<dynamic>? ?? [];
        _mostAbsent = absent.map((a) {
          final m = a as Map<String, dynamic>;
          return _AbsentStudent(
            name: m['name']?.toString() ?? 'Unknown',
            absences: (m['absences'] as num?)?.toInt() ?? 0,
            totalDays: (m['totalDays'] as num?)?.toInt() ?? 1,
          );
        }).toList();

        final daily = report['dailyBreakdown'] as List<dynamic>? ?? [];
        _dailyBreakdown = daily.map((d) {
          final m = d as Map<String, dynamic>;
          return _DayAttendance(
            day: m['day']?.toString() ?? '',
            percentage: (m['percentage'] as num?)?.toInt() ?? 0,
          );
        }).toList();

        _loadingReport = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loadingReport = false;
      });
    }
  }

  String _labelFor(Map<String, dynamic> offering) {
    final subject = offering['subject'];
    final grade = offering['grade'];
    final section = offering['section'];
    final subjectName = subject is Map ? (subject['name'] ?? '') : '';
    final gradeName = grade is Map ? (grade['name'] ?? '') : '';
    final sectionName = section is Map ? (section['name'] ?? '') : '';
    return '$subjectName $gradeName$sectionName'.trim();
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
          'Attendance Analytics',
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loadingClasses) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _classOfferings.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'Failed to load data',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error ?? '',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _loadClasses,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_classOfferings.isEmpty) {
      return Center(
        child: Text(
          'No classes found.',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildClassDropdown(),
          const SizedBox(height: 20),
          if (_loadingReport)
            const Padding(
              padding: EdgeInsets.only(top: 80),
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            _buildOverviewCards(),
            const SizedBox(height: 24),
            if (_weeklyData.isNotEmpty) ...[
              _buildTrendsSection(),
              const SizedBox(height: 24),
            ],
            if (_mostAbsent.isNotEmpty) ...[
              _buildMostAbsentSection(),
              const SizedBox(height: 24),
            ],
            if (_dailyBreakdown.isNotEmpty) ...[
              _buildDailyBreakdownSection(),
              const SizedBox(height: 32),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildClassDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedClassId,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          items: _classOfferings.map((c) {
            final id = c['id'] as String;
            return DropdownMenuItem(value: id, child: Text(_labelFor(c)));
          }).toList(),
          onChanged: (val) {
            if (val != null && val != _selectedClassId) {
              setState(() => _selectedClassId = val);
              _loadReport();
            }
          },
        ),
      ),
    );
  }

  Widget _buildOverviewCards() {
    return Row(
      children: [
        Expanded(
          child: _OverviewCard(
            title: 'Average\nAttendance',
            value: '${_averageAttendance.round()}%',
            icon: Icons.trending_up,
            color: AppColors.secondary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _OverviewCard(
            title: 'Total\nAbsences',
            value: '$_totalAbsences',
            icon: Icons.person_off_outlined,
            color: AppColors.error,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _OverviewCard(
            title: 'Late\nArrivals',
            value: '$_lateArrivals',
            icon: Icons.schedule,
            color: AppColors.accent,
          ),
        ),
      ],
    );
  }

  Widget _buildTrendsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'WEEKLY TRENDS',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade500,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              SizedBox(
                height: 180,
                child: CustomPaint(
                  size: const Size(double.infinity, 180),
                  painter: _TrendChartPainter(data: _weeklyData),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: _weeklyData
                    .map(
                      (w) => Text(
                        w.label,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMostAbsentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'MOST ABSENT STUDENTS',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade500,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 12),
        ...List.generate(_mostAbsent.length, (index) {
          final student = _mostAbsent[index];
          final ratio = student.totalDays > 0
              ? student.absences / student.totalDays
              : 0.0;
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
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.error.withValues(alpha: 0.1),
                  child: Text(
                    student.name
                        .split(' ')
                        .where((w) => w.isNotEmpty)
                        .map((w) => w[0])
                        .take(2)
                        .join()
                        .toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.error,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: ratio,
                          minHeight: 6,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            ratio > 0.15 ? AppColors.error : AppColors.accent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${student.absences}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: AppColors.error,
                      ),
                    ),
                    Text(
                      'absences',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildDailyBreakdownSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ATTENDANCE BY DAY',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade500,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: _dailyBreakdown.map((day) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    SizedBox(
                      width: 36,
                      child: Text(
                        day.day,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: day.percentage / 100,
                          minHeight: 14,
                          backgroundColor: Colors.grey.shade100,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            day.percentage >= 95
                                ? AppColors.secondary
                                : day.percentage >= 90
                                ? AppColors.primary
                                : AppColors.accent,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 40,
                      child: Text(
                        '${day.percentage}%',
                        textAlign: TextAlign.end,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _OverviewCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _OverviewCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendChartPainter extends CustomPainter {
  final List<_WeekData> data;

  _TrendChartPainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    const double minVal = 80;
    const double maxVal = 100;
    const double range = maxVal - minVal;

    final gridPaint = Paint()
      ..color = const Color(0xFFE8E8E8)
      ..strokeWidth = 1;

    for (int i = 0; i <= 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final linePaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.primary.withValues(alpha: 0.25),
          AppColors.primary.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final dotPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill;

    final dotBorderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final points = <Offset>[];
    for (int i = 0; i < data.length; i++) {
      final x = data.length == 1
          ? size.width / 2
          : i * size.width / (data.length - 1);
      final clamped = data[i].percentage.clamp(minVal, maxVal);
      final normalized = (clamped - minVal) / range;
      final y = size.height - (normalized * size.height);
      points.add(Offset(x, y));
    }

    if (points.length == 1) {
      canvas.drawCircle(points[0], 5, dotBorderPaint);
      canvas.drawCircle(points[0], 3.5, dotPaint);
      return;
    }

    final linePath = Path()..moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      final cp1x = points[i - 1].dx + (points[i].dx - points[i - 1].dx) / 3;
      final cp2x = points[i].dx - (points[i].dx - points[i - 1].dx) / 3;
      linePath.cubicTo(
        cp1x,
        points[i - 1].dy,
        cp2x,
        points[i].dy,
        points[i].dx,
        points[i].dy,
      );
    }

    final fillPath = Path.from(linePath)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(fillPath, fillPaint);

    canvas.drawPath(linePath, linePaint);

    for (final point in points) {
      canvas.drawCircle(point, 5, dotBorderPaint);
      canvas.drawCircle(point, 3.5, dotPaint);
    }

    final textPainterStyle = TextStyle(
      fontSize: 10,
      color: Colors.grey.shade500,
      fontWeight: FontWeight.w500,
    );
    for (int i = 0; i <= 4; i++) {
      final val = maxVal - (range * i / 4);
      final tp = TextPainter(
        text: TextSpan(text: '${val.toInt()}%', style: textPainterStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      final y = size.height * i / 4 - tp.height - 2;
      tp.paint(canvas, Offset(0, y));
    }
  }

  @override
  bool shouldRepaint(covariant _TrendChartPainter oldDelegate) =>
      oldDelegate.data != data;
}

class _WeekData {
  final String label;
  final double percentage;

  _WeekData({required this.label, required this.percentage});
}

class _AbsentStudent {
  final String name;
  final int absences;
  final int totalDays;

  _AbsentStudent({
    required this.name,
    required this.absences,
    required this.totalDays,
  });
}

class _DayAttendance {
  final String day;
  final int percentage;

  _DayAttendance({required this.day, required this.percentage});
}
