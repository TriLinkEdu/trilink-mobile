import '../../../../core/routes/route_names.dart';
import '../models/student_growth_models.dart';
import 'student_analytics_repository.dart';

class MockStudentAnalyticsRepository implements StudentAnalyticsRepository {
  static const Duration _latency = Duration(milliseconds: 260);

  @override
  Future<StudentWeeklySnapshot> fetchWeeklySnapshot() async {
    await Future<void>.delayed(_latency);
    return const StudentWeeklySnapshot(
      attendanceRate: 0.93,
      averageQuizScore: 82,
      dueAssignments: 3,
      trend: 'up',
      focusSubjects: ['Physics', 'Mathematics'],
      summary:
          'You improved this week, but Physics problem-solving speed still needs focus.',
    );
  }

  @override
  Future<StudentPerformanceTrends> fetchPerformanceTrends() async {
    await Future<void>.delayed(_latency);
    return const StudentPerformanceTrends(
      examReadinessScore: 78,
      subjects: [
        StudentSubjectTrend(
          subjectId: 'physics',
          subjectName: 'Physics',
          points: [
            StudentTrendPoint(label: 'W1', value: 64),
            StudentTrendPoint(label: 'W2', value: 68),
            StudentTrendPoint(label: 'W3', value: 72),
            StudentTrendPoint(label: 'W4', value: 70),
            StudentTrendPoint(label: 'W5', value: 76),
            StudentTrendPoint(label: 'W6', value: 79),
          ],
          strengthTopics: ['Kinematics basics', 'Vectors'],
          riskTopics: ['Newton laws applications', 'Word problems'],
          recommendation: 'Do 20 minutes of force diagrams practice today.',
        ),
        StudentSubjectTrend(
          subjectId: 'math',
          subjectName: 'Mathematics',
          points: [
            StudentTrendPoint(label: 'W1', value: 78),
            StudentTrendPoint(label: 'W2', value: 74),
            StudentTrendPoint(label: 'W3', value: 80),
            StudentTrendPoint(label: 'W4', value: 84),
            StudentTrendPoint(label: 'W5', value: 81),
            StudentTrendPoint(label: 'W6', value: 86),
          ],
          strengthTopics: ['Algebra simplification', 'Linear equations'],
          riskTopics: ['Applied geometry'],
          recommendation: 'Review two geometry proofs before next quiz.',
        ),
      ],
    );
  }

  @override
  Future<StudentAttendanceInsight> fetchAttendanceInsight() async {
    await Future<void>.delayed(_latency);
    return const StudentAttendanceInsight(
      currentRate: 0.91,
      weeklyTrend: [
        StudentTrendPoint(label: 'W1', value: 88),
        StudentTrendPoint(label: 'W2', value: 92),
        StudentTrendPoint(label: 'W3', value: 90),
        StudentTrendPoint(label: 'W4', value: 94),
      ],
      riskLevel: 'Low',
      projectedMonthEndRate: 0.92,
      bestDay: 'Wednesday',
      weakDay: 'Monday',
    );
  }

  @override
  Future<List<StudentActionItem>> fetchActionPlan() async {
    await Future<void>.delayed(_latency);
    return const [
      StudentActionItem(
        id: 'a1',
        title: 'Submit Physics Homework',
        reason: 'Due in 8 hours and worth 10% of unit grade.',
        category: 'assignment',
        effortMinutes: 25,
        routeName: RouteNames.studentAssignments,
        routeArgs: null,
        done: false,
      ),
      StudentActionItem(
        id: 'a2',
        title: 'Practice Newton Laws Quiz',
        reason: 'Recent trend shows weak application questions.',
        category: 'study',
        effortMinutes: 20,
        routeName: RouteNames.studentGamification,
        routeArgs: null,
        done: false,
      ),
      StudentActionItem(
        id: 'a3',
        title: 'Improve Monday Attendance',
        reason: 'Monday is your lowest attendance consistency day.',
        category: 'attendance',
        effortMinutes: 5,
        routeName: RouteNames.studentAttendance,
        routeArgs: null,
        done: false,
      ),
    ];
  }

  @override
  void clearCache() {}
}
