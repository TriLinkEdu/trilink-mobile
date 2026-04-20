import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/routes/route_names.dart';
import '../../../../core/services/storage_service.dart';
import '../models/student_growth_models.dart';
import 'student_analytics_repository.dart';

class RealStudentAnalyticsRepository implements StudentAnalyticsRepository {
  final ApiClient _api;
  final StorageService _storage;

  RealStudentAnalyticsRepository({
    ApiClient? apiClient,
    required StorageService storageService,
  }) : _api = apiClient ?? ApiClient(),
       _storage = storageService;

  @override
  Future<StudentWeeklySnapshot> fetchWeeklySnapshot() async {
    final dashboard = await _api.get(ApiConstants.dashboardStudent);
    final grades = await _api.get('/reports/my-grades');

    final attendanceRaw = _asDouble(
      (dashboard['attendanceSummaryLast30Days']
          as Map<String, dynamic>?)?['presentOrLateRate'],
      fallback: 0,
    );
    final attendanceRate = attendanceRaw > 1
        ? attendanceRaw / 100
        : attendanceRaw;

    final subjectAverages = _subjectAverages(grades);
    final overallScore = subjectAverages.isEmpty
        ? 0.0
        : subjectAverages.values.reduce((a, b) => a + b) /
              subjectAverages.length;

    final focusSubjects = subjectAverages.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    final dueAssignments = _readList(dashboard['upcomingExams']).length;
    final trend = overallScore >= 70 ? 'up' : 'flat';

    final focus = focusSubjects.take(2).map((e) => e.key).toList();
    return StudentWeeklySnapshot(
      attendanceRate: attendanceRate,
      averageQuizScore: overallScore,
      dueAssignments: dueAssignments,
      trend: trend,
      focusSubjects: focus,
      summary: _weeklySummary(attendanceRate, overallScore, dueAssignments),
    );
  }

  @override
  Future<StudentPerformanceTrends> fetchPerformanceTrends() async {
    final grades = await _api.get('/reports/my-grades');
    final subjectsRaw = _readList(grades['subjects']);
    final subjects = <StudentSubjectTrend>[];

    for (final raw in subjectsRaw.whereType<Map<String, dynamic>>()) {
      final subjectId = (raw['subjectId'] ?? '').toString();
      final subjectName = (raw['subjectName'] ?? 'Subject').toString();
      final exams = _readList(raw['exams']);
      if (exams.isEmpty) continue;

      final points = <StudentTrendPoint>[];
      final scored = <double>[];
      for (final exam in exams.whereType<Map<String, dynamic>>()) {
        final score = _asDouble(exam['score'], fallback: 0);
        final max = _asDouble(exam['maxPoints'], fallback: 100);
        final percent = max <= 0 ? 0.0 : (score / max) * 100;
        final releasedAt = DateTime.tryParse(
          (exam['releasedAt'] ?? '').toString(),
        );
        final label = releasedAt == null
            ? 'Recent'
            : '${releasedAt.month}/${releasedAt.day}';
        points.add(StudentTrendPoint(label: label, value: percent));
        scored.add(percent);
      }

      if (points.isEmpty) continue;
      final recent = points.last.value;
      final recommendation = recent < 70
          ? 'Prioritize revision tasks for $subjectName this week.'
          : 'Maintain momentum in $subjectName with one focused practice set daily.';

      subjects.add(
        StudentSubjectTrend(
          subjectId: subjectId,
          subjectName: subjectName,
          points: points,
          strengthTopics: recent >= 70 ? ['Recent assessments'] : const [],
          riskTopics: recent < 70 ? ['Recent assessments'] : const [],
          recommendation: recommendation,
        ),
      );
    }

    final readiness = subjects.isEmpty
        ? 0
        : (subjects.map((s) => s.points.last.value).reduce((a, b) => a + b) /
                  subjects.length)
              .round();

    return StudentPerformanceTrends(
      examReadinessScore: readiness.clamp(0, 100),
      subjects: subjects,
    );
  }

  @override
  Future<StudentAttendanceInsight> fetchAttendanceInsight() async {
    final studentId = await _resolveStudentId();
    final report = await _api.get(
      ApiConstants.attendanceStudentReport(studentId),
    );
    final marks = _readList(report['marks']);

    if (marks.isEmpty) {
      return const StudentAttendanceInsight(
        currentRate: 0,
        weeklyTrend: [],
        riskLevel: 'High',
        projectedMonthEndRate: 0,
        bestDay: 'N/A',
        weakDay: 'N/A',
      );
    }

    final presentOrLate = marks.where((m) {
      final status = (m is Map<String, dynamic> ? m['status'] : '')
          .toString()
          .toLowerCase();
      return status == 'present' || status == 'late';
    }).length;
    final currentRate = presentOrLate / marks.length;

    final weeklyBuckets = <String, List<double>>{};
    final dayRates = <int, List<double>>{};

    for (final row in marks.whereType<Map<String, dynamic>>()) {
      final date = DateTime.tryParse((row['sessionDate'] ?? '').toString());
      if (date == null) continue;
      final status = (row['status'] ?? '').toString().toLowerCase();
      final value = (status == 'present' || status == 'late') ? 100.0 : 0.0;
      final weekKey =
          '${date.year}-W${((date.day - 1) ~/ 7) + 1}-${date.month}';
      weeklyBuckets.putIfAbsent(weekKey, () => []).add(value);
      dayRates.putIfAbsent(date.weekday, () => []).add(value);
    }

    final weekEntries = weeklyBuckets.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final weeklyTrend = weekEntries
        .take(4)
        .map(
          (entry) => StudentTrendPoint(
            label: entry.key.split('-').skip(1).join(' '),
            value: entry.value.reduce((a, b) => a + b) / entry.value.length,
          ),
        )
        .toList();

    final best = _bestDay(dayRates, highest: true);
    final weak = _bestDay(dayRates, highest: false);

    return StudentAttendanceInsight(
      currentRate: currentRate,
      weeklyTrend: weeklyTrend,
      riskLevel: _riskLabel(currentRate),
      projectedMonthEndRate: currentRate,
      bestDay: _weekdayLabel(best),
      weakDay: _weekdayLabel(weak),
    );
  }

