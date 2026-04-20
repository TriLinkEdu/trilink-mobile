import '../../../../core/constants/api_constants.dart';
import '../../../../core/models/performance_report_model.dart';
import '../../../../core/models/student_goal_model.dart';
import '../../../../core/models/topic_mastery_model.dart';
import '../../../../core/network/api_client.dart';
import 'student_performance_repository.dart';

class RealStudentPerformanceRepository implements StudentPerformanceRepository {
  final ApiClient _api;

  RealStudentPerformanceRepository({ApiClient? apiClient})
    : _api = apiClient ?? ApiClient();

  @override
  Future<List<TopicMasteryModel>> fetchMasteryLevels(String studentId) async {
    // No dedicated mastery endpoint in backend yet.
    return const [];
  }

  @override
  Future<List<StudentGoalModel>> fetchGoals(String studentId) async {
    final rows = await _api.getList(ApiConstants.myGoals);
    return rows.whereType<Map<String, dynamic>>().map(_mapGoal).toList();
  }

  @override
  Future<StudentGoalModel> createGoal(StudentGoalModel goal) async {
    final title = goal.goalText.trim();
    final raw = await _api.post(
      ApiConstants.myGoals,
      data: {
        'title': title,
        'description': title,
        if (goal.targetDate != null)
          'targetDate': goal.targetDate!.toIso8601String().split('T').first,
      },
    );
    return _mapGoal(raw, fallbackStudentId: goal.studentId);
  }

  @override
  Future<StudentGoalModel> updateGoal(StudentGoalModel goal) async {
    final title = goal.goalText.trim();
    final raw = await _api.patch(
      ApiConstants.goalById(goal.id),
      data: {
        'title': title,
        'description': title,
        'status': goal.isAchieved ? 'completed' : 'active',
        if (goal.targetDate != null)
          'targetDate': goal.targetDate!.toIso8601String().split('T').first,
      },
    );
    return _mapGoal(raw, fallbackStudentId: goal.studentId);
  }

  @override
  Future<PerformanceReportModel> fetchLatestReport(String studentId) async {
    final raw = await _api.get(
      ApiConstants.studentReport(studentId),
      queryParameters: {'periodType': 'weekly'},
    );
    final summary = raw['summary'] as Map<String, dynamic>?;
    final courses = raw['courses'] as List<dynamic>?;

    final strengths = <String>[];
    final weaknesses = <String>[];
    final recommendations = <String>[];

    if (summary != null) {
      final attendance = summary['overallAttendancePercent'];
      final subjects = summary['overallSubjectsAveragePercent'];

      if (attendance is num && attendance >= 85) {
        strengths.add('Excellent attendance consistency');
      } else {
        weaknesses.add('Attendance needs consistency');
      }

      if (subjects is num && subjects >= 75) {
        strengths.add('Strong subject average performance');
      } else {
        weaknesses.add('Subject average below target threshold');
      }
    }

    if (courses != null && courses.isNotEmpty) {
      recommendations.add('Focus on lowest-performing subject this week');
      recommendations.add('Review recent assessment feedback before next exam');
    } else {
      recommendations.add(
        'Complete more assessed coursework to unlock trend insights',
      );
    }

    return PerformanceReportModel(
      id: (raw['studentId'] ?? studentId).toString(),
      studentId: (raw['studentId'] ?? studentId).toString(),
      overallScore: _asDouble(
        summary?['overallSubjectsAveragePercent'],
        fallback: 0,
      ),
      strengths: strengths,
      weaknesses: weaknesses,
      recommendations: recommendations,
      generatedAt:
          DateTime.tryParse((raw['generatedAt'] ?? '').toString()) ??
          DateTime.now(),
    );
  }

  StudentGoalModel _mapGoal(
    Map<String, dynamic> raw, {
    String? fallbackStudentId,
  }) {
    final status = (raw['status'] ?? 'active').toString().toLowerCase();
    return StudentGoalModel(
      id: (raw['id'] ?? '').toString(),
      studentId: (raw['studentId'] ?? fallbackStudentId ?? '').toString(),
      goalText: (raw['title'] ?? raw['description'] ?? '').toString(),
      targetDate: DateTime.tryParse((raw['targetDate'] ?? '').toString()),
      isAchieved:
          status == 'completed' || status == 'done' || status == 'closed',
      createdAt:
          DateTime.tryParse((raw['createdAt'] ?? '').toString()) ??
          DateTime.now(),
    );
  }

  double _asDouble(dynamic value, {required double fallback}) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? fallback;
  }
}
