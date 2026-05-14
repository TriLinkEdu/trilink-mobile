import '../models/assignment_model.dart';

abstract class StudentAssignmentsRepository {
  Future<List<AssignmentModel>> fetchAssignments();
  Future<AssignmentModel> fetchAssignmentById(String id);

  /// Submit text-only assignment content.
  Future<void> submitAssignment(String id, String content);

  /// Submit with an optional file attachment (file path on device).
  Future<void> submitAssignmentWithFile(
    String id,
    String content, {
    String? filePath,
  });

  /// Force-bust the in-memory cache and return fresh data.
  Future<List<AssignmentModel>> refresh();
  List<AssignmentModel>? getCached() => null;
  void clearCache() {}
}
