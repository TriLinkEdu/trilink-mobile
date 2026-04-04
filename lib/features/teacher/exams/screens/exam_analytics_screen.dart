import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/api_service.dart';

class ExamAnalyticsScreen extends StatefulWidget {
  final String examId;

  const ExamAnalyticsScreen({super.key, required this.examId});

  @override
  State<ExamAnalyticsScreen> createState() => _ExamAnalyticsScreenState();
}

class _ExamAnalyticsScreenState extends State<ExamAnalyticsScreen> {
  bool _loading = true;
  String? _error;

  List<_ScoreRange> _scoreDistribution = [];
  List<_QuestionAnalysis> _questionAnalyses = [];
  List<_TopPerformer> _topPerformers = [];
  List<_TrendPoint> _trendData = [];

  double _classAverage = 0;
  int _highestScore = 0;
  int _passRate = 0;
  int _totalSubmissions = 0;
  int _totalStudents = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final attempts = await ApiService().getExamAttempts(widget.examId);

      if (attempts.isEmpty) {
        setState(() {
          _totalSubmissions = 0;
          _totalStudents = 0;
        });
      } else {
        _computeAnalytics(attempts);
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  void _computeAnalytics(List<dynamic> attempts) {
    final scores = <int>[];
    final performers = <_TopPerformer>[];

    for (final a in attempts) {
      final attempt = a as Map<String, dynamic>;
      final score = (attempt['score'] ?? attempt['totalScore'] ?? 0) as num;
      final maxScore = (attempt['maxScore'] ?? attempt['totalMarks'] ?? 100) as num;
      final pct = maxScore > 0 ? (score / maxScore * 100).round() : 0;
      scores.add(pct);

      final student = attempt['student'] as Map<String, dynamic>?;
      final name = student?['name'] ??
          '${student?['firstName'] ?? ''} ${student?['lastName'] ?? ''}'.trim();
      performers.add(_TopPerformer(
        rank: 0,
        name: name.isEmpty ? 'Student' : name,
        score: pct,
      ));
    }

    scores.sort((a, b) => b.compareTo(a));
    performers.sort((a, b) => b.score.compareTo(a.score));

    final rankedPerformers = <_TopPerformer>[];
    for (int i = 0; i < math.min(5, performers.length); i++) {
      rankedPerformers.add(_TopPerformer(
        rank: i + 1,
        name: performers[i].name,
        score: performers[i].score,
      ));
    }

    final avg = scores.isEmpty
        ? 0.0
        : scores.reduce((a, b) => a + b) / scores.length;
    final highest = scores.isEmpty ? 0 : scores.first;
    final passing = scores.where((s) => s >= 50).length;
    final passRatePct =
        scores.isEmpty ? 0 : (passing / scores.length * 100).round();

    final ranges = [
      _ScoreRange(label: '80-100', count: scores.where((s) => s >= 80).length, color: AppColors.secondary),
      _ScoreRange(label: '60-80', count: scores.where((s) => s >= 60 && s < 80).length, color: AppColors.primary),
      _ScoreRange(label: '40-60', count: scores.where((s) => s >= 40 && s < 60).length, color: AppColors.accent),
      _ScoreRange(label: '20-40', count: scores.where((s) => s >= 20 && s < 40).length, color: Colors.orange),
      _ScoreRange(label: '0-20', count: scores.where((s) => s < 20).length, color: AppColors.error),
    ];

    setState(() {
      _classAverage = avg;
      _highestScore = highest;
      _passRate = passRatePct;
      _totalSubmissions = scores.length;
      _totalStudents = scores.length;
      _scoreDistribution = ranges;
      _topPerformers = rankedPerformers;
      _trendData = [_TrendPoint(label: 'This Exam', value: avg)];
      _questionAnalyses = [];
    });
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
          'Exam Analytics',
          style: TextStyle(
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
              : _totalSubmissions == 0
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.analytics_outlined,
                              size: 48, color: Colors.grey.shade300),
                          const SizedBox(height: 12),
                          Text(
                            'No submissions yet',
                            style: TextStyle(
                                fontSize: 16, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadData,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildOverviewCards(),
                            const SizedBox(height: 20),
                            _buildScoreDistribution(),
                            if (_questionAnalyses.isNotEmpty) ...[
                              const SizedBox(height: 20),
                              _buildPerQuestionAnalysis(),
                            ],
                            if (_topPerformers.isNotEmpty) ...[
                              const SizedBox(height: 20),
                              _buildTopPerformers(),
                            ],
                            if (_trendData.length > 1) ...[
                              const SizedBox(height: 20),
                              _buildPerformanceTrend(),
                            ],
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
    );
  }

  Widget _buildOverviewCards() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        _OverviewCard(
          title: 'Class Average',
          value: '${_classAverage.round()}%',
          icon: Icons.analytics_outlined,
          color: AppColors.primary,
        ),
        _OverviewCard(
          title: 'Highest Score',
          value: '$_highestScore%',
          icon: Icons.emoji_events_outlined,
          color: AppColors.accent,
        ),
        _OverviewCard(
          title: 'Pass Rate',
          value: '$_passRate%',
          icon: Icons.check_circle_outline,
          color: AppColors.secondary,
        ),
        _OverviewCard(
          title: 'Submissions',
          value: '$_totalSubmissions/$_totalStudents',
          icon: Icons.people_outline,
          color: Colors.purple,
        ),
      ],
    );
  }

  Widget _buildScoreDistribution() {
    final maxCount = _scoreDistribution.isEmpty
        ? 1.0
        : _scoreDistribution.map((e) => e.count).reduce(math.max).toDouble();

    return Container(
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
          const Text(
            'Score Distribution',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          ..._scoreDistribution.map((range) {
            final barWidth = maxCount > 0 ? range.count / maxCount : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  SizedBox(
                    width: 50,
                    child: Text(
                      range.label,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return Stack(
                          children: [
                            Container(
                              height: 22,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            Container(
                              height: 22,
                              width: constraints.maxWidth * barWidth,
                              decoration: BoxDecoration(
                                color: range.color,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 28,
                    child: Text(
                      '${range.count}',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPerQuestionAnalysis() {
    return Container(
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
          const Text(
            'Per-Question Analysis',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ..._questionAnalyses.map((q) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        'Q${q.number}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          q.text,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              'Avg: ${q.avgScore}%',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: q.difficultyColor
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                q.difficulty,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: q.difficultyColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 40,
                    child: Text(
                      '${q.avgScore}%',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: q.avgScore >= 70
                            ? AppColors.secondary
                            : q.avgScore >= 50
                                ? AppColors.accent
                                : AppColors.error,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTopPerformers() {
    return Container(
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
          const Text(
            'Top Performers',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ..._topPerformers.map((performer) {
            final isTopThree = performer.rank <= 3;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isTopThree
                          ? _rankColor(performer.rank).withValues(alpha: 0.15)
                          : Colors.grey.shade100,
                    ),
                    child: Center(
                      child: Text(
                        '${performer.rank}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isTopThree
                              ? _rankColor(performer.rank)
                              : Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      performer.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    '${performer.score}%',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isTopThree
                          ? _rankColor(performer.rank)
                          : Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Color _rankColor(int rank) {
    switch (rank) {
      case 1:
        return AppColors.accent;
      case 2:
        return Colors.blueGrey;
      case 3:
        return Colors.brown;
      default:
        return Colors.grey;
    }
  }

  Widget _buildPerformanceTrend() {
    return Container(
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
          const Text(
            'Performance Trend',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: CustomPaint(
              size: Size.infinite,
              painter: _TrendChartPainter(
                data: _trendData,
                lineColor: AppColors.primary,
                fillColor: AppColors.primary.withValues(alpha: 0.1),
                dotColor: AppColors.primary,
                gridColor: Colors.grey.shade200,
                textColor: Colors.grey.shade600,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _trendData
                .map((d) => Text(
                      d.label,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _ScoreRange {
  final String label;
  final int count;
  final Color color;

  _ScoreRange({
    required this.label,
    required this.count,
    required this.color,
  });
}

class _QuestionAnalysis {
  final int number;
  final String text;
  final int avgScore;
  final String difficulty;

  _QuestionAnalysis({
    required this.number,
    required this.text,
    required this.avgScore,
    required this.difficulty,
  });

  Color get difficultyColor {
    switch (difficulty) {
      case 'Easy':
        return AppColors.secondary;
      case 'Medium':
        return AppColors.accent;
      case 'Hard':
        return AppColors.error;
      default:
        return Colors.grey;
    }
  }
}

class _TopPerformer {
  final int rank;
  final String name;
  final int score;

  _TopPerformer({
    required this.rank,
    required this.name,
    required this.score,
  });
}

class _TrendPoint {
  final String label;
  final double value;

  _TrendPoint({required this.label, required this.value});
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendChartPainter extends CustomPainter {
  final List<_TrendPoint> data;
  final Color lineColor;
  final Color fillColor;
  final Color dotColor;
  final Color gridColor;
  final Color textColor;

  _TrendChartPainter({
    required this.data,
    required this.lineColor,
    required this.fillColor,
    required this.dotColor,
    required this.gridColor,
    required this.textColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    const double padLeft = 30;
    const double padTop = 10;
    const double padBottom = 10;
    const double padRight = 10;

    final chartWidth = size.width - padLeft - padRight;
    final chartHeight = size.height - padTop - padBottom;

    final minVal = data.map((d) => d.value).reduce(math.min) - 10;
    final maxVal = data.map((d) => d.value).reduce(math.max) + 10;
    final range = maxVal - minVal;

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.5;

    for (int i = 0; i <= 4; i++) {
      final y = padTop + chartHeight * (1 - i / 4);
      canvas.drawLine(
        Offset(padLeft, y),
        Offset(size.width - padRight, y),
        gridPaint,
      );

      final label = (minVal + range * i / 4).toInt().toString();
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(fontSize: 10, color: textColor),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(padLeft - tp.width - 4, y - tp.height / 2));
    }

    final points = <Offset>[];
    final divisor = data.length > 1 ? data.length - 1 : 1;
    for (int i = 0; i < data.length; i++) {
      final x = padLeft + (chartWidth / divisor) * i;
      final y = padTop + chartHeight * (1 - (data[i].value - minVal) / range);
      points.add(Offset(x, y));
    }

    final fillPath = Path()..moveTo(points.first.dx, padTop + chartHeight);
    for (final p in points) {
      fillPath.lineTo(p.dx, p.dy);
    }
    fillPath.lineTo(points.last.dx, padTop + chartHeight);
    fillPath.close();
    canvas.drawPath(fillPath, Paint()..color = fillColor);

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;

    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      linePath.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(linePath, linePaint);

    for (final p in points) {
      canvas.drawCircle(
        p,
        4,
        Paint()..color = Colors.white,
      );
      canvas.drawCircle(
        p,
        4,
        Paint()
          ..color = dotColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
