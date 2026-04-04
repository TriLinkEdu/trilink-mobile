import '../models/student_growth_models.dart';

abstract class StudentAnalyticsRepository {
  Future<StudentWeeklySnapshot> fetchWeeklySnapshot();

  Future<StudentPerformanceTrends> fetchPerformanceTrends();

  Future<StudentAttendanceInsight> fetchAttendanceInsight();

  Future<List<StudentActionItem>> fetchActionPlan();
}
