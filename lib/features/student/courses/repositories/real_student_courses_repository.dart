import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/services/local_cache_service.dart';
import '../models/course_resource_model.dart';
import 'student_courses_repository.dart';

class RealStudentCoursesRepository implements StudentCoursesRepository {
  final ApiClient _api;
  final LocalCacheService _cache;

  static const Duration _ttl = Duration(minutes: 20);

  List<CourseResourceModel>? _resourcesCache;
  DateTime? _resourcesFetchedAt;
  Future<List<CourseResourceModel>>? _resourcesInFlight;

  RealStudentCoursesRepository({
    ApiClient? apiClient,
    required LocalCacheService cacheService,
  }) : _api = apiClient ?? ApiClient(),
       _cache = cacheService;

  @override
  Future<List<CourseResourceModel>> fetchCourseResources() async {
    _restoreCache();
    if (_resourcesCache != null && _resourcesFetchedAt != null) {
      final age = DateTime.now().difference(_resourcesFetchedAt!);
      if (age < _ttl) return _resourcesCache!;
    }

    final inFlight = _resourcesInFlight;
    if (inFlight != null) return inFlight;

    final future = _fetchFresh();
    _resourcesInFlight = future;
    try {
      final data = await future;
      _resourcesCache = data;
      _resourcesFetchedAt = DateTime.now();
      return data;
    } catch (_) {
      if (_resourcesCache != null) return _resourcesCache!;
      rethrow;
    } finally {
      _resourcesInFlight = null;
    }
  }

  @override
  Future<List<CourseResourceModel>> fetchResourcesBySubject(
    String subjectId,
  ) async {
    final all = await fetchCourseResources();
    final normalized = subjectId.trim().toLowerCase();
    return all
        .where((r) => r.subjectId.trim().toLowerCase() == normalized)
        .toList();
  }

  @override
  Future<CourseResourceModel?> fetchResourceById(String resourceId) async {
    final all = await fetchCourseResources();
    for (final resource in all) {
      if (resource.id == resourceId) return resource;
    }
    return null;
  }

  Future<List<CourseResourceModel>> _fetchFresh() async {
    final rows = await _api.getList(ApiConstants.courseResources);
    final resources = rows
        .whereType<Map<String, dynamic>>()
        .map((json) => CourseResourceModel.fromJson(json))
        .toList();
    await _cache.write(
      _cacheKey,
      resources.map((item) => item.toJson()).toList(),
    );
    return resources;
  }

  static const String _cacheKey = 'student_course_resources_v1';

  void _restoreCache() {
    if (_resourcesCache != null) return;
    final entry = _cache.read(_cacheKey);
    if (entry == null) return;
    final raw = entry.data;
    if (raw is! List) return;
    _resourcesCache = raw
        .whereType<Map<String, dynamic>>()
        .map((json) => CourseResourceModel.fromJson(json))
        .toList();
    _resourcesFetchedAt = entry.savedAt;
  }

  @override
  List<CourseResourceModel>? getCached() => _resourcesCache;

  @override
  void clearCache() {
    _resourcesCache = null;
    _resourcesFetchedAt = null;
    _resourcesInFlight = null;
  }

}