  @override
  Future<List<StudentActionItem>> fetchActionPlan() async {
    final goalsRows = await _api.getList(ApiConstants.myGoals);
    final dashboard = await _api.get(ApiConstants.dashboardStudent);
    final grades = await _api.get('/reports/my-grades');

    final actions = <StudentActionItem>[];

    final activeGoals = goalsRows
        .whereType<Map<String, dynamic>>()
        .where((g) {
          final status = (g['status'] ?? 'active').toString().toLowerCase();
          return status == 'active';
        })
        .take(2);

    for (final goal in activeGoals) {
      actions.add(
        StudentActionItem(
          id: (goal['id'] ?? '').toString(),
          title: (goal['title'] ?? 'Complete your goal').toString(),
          reason: 'This goal is still active and impacts your progress.',
          category: 'goal',
          effortMinutes: 20,
          routeName: RouteNames.studentGoals,
          routeArgs: null,
          done: false,
        ),
      );
    }

    final subjectAverages = _subjectAverages(grades);
    if (subjectAverages.isNotEmpty) {
      final weakest = subjectAverages.entries.toList()
        ..sort((a, b) => a.value.compareTo(b.value));
      final weak = weakest.first;
      actions.add(
        StudentActionItem(
          id: 'study-${weak.key.toLowerCase().replaceAll(' ', '-')}',
          title: 'Review ${weak.key}',
          reason: 'This is your lowest-performing subject right now.',
          category: 'study',
          effortMinutes: 30,
          routeName: RouteNames.studentGrades,
          routeArgs: null,
          done: false,
        ),
      );
    }

    final upcomingExams = _readList(dashboard['upcomingExams']);
    if (upcomingExams.isNotEmpty) {
      actions.add(
        StudentActionItem(
          id: 'exam-prep',
          title: 'Prepare upcoming exam',
          reason: 'You have ${upcomingExams.length} exam(s) scheduled soon.',
          category: 'exam',
          effortMinutes: 25,
          routeName: RouteNames.studentExams,
          routeArgs: null,
          done: false,
        ),
      );
    }

    if (actions.isEmpty) {
      actions.add(
        const StudentActionItem(
          id: 'refresh-learning-routine',
          title: 'Plan your next study block',
          reason:
              'Keep consistency by scheduling at least one focused session today.',
          category: 'routine',
          effortMinutes: 20,
          routeName: RouteNames.studentGoals,
          routeArgs: null,
          done: false,
        ),
      );
    }

    return actions;
  }

  Map<String, double> _subjectAverages(Map<String, dynamic> gradesResponse) {
    final subjectAverages = <String, double>{};
    final subjects = _readList(gradesResponse['subjects']);
    for (final subject in subjects.whereType<Map<String, dynamic>>()) {
      final name = (subject['subjectName'] ?? 'Subject').toString();
      final exams = _readList(subject['exams']);
      if (exams.isEmpty) continue;
      final percentages = <double>[];
      for (final exam in exams.whereType<Map<String, dynamic>>()) {
        final score = _asDouble(exam['score'], fallback: 0);
        final max = _asDouble(exam['maxPoints'], fallback: 100);
        if (max <= 0) continue;
        percentages.add((score / max) * 100);
      }
      if (percentages.isEmpty) continue;
      subjectAverages[name] =
          percentages.reduce((a, b) => a + b) / percentages.length;
    }
    return subjectAverages;
  }

  String _weeklySummary(
    double attendanceRate,
    double avgScore,
    int dueAssignments,
  ) {
    final att = (attendanceRate * 100).round();
    final score = avgScore.round();
    return 'Attendance is $att%, average score is $score%, and $dueAssignments tasks need attention this week.';
  }

  String _riskLabel(double rate) {
    if (rate >= 0.9) return 'Low';
    if (rate >= 0.75) return 'Medium';
    return 'High';
  }

  int _bestDay(Map<int, List<double>> dayRates, {required bool highest}) {
    if (dayRates.isEmpty) return DateTime.monday;
    final entries = dayRates.entries.map((e) {
      final avg = e.value.reduce((a, b) => a + b) / e.value.length;
      return MapEntry(e.key, avg);
    }).toList();
    entries.sort(
      (a, b) =>
          highest ? b.value.compareTo(a.value) : a.value.compareTo(b.value),
    );
    return entries.first.key;
  }

  String _weekdayLabel(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Monday';
      case DateTime.tuesday:
        return 'Tuesday';
      case DateTime.wednesday:
        return 'Wednesday';
      case DateTime.thursday:
        return 'Thursday';
      case DateTime.friday:
        return 'Friday';
      case DateTime.saturday:
        return 'Saturday';
      case DateTime.sunday:
        return 'Sunday';
      default:
        return 'N/A';
    }
  }

  List<dynamic> _readList(dynamic value) {
    if (value is List) return value;
    return const [];
  }

  double _asDouble(dynamic value, {required double fallback}) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? fallback;
  }

  Future<String> _resolveStudentId() async {
    final user = await _storage.getUser();
    final id = (user?['id'] ?? '').toString();
    if (id.isEmpty) {
      throw StateError('Student session not found. Please login again.');
    }
    return id;
  }
}
