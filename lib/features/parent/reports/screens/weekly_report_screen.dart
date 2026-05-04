import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/api_service.dart';
import '../../../shared/widgets/role_page_background.dart';

class WeeklyReportScreen extends StatefulWidget {
  final String? childStudentId;
  final String childName;

  const WeeklyReportScreen({
    super.key,
    this.childStudentId,
    this.childName = '',
  });

  @override
  State<WeeklyReportScreen> createState() => _WeeklyReportScreenState();
}

class _WeeklyReportScreenState extends State<WeeklyReportScreen> {
  bool _loading = true;
  String? _error;

  // Backend returns { weekFrom, weekThrough, generatedAt, children: [...] }
  Map<String, dynamic> _summary = {};

  // The child entry we care about
  Map<String, dynamic> _childData = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _loading = true; _error = null; });
    try {
      // GET /reports/parent/weekly-summary?childStudentId=...
      final data = await ApiService().getWeeklyParentSummary(
        childStudentId: widget.childStudentId,
      );
      if (!mounted) return;

      final children = (data['children'] as List<dynamic>?) ?? [];

      // Pick the matching child or first one
      Map<String, dynamic> child = {};
      if (children.isNotEmpty) {
        if (widget.childStudentId != null) {
          child = (children.firstWhere(
            (c) => (c as Map)['studentId'] == widget.childStudentId,
            orElse: () => children.first,
          ) as Map<String, dynamic>);
        } else {
          child = children.first as Map<String, dynamic>;
        }
      }

      setState(() {
        _summary = data;
        _childData = child;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  String get _displayName {
    if (widget.childName.isNotEmpty) return widget.childName;
    return _childData['name'] as String? ?? 'Student';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new,
              color: theme.colorScheme.onSurface, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Weekly Report',
          style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.bold,
              fontSize: 17),
        ),
        centerTitle: true,
      ),
      body: RolePageBackground(
        flavor: RoleThemeFlavor.parent,
        child: _loading
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
                          _buildWeekHeader(),
                          const SizedBox(height: 16),
                          _buildAttendanceCard(),
                          const SizedBox(height: 16),
                          _buildExamsCard(),
                          const SizedBox(height: 20),
                        ],
                      ),
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
            Icon(Icons.wifi_off_rounded, size: 48, color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(_error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13)),
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

  Widget _buildWeekHeader() {
    final weekFrom = _summary['weekFrom'] as String? ?? '';
    final weekThrough = _summary['weekThrough'] as String? ?? '';
    final initials = _displayName
        .split(' ')
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p[0].toUpperCase())
        .join();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Theme.of(context).shadowColor.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
            child: Text(initials,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_displayName,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface)),
                const SizedBox(height: 3),
                if (weekFrom.isNotEmpty && weekThrough.isNotEmpty)
                  Text(
                    '${_formatDate(weekFrom)} – ${_formatDate(weekThrough)}',
                    style: TextStyle(
                        fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'This Week',
              style: TextStyle(
                  fontSize: 11,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceCard() {
    final att = _childData['attendanceThisWeek'] as Map<String, dynamic>? ?? {};
    final total = att['totalMarks'] as int? ?? 0;
    final byStatus = att['byStatus'] as Map<String, dynamic>? ?? {};
    final present = byStatus['present'] as int? ?? 0;
    final late = byStatus['late'] as int? ?? 0;
    final absent = byStatus['absent'] as int? ?? 0;
    final rate = att['presentOrLateRate'] as num?;
    final ratePct = rate != null ? rate * 100 : null;

    final rateColor = ratePct == null
        ? Theme.of(context).colorScheme.onSurfaceVariant
        : ratePct >= 80
            ? AppColors.success
            : ratePct >= 60
                ? AppColors.warning
                : AppColors.error;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Theme.of(context).shadowColor.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.event_available_outlined,
                    color: AppColors.secondary, size: 18),
              ),
              const SizedBox(width: 10),
              Text('Attendance This Week',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface)),
            ],
          ),
          const SizedBox(height: 16),
          if (total == 0)
            Center(
              child: Text('No attendance data this week',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13)),
            )
          else ...[
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        ratePct != null
                            ? '${ratePct.toStringAsFixed(0)}%'
                            : '--',
                        style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: rateColor),
                      ),
                      Text('Rate',
                          style: TextStyle(
                              fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ),
                _buildAttStat('Present', present, AppColors.success),
                _buildAttStat('Late', late, AppColors.warning),
                _buildAttStat('Absent', absent, AppColors.error),
              ],
            ),
            const SizedBox(height: 12),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: total > 0 ? (present + late) / total : 0,
                backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
                valueColor: AlwaysStoppedAnimation(rateColor),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 4),
            Text('$total sessions recorded this week',
                style: TextStyle(
                    fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
        ],
      ),
    );
  }

  Widget _buildAttStat(String label, int count, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text('$count',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color)),
          Text(label,
              style: TextStyle(
                  fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _buildExamsCard() {
    final examsCount = _childData['examsReleasedThisWeek'] as int? ?? 0;
    final exams = (_childData['exams'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Theme.of(context).shadowColor.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.assignment_outlined,
                    color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text('Exams This Week',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$examsCount released',
                  style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (exams.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text('No exams released this week',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13)),
              ),
            )
          else
            ...exams.map((exam) {
              final title = exam['title'] as String? ?? 'Exam';
              final score = exam['score'] as num?;
              final releasedAt = exam['releasedAt'] as String? ?? '';
              final scoreColor = score == null
                  ? Theme.of(context).colorScheme.onSurfaceVariant
                  : score >= 80
                      ? AppColors.success
                      : score >= 60
                          ? AppColors.warning
                          : AppColors.error;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title,
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).colorScheme.onSurface),
                              overflow: TextOverflow.ellipsis),
                          if (releasedAt.isNotEmpty)
                            Text(_formatDate(releasedAt),
                                style: TextStyle(
                                    fontSize: 11,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
                        ],
                      ),
                    ),
                    if (score != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: scoreColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${score.toStringAsFixed(0)}',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: scoreColor),
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

  String _formatDate(String iso) {
    try {
      final d = DateTime.parse(iso);
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${months[d.month - 1]} ${d.day}';
    } catch (_) {
      return iso;
    }
  }
}
