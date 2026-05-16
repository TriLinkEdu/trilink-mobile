import '../../../../core/constants/api_constants.dart';
import '../../../../core/models/performance_report_model.dart';
import '../../../../core/models/student_goal_model.dart';
import '../../../../core/models/topic_mastery_model.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/local_cache_service.dart';
import '../../../../core/services/storage_service.dart';
import 'student_performance_repository.dart';

class RealStudentPerformanceRepository implements StudentPerformanceRepository {
  final ApiClient _api;
  final StorageService _storage;
  final LocalCacheService _cacheService;

  static const Duration _goalsTtl = Duration(minutes: 30);
  static const Duration _reportTtl = Duration(hours: 1);

  List<StudentGoalModel>? _goalsCache;
  DateTime? _goalsFetchedAt;
  Future<List<StudentGoalModel>>? _goalsInFlight;

  final Map<String, PerformanceReportModel> _reportCache =
      <String, PerformanceReportModel>{};
  final Map<String, DateTime> _reportFetchedAt = <String, DateTime>{};
  final Map<String, Future<PerformanceReportModel>> _reportInFlight =
      <String, Future<PerformanceReportModel>>{};

  RealStudentPerformanceRepository({
    ApiClient? apiClient,
    required StorageService storageService,
    required LocalCacheService cacheService,
  }) : _api = apiClient ?? ApiClient(),
       _storage = storageService,
       _cacheService = cacheService;

  @override
  Future<List<TopicMasteryModel>> fetchMasteryLevels(String studentId) async {
    final rows = await _api.getList(ApiConstants.studentMastery(studentId));
    return rows.whereType<Map<String, dynamic>>().map((raw) {
      return TopicMasteryModel(
        studentId: (raw['studentId'] ?? studentId).toString(),
        topicId: (raw['topicId'] ?? '').toString(),
        topicName: (raw['topicName'] ?? 'Topic').toString(),
        subjectId: (raw['subjectId'] ?? '').toString(),
        masteryLevel: _asDouble(raw['masteryLevel'], fallback: 0),
        lastAssessed:
            DateTime.tryParse((raw['lastAssessed'] ?? '').toString()) ??
            DateTime.now(),
      );
    }).toList();
  }

  @override
  Future<List<StudentGoalModel>> fetchGoals(String studentId) async {
    final resolvedId = await _resolveStudentId(studentId);
    _restoreGoalsCache(resolvedId);
    if (_goalsCache != null && _goalsFetchedAt != null) {
      final age = DateTime.now().difference(_goalsFetchedAt!);
      if (age < _goalsTtl) return _goalsCache!;
    }

    final inFlight = _goalsInFlight;
    if (inFlight != null) return inFlight;

    final future = _fetchGoalsFresh();
    _goalsInFlight = future;
    try {
      final data = await future;
      _goalsCache = data;
      _goalsFetchedAt = DateTime.now();
      await _cacheService.write(
        _goalsCacheKey(resolvedId),
        data.map((item) => item.toJson()).toList(),
      );
      return data;
    } catch (_) {
      if (_goalsCache != null) return _goalsCache!;
      rethrow;
    } finally {
      _goalsInFlight = null;
    }
  }

  Future<List<StudentGoalModel>> _fetchGoalsFresh() async {
    final rows = await _api.getList(ApiConstants.myGoals);
    return rows.whereType<Map<String, dynamic>>().map(_mapGoal).toList();
  }

  @override
  Future<StudentGoalModel> createGoal(StudentGoalModel goal) async {
    final title = goal.goalText.trim();
    final raw = await _api.post(
      ApiConstants.myGoals,
      data: {
        'title': title,
        'description': title,
        if (goal.targetDate != null)
          'targetDate': goal.targetDate!.toIso8601String().split('T').first,
      },
    );
    _goalsFetchedAt = null;
    return _mapGoal(raw, fallbackStudentId: goal.studentId);
  }

  @override
  Future<StudentGoalModel> updateGoal(StudentGoalModel goal) async {
    final title = goal.goalText.trim();
    final raw = await _api.patch(
      ApiConstants.goalById(goal.id),
      data: {
        'title': title,
        'description': title,
        'status': goal.isAchieved ? 'completed' : 'active',
        if (goal.targetDate != null)
          'targetDate': goal.targetDate!.toIso8601String().split('T').first,
      },
    );
    _goalsFetchedAt = null;
    return _mapGoal(raw, fallbackStudentId: goal.studentId);
  }

