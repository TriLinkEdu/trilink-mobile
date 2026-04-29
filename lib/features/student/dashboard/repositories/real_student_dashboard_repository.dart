import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/storage_service.dart';
import '../../shared/repositories/student_progress_repository.dart';
import '../models/dashboard_data_model.dart';
import 'student_dashboard_repository.dart';

class RealStudentDashboardRepository implements StudentDashboardRepository {
  final ApiClient _api;
  final StudentProgressRepository _progressRepository;
  final StorageService _storage;

  static DashboardDataModel? _cache;
  static DateTime? _fetchedAt;
  static Future<DashboardDataModel>? _inFlight;
  static const Duration _ttl = Duration(seconds: 30);

  RealStudentDashboardRepository({
    ApiClient? apiClient,
    required StudentProgressRepository progressRepository,
    required StorageService storageService,
  }) : _api = apiClient ?? ApiClient(),
       _progressRepository = progressRepository,
       _storage = storageService;

  @override
  Future<DashboardDataModel> fetchDashboardData() async {
    if (_cache != null && _fetchedAt != null) {
      final age = DateTime.now().difference(_fetchedAt!);
      if (age < _ttl) return _cache!;
    }

    if (_inFlight != null) return _inFlight!;

    final future = _fetchFresh();
    _inFlight = future;
    final data = await future;
    _inFlight = null;
    _cache = data;
    _fetchedAt = DateTime.now();
    return data;
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
    final createdAt = DateTime.tryParse((raw['createdAt'] ?? '').toString());
    if (createdAt == null) return null;
    return DashboardAnnouncementSnippet(
      id: (raw['id'] ?? '').toString(),
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
}
