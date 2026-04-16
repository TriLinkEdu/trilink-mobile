import '../../../../core/network/api_client.dart';
import '../models/grade_model.dart';
import 'student_grades_repository.dart';

class RealStudentGradesRepository implements StudentGradesRepository {
  final ApiClient _api;

  RealStudentGradesRepository({ApiClient? apiClient})
    : _api = apiClient ?? ApiClient();

  @override
  Future<List<GradeModel>> fetchGrades({String? term}) async {
    final data = await _api.get('/reports/my-grades');
    final subjects = data['subjects'];
    if (subjects is! List) return const [];

    final grades = <GradeModel>[];
    for (final subject in subjects.whereType<Map<String, dynamic>>()) {
      final subjectId = (subject['subjectId'] ?? '').toString();
      final subjectName = (subject['subjectName'] ?? 'Subject').toString();
      final exams = subject['exams'];
      if (exams is! List) continue;

      for (final exam in exams.whereType<Map<String, dynamic>>()) {
        final model = _toGrade(
          subjectId: subjectId,
          subjectName: subjectName,
          raw: exam,
        );
        if (term == null || model.term == term) {
          grades.add(model);
        }
      }
    }

    grades.sort((a, b) => b.date.compareTo(a.date));
    return grades;
  }

  @override
  Future<List<GradeModel>> fetchGradesBySubject(String subjectId) async {
    final all = await fetchGrades();
    return all.where((grade) => grade.subjectId == subjectId).toList();
  }

  GradeModel _toGrade({
    required String subjectId,
    required String subjectName,
    required Map<String, dynamic> raw,
  }) {
    final releasedAt = (raw['releasedAt'] ?? '').toString();
    final score = _readDouble(raw['score']);
    final maxScore = _readDouble(raw['maxPoints'], fallback: 100);
    final date = DateTime.tryParse(releasedAt) ?? DateTime.now();

    return GradeModel(
      id: (raw['attemptId'] ?? raw['examId'] ?? '').toString(),
      subjectId: subjectId,
      subjectName: subjectName,
      assessmentName: (raw['title'] ?? 'Assessment').toString(),
      score: score,
      maxScore: maxScore <= 0 ? 100 : maxScore,
      date: date,
      term: _termFromDate(date),
    );
  }

  double _readDouble(dynamic value, {double fallback = 0}) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? fallback;
  }

  String _termFromDate(DateTime date) {
    if (date.month >= 9 || date.month <= 1) {
      return 'Fall ${date.year}';
    }
    return 'Spring ${date.year}';
  }
}
