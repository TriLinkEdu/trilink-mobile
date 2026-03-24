import '../models/grade_model.dart';

abstract class StudentGradesRepository {
  Future<List<GradeModel>> fetchGrades();
  Future<List<GradeModel>> fetchGradesBySubject(String subjectId);
}
