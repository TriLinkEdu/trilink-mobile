import '../../../../core/models/topic_mastery_model.dart';
import '../../../../core/models/student_goal_model.dart';
import '../../../../core/models/performance_report_model.dart';

abstract class StudentPerformanceRepository {
  Future<List<TopicMasteryModel>> fetchMasteryLevels(String studentId);
  Future<List<StudentGoalModel>> fetchGoals(String studentId);
  Future<StudentGoalModel> createGoal(StudentGoalModel goal);
  Future<StudentGoalModel> updateGoal(StudentGoalModel goal);
  Future<PerformanceReportModel> fetchLatestReport(String studentId);
}
