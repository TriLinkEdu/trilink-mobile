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
    ),
    GradeModel(
      id: 'g2',
      subjectId: 'mathematics',
      subjectName: 'Mathematics',
      assessmentName: 'Assignment 1',
      score: 96,
      maxScore: 100,
      date: DateTime(2023, 9, 24),
    ),
    GradeModel(
      id: 'g3',
      subjectId: 'physics',
      subjectName: 'Physics',
      assessmentName: 'Lab 1',
      score: 85,
      maxScore: 100,
      date: DateTime(2023, 9, 15),
    ),
    GradeModel(
      id: 'g4',
      subjectId: 'physics',
      subjectName: 'Physics',
      assessmentName: 'Quiz 2',
      score: 84,
      maxScore: 100,
      date: DateTime(2023, 10, 5),
    ),
    GradeModel(
      id: 'g5',
      subjectId: 'literature',
      subjectName: 'Literature',
      assessmentName: 'Essay 1',
      score: 88,
      maxScore: 100,
      date: DateTime(2023, 9, 18),
    ),
    GradeModel(
      id: 'g6',
      subjectId: 'literature',
      subjectName: 'Literature',
      assessmentName: 'Essay 2',
      score: 88,
      maxScore: 100,
      date: DateTime(2023, 10, 6),
    ),
    GradeModel(
      id: 'g7',
      subjectId: 'history',
      subjectName: 'History',
      assessmentName: 'Midterm',
      score: 79,
      maxScore: 100,
      date: DateTime(2023, 10, 2),
    ),
    GradeModel(
      id: 'g8',
      subjectId: 'computer-science',
      subjectName: 'Computer Science',
      assessmentName: 'Project 1',
      score: 95,
      maxScore: 100,
      date: DateTime(2023, 10, 8),
    ),
  ];

  @override
  Future<List<GradeModel>> fetchGrades() async {
    await Future<void>.delayed(_latency);
    return List<GradeModel>.from(_grades);
  }

  @override
  Future<List<GradeModel>> fetchGradesBySubject(String subjectId) async {
    await Future<void>.delayed(_latency);
    return _grades.where((grade) => grade.subjectId == subjectId).toList();
  }
}
