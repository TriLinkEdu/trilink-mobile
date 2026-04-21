import '../models/course_resource_model.dart';
import 'student_courses_repository.dart';

class RealStudentCoursesRepository implements StudentCoursesRepository {
  final StudentCoursesRepository _fallback;

  static const Duration _ttl = Duration(seconds: 30);

  static List<CourseResourceModel>? _resourcesCache;
  static DateTime? _resourcesFetchedAt;
  static Future<List<CourseResourceModel>>? _resourcesInFlight;

  RealStudentCoursesRepository({required StudentCoursesRepository fallback})
    : _fallback = fallback;

  @override
  Future<List<CourseResourceModel>> fetchCourseResources() async {
    if (_resourcesCache != null && _resourcesFetchedAt != null) {
      final age = DateTime.now().difference(_resourcesFetchedAt!);
      if (age < _ttl) return _resourcesCache!;
    }

    final inFlight = _resourcesInFlight;
    if (inFlight != null) return inFlight;

    final future = _fallback.fetchCourseResources();
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
    return all.where((r) => r.subjectId == subjectId).toList();
  }

  @override
  Future<CourseResourceModel?> fetchResourceById(String resourceId) async {
    final all = await fetchCourseResources();
    for (final resource in all) {
      if (resource.id == resourceId) return resource;
    }
    return null;
  }
}
