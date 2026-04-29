import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/routes/route_names.dart';
import '../../../../core/services/storage_service.dart';
import '../models/student_growth_models.dart';
import 'student_analytics_repository.dart';

class RealStudentAnalyticsRepository implements StudentAnalyticsRepository {
  final ApiClient _api;
  final StorageService _storage;

  static const Duration _dashboardTtl = Duration(seconds: 30);
  static const Duration _gradesTtl = Duration(seconds: 30);
  static const Duration _goalsTtl = Duration(seconds: 30);
  static const Duration _attendanceTtl = Duration(seconds: 20);

  static Map<String, dynamic>? _dashboardCache;
  static DateTime? _dashboardFetchedAt;
  static Future<Map<String, dynamic>>? _dashboardInFlight;

  static Map<String, dynamic>? _gradesCache;
  static DateTime? _gradesFetchedAt;
  static Future<Map<String, dynamic>>? _gradesInFlight;

  static List<dynamic>? _goalsCache;
  static DateTime? _goalsFetchedAt;
  static Future<List<dynamic>>? _goalsInFlight;

  static Map<String, dynamic>? _attendanceCache;
  static DateTime? _attendanceFetchedAt;
  static Future<Map<String, dynamic>>? _attendanceInFlight;

  RealStudentAnalyticsRepository({
    ApiClient? apiClient,
    required StorageService storageService,
  }) : _api = apiClient ?? ApiClient(),
       _storage = storageService;

