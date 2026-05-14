import '../../../../core/models/performance_report_model.dart';
import '../../../../core/models/student_goal_model.dart';
import '../../../../core/models/topic_mastery_model.dart';
import 'student_performance_repository.dart';

class MockStudentPerformanceRepository implements StudentPerformanceRepository {
  static const Duration _latency = Duration(milliseconds: 350);
  static const String _demoStudentId = 'student1';

  static final List<TopicMasteryModel> _mastery = [
    TopicMasteryModel(
      studentId: _demoStudentId,
      topicId: 'math-algebra',
      topicName: 'Algebra',
      subjectId: 'mathematics',
      masteryLevel: 0.85,
      lastAssessed: DateTime(2026, 2, 10),
    ),
    TopicMasteryModel(
      studentId: _demoStudentId,
      topicId: 'math-calculus',
      topicName: 'Calculus',
      subjectId: 'mathematics',
      masteryLevel: 0.62,
      lastAssessed: DateTime(2026, 2, 8),
    ),
    TopicMasteryModel(
      studentId: _demoStudentId,
      topicId: 'phy-mechanics',
      topicName: 'Mechanics',
      subjectId: 'physics',
      masteryLevel: 0.78,
      lastAssessed: DateTime(2026, 2, 5),
    ),
    TopicMasteryModel(
      studentId: _demoStudentId,
      topicId: 'phy-thermo',
      topicName: 'Thermodynamics',
      subjectId: 'physics',
      masteryLevel: 0.45,
      lastAssessed: DateTime(2026, 1, 28),
    ),
    TopicMasteryModel(
      studentId: _demoStudentId,
      topicId: 'lit-poetry',
      topicName: 'Poetry',
      subjectId: 'literature',
      masteryLevel: 0.91,
      lastAssessed: DateTime(2026, 2, 12),
    ),
    TopicMasteryModel(
      studentId: _demoStudentId,
      topicId: 'hist-modern',
      topicName: 'Modern World History',
      subjectId: 'history',
      masteryLevel: 0.55,
      lastAssessed: DateTime(2026, 2, 1),
    ),
    TopicMasteryModel(
      studentId: _demoStudentId,
      topicId: 'cs-ds',
      topicName: 'Data Structures',
      subjectId: 'computer_science',
      masteryLevel: 0.72,
      lastAssessed: DateTime(2026, 2, 11),
    ),
    TopicMasteryModel(
      studentId: _demoStudentId,
      topicId: 'cs-algo',
      topicName: 'Algorithms',
      subjectId: 'computer_science',
      masteryLevel: 0.38,
      lastAssessed: DateTime(2026, 1, 22),
    ),
    TopicMasteryModel(
      studentId: _demoStudentId,
      topicId: 'math-geometry',
      topicName: 'Geometry',
      subjectId: 'mathematics',
      masteryLevel: 0.88,
      lastAssessed: DateTime(2026, 2, 9),
    ),
  ];

  static final List<StudentGoalModel> _goals = [
    StudentGoalModel(
      id: 'goal-1',
      studentId: _demoStudentId,
      goalText: 'Raise calculus quiz average to 85% before midterm',
      targetDate: DateTime(2026, 4, 15),
      isAchieved: false,
      createdAt: DateTime(2026, 1, 5),
    ),
    StudentGoalModel(
      id: 'goal-2',
      studentId: _demoStudentId,
      goalText: 'Complete all physics lab reports with full documentation',
      targetDate: DateTime(2026, 3, 30),
      isAchieved: false,
      createdAt: DateTime(2026, 1, 12),
    ),
    StudentGoalModel(
      id: 'goal-3',
      studentId: _demoStudentId,
      goalText: 'Read three assigned novels for literature seminar',
      targetDate: DateTime(2026, 5, 1),
      isAchieved: false,
      createdAt: DateTime(2026, 2, 1),
    ),
    StudentGoalModel(
      id: 'goal-4',
      studentId: _demoStudentId,
      goalText: 'Score at least 90% on the next history unit test',
      targetDate: DateTime(2026, 3, 20),
      isAchieved: true,
      createdAt: DateTime(2025, 11, 10),
    ),
  ];

  static final PerformanceReportModel _report = PerformanceReportModel(
    id: 'report-latest',
    studentId: _demoStudentId,
    overallScore: 78.5,
    strengths: const ['Strong analytical skills'],
    weaknesses: const ['Time management during exams'],
    recommendations: const ['Practice timed problem sets'],
    generatedAt: DateTime(2026, 2, 14, 9, 30),
  );

  @override
  Future<List<TopicMasteryModel>> fetchMasteryLevels(String studentId) async {
    await Future<void>.delayed(_latency);
    if (studentId != _demoStudentId) return [];
    return List<TopicMasteryModel>.from(_mastery);
  }

  @override
  Future<List<StudentGoalModel>> fetchGoals(String studentId) async {
    await Future<void>.delayed(_latency);
    if (studentId != _demoStudentId) return [];
    return List<StudentGoalModel>.from(_goals);
  }

  @override
  Future<StudentGoalModel> createGoal(StudentGoalModel goal) async {
    await Future<void>.delayed(_latency);
    _goals.add(goal);
    return goal;
  }

  @override
  Future<StudentGoalModel> updateGoal(StudentGoalModel goal) async {
    await Future<void>.delayed(_latency);
    final i = _goals.indexWhere((g) => g.id == goal.id);
    if (i >= 0) {
      _goals[i] = goal;
    }
    return goal;
  }

  @override
  Future<PerformanceReportModel> fetchLatestReport(String studentId) async {
    await Future<void>.delayed(_latency);
    if (studentId != _demoStudentId) {
      return PerformanceReportModel(
        id: 'report-empty',
        studentId: studentId,
        overallScore: 0,
        strengths: const [],
        weaknesses: const [],
        recommendations: const [],
        generatedAt: DateTime.now(),
      );
    }
    return PerformanceReportModel(
      id: _report.id,
      studentId: _report.studentId,
      overallScore: _report.overallScore,
      strengths: List<String>.from(_report.strengths),
      weaknesses: List<String>.from(_report.weaknesses),
      recommendations: List<String>.from(_report.recommendations),
      generatedAt: _report.generatedAt,
    );
  }

  @override
  List<StudentGoalModel>? getCached() => null;

  @override
  void clearCache() {}
}
