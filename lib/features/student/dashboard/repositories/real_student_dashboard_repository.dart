import 'dart:convert';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/local_cache_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../shared/repositories/student_progress_repository.dart';
import '../models/dashboard_data_model.dart';
import 'student_dashboard_repository.dart';

class RealStudentDashboardRepository implements StudentDashboardRepository {
  final ApiClient _api;
  final StudentProgressRepository _progressRepository;
  final StorageService _storage;
  final LocalCacheService _cacheService;

  DashboardDataModel? _cache;
  DateTime? _fetchedAt;
  Future<DashboardDataModel>? _inFlight;
  static const Duration _ttl = Duration(minutes: 10);

  RealStudentDashboardRepository({
    ApiClient? apiClient,
    required StudentProgressRepository progressRepository,
    required StorageService storageService,
    required LocalCacheService cacheService,
  }) : _api = apiClient ?? ApiClient(),
       _progressRepository = progressRepository,
       _storage = storageService,
       _cacheService = cacheService;

  @override
  Future<DashboardDataModel> fetchDashboardData() async {
    final userId = await _currentUserId();
    _restoreCache(userId);
    if (_cache != null && _fetchedAt != null) {
      final age = DateTime.now().difference(_fetchedAt!);
      if (age < _ttl) return _cache!;
    }

    if (_inFlight != null) return _inFlight!;

    final future = _fetchFresh();
    _inFlight = future;
    try {
      final data = await future;
      _cache = data;
      _fetchedAt = DateTime.now();
      await _cacheService.write(_cacheKey(userId), data.toJson());
      return data;
    } catch (_) {
      if (_cache != null) return _cache!;
      rethrow;
    } finally {
      _inFlight = null;
    }
  }

  Future<DashboardDataModel> _fetchFresh() async {
    final json = await _api.get(ApiConstants.dashboardStudent);
    final progress = await _progressRepository.fetchProgress();

    final attendance = _readDouble(
      (json['attendanceSummaryLast30Days']
          as Map<String, dynamic>?)?['presentOrLateRate'],
      fallback: 0,
    );

    final upcoming = _readList(json['upcomingExams']);
    final nextUp = upcoming.isEmpty ? null : _toNextUp(upcoming.first);

    final notifications = _readList(json['recentNotifications']);
    final recentAnnouncements = notifications
        .map(_toAnnouncement)
        .whereType<DashboardAnnouncementSnippet>()
        .toList();

    final user = await _storage.getUser();
    final levelTitle = _resolveLevelTitle(user);

    return DashboardDataModel(
      stats: DashboardStatsModel(
        streakDays: progress.currentStreak,
        totalXp: progress.totalXp,
        level: progress.level,
        levelTitle: levelTitle,
        attendancePercent: attendance,
      ),
      nextUp: nextUp,
      recentAnnouncements: recentAnnouncements,
      recentGradeHighlight: null,
    );
  }

  NextUpItemModel _toNextUp(Map<String, dynamic> raw) {
    final classOfferingId = (raw['classOfferingId'] ?? '').toString();
    return NextUpItemModel(
      id: (raw['id'] ?? '').toString(),
      title: (raw['title'] ?? 'Upcoming exam').toString(),
      subtitle: 'Prepare before the exam window closes',
      type: 'exam',
      subjectId: classOfferingId,
      subjectName: 'Class',
      dueAt:
          DateTime.tryParse((raw['opensAt'] ?? '').toString()) ??
          DateTime.now(),
      participantCount: 0,
    );
  }

  DashboardAnnouncementSnippet? _toAnnouncement(Map<String, dynamic> raw) {
    if (raw['type'] != 'announcement') return null;
    
    final createdAt = DateTime.tryParse((raw['createdAt'] ?? '').toString());
    if (createdAt == null) return null;
    
    String id = (raw['id'] ?? '').toString();
    final payloadJsonStr = raw['payloadJson'];
    if (payloadJsonStr is String && payloadJsonStr.isNotEmpty) {
      try {
        final payload = jsonDecode(payloadJsonStr) as Map<String, dynamic>;
        if (payload['announcementId'] != null) {
          id = payload['announcementId'].toString();
        }
      } catch (_) {}
    }

    return DashboardAnnouncementSnippet(
      id: id,
      title: (raw['title'] ?? 'Notification').toString(),
      authorName: 'TriLink',
      snippet: (raw['body'] ?? '').toString(),
      createdAt: createdAt,
    );
  }

  List<Map<String, dynamic>> _readList(dynamic value) {
    if (value is! List) return const [];
    return value.whereType<Map<String, dynamic>>().toList();
  }

  double _readDouble(dynamic value, {required double fallback}) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? fallback;
  }

  String _resolveLevelTitle(Map<String, dynamic>? user) {
    final grade = (user?['grade'] ?? '').toString().trim();
    if (grade.isNotEmpty) return grade;
    return 'Student';
  }

  Future<String> _currentUserId() async {
    final user = await _storage.getUser();
    return (user?['id'] ?? '').toString();
  }

  String _cacheKey(String userId) =>
      userId.isEmpty ? 'student_dashboard_v2' : 'student_dashboard_v2_$userId';

  @override
  DashboardDataModel? getCached() => _cache;

  @override
  void clearCache() {
    _cache = null;
    _fetchedAt = null;
    _inFlight = null;
  }

  void _restoreCache(String userId) {
    if (_cache != null) return;
    final entry = _cacheService.read(_cacheKey(userId));
    if (entry == null || entry.data is! Map<String, dynamic>) return;
    _cache = DashboardDataModel.fromJson(
      Map<String, dynamic>.from(entry.data as Map),
    );
    _fetchedAt = entry.savedAt;
  }
}