  @override
  Future<StudentWeeklySnapshot> fetchWeeklySnapshot() async {
    final api = await _safeGetMap('/analytics/student/weekly-snapshot');
    if (api.isNotEmpty) {
      return StudentWeeklySnapshot(
        attendanceRate: _asDouble(api['attendanceRate'], fallback: 0),
        averageQuizScore: _asDouble(api['averageQuizScore'], fallback: 0),
        dueAssignments: _asInt(api['dueAssignments'], fallback: 0),
        trend: (api['trend'] ?? 'flat').toString(),
        focusSubjects: _readList(
          api['focusSubjects'],
        ).map((e) => e.toString()).toList(),
        summary: (api['summary'] ?? '').toString(),
      );
    }

    final dashboard = await _getDashboardData();
    final grades = await _getGradesData();

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
    final api = await _safeGetMap('/analytics/student/performance-trends');
    if (api.isNotEmpty) {
      final subjects = _readList(api['subjects'])
          .whereType<Map<String, dynamic>>()
          .map((raw) {
            final points = _readList(raw['points'])
                .whereType<Map<String, dynamic>>()
                .map(
                  (p) => StudentTrendPoint(
                    label: (p['label'] ?? '').toString(),
                    value: _asDouble(p['value'], fallback: 0),
                  ),
                )
                .toList();
            return StudentSubjectTrend(
              subjectId: (raw['subjectId'] ?? '').toString(),
              subjectName: (raw['subjectName'] ?? 'Subject').toString(),
              points: points,
              strengthTopics: _readList(
                raw['strengthTopics'],
              ).map((e) => e.toString()).toList(),
              riskTopics: _readList(
                raw['riskTopics'],
              ).map((e) => e.toString()).toList(),
              recommendation: (raw['recommendation'] ?? '').toString(),
            );
          })
          .toList();

      return StudentPerformanceTrends(
        examReadinessScore: _asInt(
          api['examReadinessScore'],
          fallback: 0,
        ).clamp(0, 100),
        subjects: subjects,
      );
    }

    final grades = await _getGradesData();
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
    final api = await _safeGetMap('/analytics/student/attendance-insights');
    if (api.isNotEmpty) {
      final weeklyTrend = _readList(api['weeklyTrend'])
          .whereType<Map<String, dynamic>>()
          .map(
            (p) => StudentTrendPoint(
              label: (p['label'] ?? '').toString(),
              value: _asDouble(p['value'], fallback: 0),
            ),
          )
          .toList();

      return StudentAttendanceInsight(
        currentRate: _asDouble(api['currentRate'], fallback: 0),
        weeklyTrend: weeklyTrend,
        riskLevel: (api['riskLevel'] ?? 'High').toString(),
        projectedMonthEndRate: _asDouble(
          api['projectedMonthEndRate'],
          fallback: 0,
        ),
        bestDay: (api['bestDay'] ?? 'N/A').toString(),
        weakDay: (api['weakDay'] ?? 'N/A').toString(),
      );
    }

    final report = await _getAttendanceData();
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
    final api = await _safeGetList('/analytics/student/action-plan');
    if (api.isNotEmpty) {
      return api.whereType<Map<String, dynamic>>().map((raw) {
        return StudentActionItem(
          id: (raw['id'] ?? '').toString(),
          title: (raw['title'] ?? 'Action').toString(),
          reason: (raw['reason'] ?? '').toString(),
          category: (raw['category'] ?? 'study').toString(),
          effortMinutes: _asInt(raw['effortMinutes'], fallback: 20),
          routeName: raw['routeName']?.toString(),
          routeArgs: null,
          done: raw['done'] == true,
        );
      }).toList();
    }

    final goalsRows = await _getGoalsData();
    final dashboard = await _getDashboardData();
    final grades = await _getGradesData();

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

  Future<Map<String, dynamic>> _getDashboardData() async {
    if (_isFresh(_dashboardFetchedAt, _dashboardTtl) &&
        _dashboardCache != null) {
      return _dashboardCache!;
    }

    final inFlight = _dashboardInFlight;
    if (inFlight != null) return inFlight;

    final future = _safeGetMap(ApiConstants.dashboardStudent);
    _dashboardInFlight = future;
    final data = await future;
    _dashboardInFlight = null;
    if (data.isNotEmpty) {
      _dashboardCache = data;
      _dashboardFetchedAt = DateTime.now();
      return data;
    }
    return _dashboardCache ?? const <String, dynamic>{};
  }

  Future<Map<String, dynamic>> _getGradesData() async {
    if (_isFresh(_gradesFetchedAt, _gradesTtl) && _gradesCache != null) {
      return _gradesCache!;
    }

    final inFlight = _gradesInFlight;
    if (inFlight != null) return inFlight;

    final future = _safeGetMap('/reports/my-grades');
    _gradesInFlight = future;
    final data = await future;
    _gradesInFlight = null;
    if (data.isNotEmpty) {
      _gradesCache = data;
      _gradesFetchedAt = DateTime.now();
      return data;
    }
    return _gradesCache ?? const <String, dynamic>{};
  }

  Future<List<dynamic>> _getGoalsData() async {
    if (_isFresh(_goalsFetchedAt, _goalsTtl) && _goalsCache != null) {
      return _goalsCache!;
    }

    final inFlight = _goalsInFlight;
    if (inFlight != null) return inFlight;

    final future = _safeGetList(ApiConstants.myGoals);
    _goalsInFlight = future;
    final data = await future;
    _goalsInFlight = null;
    if (data.isNotEmpty) {
      _goalsCache = data;
      _goalsFetchedAt = DateTime.now();
      return data;
    }
    return _goalsCache ?? const [];
  }

  Future<Map<String, dynamic>> _getAttendanceData() async {
    if (_isFresh(_attendanceFetchedAt, _attendanceTtl) &&
        _attendanceCache != null) {
      return _attendanceCache!;
    }

    final inFlight = _attendanceInFlight;
    if (inFlight != null) return inFlight;

    final studentId = await _resolveStudentId();
    final future = _safeGetMap(ApiConstants.attendanceStudentReport(studentId));
    _attendanceInFlight = future;
    final data = await future;
    _attendanceInFlight = null;
    if (data.isNotEmpty) {
      _attendanceCache = data;
      _attendanceFetchedAt = DateTime.now();
      return data;
    }
    return _attendanceCache ?? const <String, dynamic>{};
  }

  Future<List<dynamic>> _safeGetList(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _api.getList(path, queryParameters: queryParameters);
    } catch (_) {
      return const [];
    }
  }

  Future<Map<String, dynamic>> _safeGetMap(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _api.get(path, queryParameters: queryParameters);
    } catch (_) {
      return const <String, dynamic>{};
    }
  }

  bool _isFresh(DateTime? fetchedAt, Duration ttl) {
    if (fetchedAt == null) return false;
    return DateTime.now().difference(fetchedAt) < ttl;
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

  int _asInt(dynamic value, {required int fallback}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
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
