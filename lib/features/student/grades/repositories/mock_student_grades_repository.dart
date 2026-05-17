import '../models/grade_model.dart';
import 'student_grades_repository.dart';

class MockStudentGradesRepository implements StudentGradesRepository {
  static const Duration _latency = Duration(milliseconds: 350);

  static final List<GradeModel> _grades = [
    GradeModel(
      id: 'g1',
      subjectId: 'mathematics',
      subjectName: 'Mathematics',
      assessmentName: 'Quiz 1',
      score: 92,
      maxScore: 100,
      date: DateTime(2023, 9, 12),
      term: 'Fall 2023',
    ),
    GradeModel(
      id: 'g2',
      subjectId: 'mathematics',
      subjectName: 'Mathematics',
      assessmentName: 'Assignment 1',
      score: 96,
      maxScore: 100,
      date: DateTime(2023, 9, 24),
      term: 'Fall 2023',
    ),
    GradeModel(
      id: 'g3',
      subjectId: 'physics',
      subjectName: 'Physics',
      assessmentName: 'Lab 1',
      score: 85,
      maxScore: 100,
      date: DateTime(2023, 9, 15),
      term: 'Fall 2023',
    ),
    GradeModel(
      id: 'g4',
      subjectId: 'physics',
      subjectName: 'Physics',
      assessmentName: 'Quiz 2',
      score: 84,
      maxScore: 100,
      date: DateTime(2023, 10, 5),
      term: 'Fall 2023',
    ),
    GradeModel(
      id: 'g5',
      subjectId: 'literature',
      subjectName: 'Literature',
      assessmentName: 'Essay 1',
      score: 88,
      maxScore: 100,
      date: DateTime(2023, 9, 18),
      term: 'Fall 2023',
    ),
    GradeModel(
      id: 'g6',
      subjectId: 'literature',
      subjectName: 'Literature',
      assessmentName: 'Essay 2',
      score: 88,
      maxScore: 100,
      date: DateTime(2023, 10, 6),
      term: 'Fall 2023',
    ),
    GradeModel(
      id: 'g7',
      subjectId: 'history',
      subjectName: 'History',
      assessmentName: 'Midterm',
      score: 79,
      maxScore: 100,
      date: DateTime(2023, 10, 2),
      term: 'Fall 2023',
    ),
    GradeModel(
      id: 'g8',
      subjectId: 'computer-science',
      subjectName: 'Computer Science',
      assessmentName: 'Project 1',
      score: 95,
      maxScore: 100,
      date: DateTime(2023, 10, 8),
      term: 'Fall 2023',
    ),
    GradeModel(
      id: 'g9',
      subjectId: 'mathematics',
      subjectName: 'Mathematics',
      assessmentName: 'Midterm',
      score: 88,
      maxScore: 100,
      date: DateTime(2023, 3, 15),
      term: 'Spring 2023',
    ),
    GradeModel(
      id: 'g10',
      subjectId: 'physics',
      subjectName: 'Physics',
      assessmentName: 'Lab Report',
      score: 82,
      maxScore: 100,
      date: DateTime(2023, 4, 10),
      term: 'Spring 2023',
    ),
    GradeModel(
      id: 'g11',
      subjectId: 'literature',
      subjectName: 'Literature',
      assessmentName: 'Book Review',
      score: 91,
      maxScore: 100,
      date: DateTime(2023, 3, 22),
      term: 'Spring 2023',
    ),
    GradeModel(
      id: 'g12',
      subjectId: 'history',
      subjectName: 'History',
      assessmentName: 'Research Paper',
      score: 85,
      maxScore: 100,
      date: DateTime(2023, 4, 5),
      term: 'Spring 2023',
    ),
  ];

  @override
  Future<List<GradeModel>> fetchGrades({String? term}) async {
    await Future<void>.delayed(_latency);
    if (term == null) return List<GradeModel>.from(_grades);
    return _grades.where((g) => g.term == term).toList();
  }

  @override
  Future<List<GradeModel>> fetchGradesBySubject(String subjectId) async {
    await Future<void>.delayed(_latency);
    return _grades.where((grade) => grade.subjectId == subjectId).toList();
  }

  @override
  Future<List<String>> fetchAvailableTerms() async {
    await Future<void>.delayed(_latency);
    final seen = <String>{};
    final terms = <String>[];
    // Sort grades newest-first so most recent term appears first
    final sorted = List<GradeModel>.from(_grades)
      ..sort((a, b) => b.date.compareTo(a.date));
    for (final g in sorted) {
      final t = g.term;
      if (t != null && seen.add(t)) terms.add(t);
    }
    return terms;
  }

  @override
  List<GradeModel>? getCached() => null;

  @override
  void clearCache() {}
}
