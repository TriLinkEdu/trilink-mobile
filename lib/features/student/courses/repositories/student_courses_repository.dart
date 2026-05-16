import '../models/course_resource_model.dart';

abstract class StudentCoursesRepository {
  Future<List<CourseResourceModel>> fetchCourseResources();
  Future<List<CourseResourceModel>> fetchResourcesBySubject(String subjectId);
  Future<CourseResourceModel?> fetchResourceById(String resourceId);

  List<CourseResourceModel>? getCached() => null;
  void clearCache() {}
}
