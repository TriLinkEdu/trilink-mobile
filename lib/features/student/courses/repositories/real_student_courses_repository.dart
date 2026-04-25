import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/course_resource_model.dart';
import 'student_courses_repository.dart';

class RealStudentCoursesRepository implements StudentCoursesRepository {
  final ApiClient _api;
  final StudentCoursesRepository _fallback;

  static const Duration _ttl = Duration(seconds: 30);

  static List<CourseResourceModel>? _resourcesCache;
  static DateTime? _resourcesFetchedAt;
  static Future<List<CourseResourceModel>>? _resourcesInFlight;

  RealStudentCoursesRepository({
    ApiClient? apiClient,
    required StudentCoursesRepository fallback,
  }) : _api = apiClient ?? ApiClient(),
       _fallback = fallback;

  @override
  Future<List<CourseResourceModel>> fetchCourseResources() async {
    if (_resourcesCache != null && _resourcesFetchedAt != null) {
      final age = DateTime.now().difference(_resourcesFetchedAt!);
      if (age < _ttl) return _resourcesCache!;
    }

    final inFlight = _resourcesInFlight;
    if (inFlight != null) return inFlight;

    final future = _fetchFresh();
    _resourcesInFlight = future;
    final data = await future;
    _resourcesInFlight = null;
    _resourcesCache = data;
    _resourcesFetchedAt = DateTime.now();
    return data;
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
    try {
      final rows = await _api.getList(ApiConstants.courseResources);
      if (rows.isEmpty) return _fallback.fetchCourseResources();
      
      return rows
          .whereType<Map<String, dynamic>>()
          .map((json) => CourseResourceModel.fromJson(json))
          .toList();
    } catch (_) {
      return _fallback.fetchCourseResources();
    }
  }

}
