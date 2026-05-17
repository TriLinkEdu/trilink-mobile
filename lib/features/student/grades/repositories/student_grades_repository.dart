import '../models/grade_model.dart';

abstract class StudentGradesRepository {
  /// Fetch all released grades, optionally filtered by [term].
  Future<List<GradeModel>> fetchGrades({String? term});

  /// Fetch released grades for a single subject.
  Future<List<GradeModel>> fetchGradesBySubject(String subjectId);

  /// Return all distinct term strings present in the student's grade data,
  /// sorted most-recent first. Used to populate the term selector.
  Future<List<String>> fetchAvailableTerms();
  List<GradeModel>? getCached() => null;
  void clearCache() {}
}
