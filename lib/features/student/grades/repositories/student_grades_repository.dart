import '../models/grade_model.dart';

abstract class StudentGradesRepository {
  Future<List<GradeModel>> fetchGrades({String? term});
  Future<List<GradeModel>> fetchGradesBySubject(String subjectId);
}