  @override
  Future<PerformanceReportModel> fetchLatestReport(String studentId) async {
    final resolvedId = await _resolveStudentId(studentId);
    _restoreReportCache(resolvedId);
    final fetchedAt = _reportFetchedAt[resolvedId];
    final cached = _reportCache[resolvedId];
    if (cached != null && fetchedAt != null) {
      final age = DateTime.now().difference(fetchedAt);
      if (age < _reportTtl) return cached;
    }

    final inFlight = _reportInFlight[resolvedId];
    if (inFlight != null) return inFlight;

    final future = _fetchLatestReportFresh(resolvedId);
    _reportInFlight[resolvedId] = future;
    try {
      final data = await future;
      _reportCache[resolvedId] = data;
      _reportFetchedAt[resolvedId] = DateTime.now();
      await _cacheService.write(
        _reportCacheKey(resolvedId),
        data.toJson(),
      );
      return data;
    } catch (_) {
      if (cached != null) return cached;
      rethrow;
    } finally {
      _reportInFlight.remove(resolvedId);
    }
  }

  Future<PerformanceReportModel> _fetchLatestReportFresh(
    String studentId,
  ) async {
    final raw = await _api.get(
      ApiConstants.studentReport(studentId),
      queryParameters: {'periodType': 'weekly'},
    );
    final summary = raw['summary'] as Map<String, dynamic>?;
    final courses = raw['courses'] as List<dynamic>?;

    final strengths = <String>[];
    final weaknesses = <String>[];
    final recommendations = <String>[];

    if (summary != null) {
      final attendance = summary['overallAttendancePercent'];
      final subjects = summary['overallSubjectsAveragePercent'];

      if (attendance is num && attendance >= 85) {
        strengths.add('Excellent attendance consistency');
      } else {
        weaknesses.add('Attendance needs consistency');
      }

      if (subjects is num && subjects >= 75) {
        strengths.add('Strong subject average performance');
      } else {
        weaknesses.add('Subject average below target threshold');
      }
    }

    if (courses != null && courses.isNotEmpty) {
      recommendations.add('Focus on lowest-performing subject this week');
      recommendations.add('Review recent assessment feedback before next exam');
    } else {
      recommendations.add(
        'Complete more assessed coursework to unlock trend insights',
      );
    }

    return PerformanceReportModel(
      id: (raw['studentId'] ?? studentId).toString(),
      studentId: (raw['studentId'] ?? studentId).toString(),
      overallScore: _asDouble(
        summary?['overallSubjectsAveragePercent'],
        fallback: 0,
      ),
      strengths: strengths,
      weaknesses: weaknesses,
      recommendations: recommendations,
      generatedAt:
          DateTime.tryParse((raw['generatedAt'] ?? '').toString()) ??
          DateTime.now(),
    );
  }

  StudentGoalModel _mapGoal(
    Map<String, dynamic> raw, {
    String? fallbackStudentId,
  }) {
    final status = (raw['status'] ?? 'active').toString().toLowerCase();
    return StudentGoalModel(
      id: (raw['id'] ?? '').toString(),
      studentId: (raw['studentId'] ?? fallbackStudentId ?? '').toString(),
      goalText: (raw['title'] ?? raw['description'] ?? '').toString(),
      targetDate: DateTime.tryParse((raw['targetDate'] ?? '').toString()),
      isAchieved:
          status == 'completed' || status == 'done' || status == 'closed',
      createdAt:
          DateTime.tryParse((raw['createdAt'] ?? '').toString()) ??
          DateTime.now(),
    );
  }

  double _asDouble(dynamic value, {required double fallback}) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? fallback;
  }

  Future<String> _resolveStudentId(String studentId) async {
    if (studentId.isNotEmpty) return studentId;
    final user = await _storage.getUser();
    return (user?['id'] ?? '').toString();
  }

  String _goalsCacheKey(String studentId) => studentId.isEmpty
      ? 'student_goals_v1'
      : 'student_goals_v1_$studentId';

  String _reportCacheKey(String studentId) => studentId.isEmpty
      ? 'student_performance_report_v1'
      : 'student_performance_report_v1_$studentId';

  void _restoreGoalsCache(String studentId) {
    if (_goalsCache != null) return;
    final entry = _cacheService.read(_goalsCacheKey(studentId));
    if (entry == null || entry.data is! List) return;
    _goalsCache = (entry.data as List)
        .whereType<Map<String, dynamic>>()
        .map(StudentGoalModel.fromJson)
        .toList();
    _goalsFetchedAt = entry.savedAt;
  }

  void _restoreReportCache(String studentId) {
    if (_reportCache.containsKey(studentId)) return;
    final entry = _cacheService.read(_reportCacheKey(studentId));
    if (entry == null || entry.data is! Map<String, dynamic>) return;
    _reportCache[studentId] = PerformanceReportModel.fromJson(
      Map<String, dynamic>.from(entry.data as Map),
    );
    _reportFetchedAt[studentId] = entry.savedAt;
  }

  @override
  List<StudentGoalModel>? getCached() => _goalsCache;

  @override
  void clearCache() {
    _goalsCache = null;
    _goalsFetchedAt = null;
    _goalsInFlight = null;
    _reportCache.clear();
    _reportFetchedAt.clear();
    _reportInFlight.clear();
  }
}
