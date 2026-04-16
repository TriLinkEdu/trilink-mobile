import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/api_service.dart';

class ParentResultsScreen extends StatefulWidget {
  const ParentResultsScreen({super.key});

  @override
  State<ParentResultsScreen> createState() => _ParentResultsScreenState();
}

class _ParentResultsScreenState extends State<ParentResultsScreen> {
  bool _loading = true;
  String? _error;
  int _selectedChildIndex = 0;

  List<Map<String, dynamic>> _children = [];
  Map<String, dynamic> _performance = {};

  String get studentName {
    if (_children.isEmpty) return '';
    final c = _children[_selectedChildIndex];
    return c['fullName'] as String? ??
        '${c['firstName'] ?? ''} ${c['lastName'] ?? ''}'.trim();
  }

  String get studentId {
    if (_children.isEmpty) return '';
    return _children[_selectedChildIndex]['studentId'] as String? ??
        _children[_selectedChildIndex]['id'] as String? ?? '';
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
      _children = children.map<Map<String, dynamic>>((child) {
        final student = child['student'] as Map<String, dynamic>?;
        return {
          'id': child['id'],
          'studentId': student?['id'] ?? child['studentId'],
          'firstName': student?['firstName'] ?? child['firstName'],
          'lastName': student?['lastName'] ?? child['lastName'],
          'fullName': '${student?['firstName'] ?? ''} ${student?['lastName'] ?? ''}'.trim(),
        };
      }).toList();
      
      if (_children.isNotEmpty) {
        await _loadPerformance();
      } else {
        if (!mounted) return;
        setState(() { _loading = false; });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _loadPerformance() async {
    try {
      // Use child performance report API
      final perf = await ApiService().getChildPerformanceReport(studentId);
      if (!mounted) return;
      setState(() { _performance = perf; _loading = false; });
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
          'Academic Results',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: _loading
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
              : Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildStudentHeader(),
                            const SizedBox(height: 16),
                            _buildTermAverageCard(),
                            const SizedBox(height: 24),
                            _buildSubjectPerformance(),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                    _buildDownloadButton(),
                  ],
                ),
    );
  }

  Widget _buildStudentHeader() {
    final avatar = _children.isNotEmpty
        ? _children[_selectedChildIndex]['avatar'] as String? ?? ''
        : '';
    final grade = _performance['grade'] as String? ?? '';
    final semester = _performance['semester'] as String? ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          avatar.isNotEmpty
              ? CircleAvatar(
                  radius: 28,
                  backgroundImage: NetworkImage(avatar),
                )
              : CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: Text(
                    studentName.isNotEmpty ? studentName[0] : '?',
                    style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 20),
                  ),
                ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                studentName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$grade • ID: #$studentId',
                style:
                    TextStyle(fontSize: 13, color: Colors.grey.shade500),
              ),
              if (semester.isNotEmpty) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    semester,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.secondary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTermAverageCard() {
    final average = _performance['termAverage']?.toString() ?? '--';
    final gpa = _performance['gpa']?.toString() ?? '';
    final rank = _performance['classRank'] as String? ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1A73E8), Color(0xFF4A9AF5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current Term Average',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  average.contains('%') ? average : '$average%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (gpa.isNotEmpty) ...[
                  const SizedBox(width: 10),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      'GPA $gpa',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            if (rank.isNotEmpty) ...[
              const SizedBox(height: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check, color: Colors.white, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      rank,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectPerformance() {
    final subjects =
        (_performance['subjects'] as List<dynamic>?) ?? [];
    final iconMap = {
      'mathematics': Icons.calculate,
      'math': Icons.calculate,
      'physics': Icons.science,
      'science': Icons.science,
      'english': Icons.menu_book,
      'history': Icons.history_edu,
    };
    final colorMap = {
      'mathematics': AppColors.primary,
      'math': AppColors.primary,
      'physics': AppColors.error,
      'science': AppColors.secondary,
      'english': Colors.purple,
      'history': Colors.orange,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Subject Performance',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const Text(
                'View All',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (subjects.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text('No subject data available',
                    style: TextStyle(color: Colors.grey.shade500)),
              ),
            ),
          ...subjects.map<Widget>((s) {
            final name = (s['name'] as String? ?? '').toLowerCase();
            final details = (s['details'] as List<dynamic>?)
                    ?.map<_GradeDetail>((d) => _GradeDetail(
                          name: d['name'] as String? ?? '',
                          grade: d['grade'] as String? ?? '',
                        ))
                    .toList() ??
                [];
            final trend = (s['trend'] as List<dynamic>?)
                    ?.map<double>((v) => (v as num).toDouble())
                    .toList();

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _SubjectCard(
                icon: iconMap[name] ?? Icons.school,
                iconColor: colorMap[name] ?? AppColors.primary,
                name: s['name'] as String? ?? '',
                teacher: s['teacher'] as String? ?? '',
                grade: s['grade'] as String? ?? '',
                gradeLabel: s['gradeLabel'] as String? ?? '',
                isExpanded: details.isNotEmpty,
                details: details.isNotEmpty ? details : null,
                trendData: trend,
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDownloadButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: ElevatedButton.icon(
        onPressed: () {},
        icon: const Icon(Icons.download, size: 18),
        label: const Text(
          'Download Full Term Report',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}

class _SubjectCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String name;
  final String teacher;
  final String grade;
  final String gradeLabel;
  final bool isExpanded;
  final List<_GradeDetail>? details;
  final List<double>? trendData;

  const _SubjectCard({
    required this.icon,
    required this.iconColor,
    required this.name,
    required this.teacher,
    required this.grade,
    required this.gradeLabel,
    this.isExpanded = false,
    this.details,
    this.trendData,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
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
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      teacher,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    grade,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    gradeLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 4),
              Icon(
                isExpanded
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
                color: Colors.grey.shade400,
              ),
            ],
          ),
          if (isExpanded && details != null) ...[
            const SizedBox(height: 14),
            ...details!.map((d) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 44),
                        child: Text(
                          d.name,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                      Text(
                        d.grade,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                )),
            if (trendData != null) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.only(left: 44),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PERFORMANCE TREND',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade500,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 50,
                      child: CustomPaint(
                        size: const Size(double.infinity, 50),
                        painter: _TrendLinePainter(data: trendData!),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _GradeDetail {
  final String name;
  final String grade;
  const _GradeDetail({required this.name, required this.grade});
}

class _TrendLinePainter extends CustomPainter {
  final List<double> data;
  _TrendLinePainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final minVal = data.reduce(math.min) - 0.2;
    final maxVal = data.reduce(math.max) + 0.2;
    final range = maxVal - minVal;

    final points = <Offset>[];
    for (int i = 0; i < data.length; i++) {
      final x = size.width * i / (data.length - 1);
      final y = size.height - (size.height * (data[i] - minVal) / range);
      points.add(Offset(x, y));
    }

    final linePaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(path, linePaint);

    final dotPaint = Paint()..color = AppColors.primary;
    for (final p in points) {
      canvas.drawCircle(p, 4, dotPaint);
      canvas.drawCircle(
        p,
        4,
        Paint()
          ..color = Colors.white
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
