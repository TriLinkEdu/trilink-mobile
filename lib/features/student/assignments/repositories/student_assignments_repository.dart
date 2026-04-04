import '../models/assignment_model.dart';

abstract class StudentAssignmentsRepository {
  Future<List<AssignmentModel>> fetchAssignments();
  Future<AssignmentModel> fetchAssignmentById(String id);
  Future<void> submitAssignment(String id, String content);
}
