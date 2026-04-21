import 'package:flutter/material.dart';
import 'route_names.dart';

import '../../features/student/grades/screens/student_grades_screen.dart';
import '../../features/student/grades/screens/subject_grades_screen.dart';
import '../../features/student/grades/screens/student_goals_screen.dart';
import '../../features/student/announcements/screens/student_announcements_screen.dart';
import '../../features/student/announcements/screens/announcement_detail_screen.dart';
import '../../features/student/attendance/screens/student_attendance_screen.dart';
import '../../features/student/notifications/screens/student_notifications_screen.dart';
import '../../features/student/chat/screens/student_chat_screen.dart';
import '../../features/student/chat/screens/chat_conversation_screen.dart';
import '../../features/student/calendar/screens/student_calendar_screen.dart';
import '../../features/student/calendar/screens/calendar_event_detail_screen.dart';
import '../../features/student/profile/screens/student_profile_screen.dart';
import '../../features/student/profile/screens/student_profile_edit_screen.dart';
import '../../features/student/settings/screens/student_settings_screen.dart';
import '../../features/student/ai_assistant/screens/ai_assistant_screen.dart';
import '../../features/student/ai_assistant/screens/learning_path_screen.dart';
import '../../features/student/ai_assistant/screens/resource_recommendation_screen.dart';
import '../../features/student/ai_assistant/screens/evaluate_me_screen.dart';
import '../../features/student/gamification/screens/gamification_screen.dart';
import '../../features/student/gamification/screens/leaderboard_screen.dart';
import '../../features/student/gamification/screens/achievements_list_screen.dart';
import '../../features/student/gamification/screens/quiz_screen.dart';
import '../../features/student/feedback/screens/student_feedback_screen.dart';
import '../../features/student/feedback/screens/submit_feedback_screen.dart';
import '../../features/student/assignments/screens/student_assignments_screen.dart';
import '../../features/student/assignments/screens/assignment_detail_screen.dart';
import '../../features/student/courses/screens/student_courses_screen.dart';
import '../../features/student/courses/screens/student_course_detail_screen.dart';
import '../../features/student/courses/screens/student_courses_resources_screen.dart';
import '../../features/student/courses/screens/course_resource_detail_screen.dart';
import '../../features/student/exams/screens/student_exam_attempt_screen.dart';
import '../../features/student/exams/screens/student_exams_screen.dart';
import '../../features/student/sync/screens/student_sync_status_screen.dart';
import '../../features/student/analytics/screens/student_weekly_snapshot_screen.dart';
import '../../features/student/analytics/screens/student_action_plan_screen.dart';
import '../../features/student/analytics/screens/student_performance_trends_screen.dart';
import '../../features/student/analytics/screens/student_attendance_insights_screen.dart';

/// Handles all student sub-page routing within the nested shell navigator.
/// This keeps the bottom nav visible for every student screen.
class StudentShellRoutes {
  StudentShellRoutes._();

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    final args = settings.arguments;
    final safeArgs = args is Map
        ? Map<String, dynamic>.from(args)
        : const <String, dynamic>{};

    switch (settings.name) {
      case RouteNames.studentGrades:
        return _page(const StudentGradesScreen(), settings);
      case RouteNames.studentSubjectGrades:
        return _page(
          SubjectGradesScreen(
            subjectId: safeArgs['subjectId']?.toString() ?? '',
            subjectName: safeArgs['subjectName']?.toString() ?? 'Subject',
            selectedTerm: safeArgs['selectedTerm'] as String?,
          ),
          settings,
        );
      case RouteNames.studentAnnouncements:
        return _page(const StudentAnnouncementsScreen(), settings);
      case RouteNames.studentAnnouncementDetail:
        return _page(
          AnnouncementDetailScreen(
            announcementId: safeArgs['announcementId']?.toString() ?? '',
          ),
          settings,
        );
      case RouteNames.studentAttendance:
        return _page(const StudentAttendanceScreen(), settings);
      case RouteNames.studentNotifications:
        return _page(const StudentNotificationsScreen(), settings);
      case RouteNames.studentChat:
        return _page(const StudentChatScreen(), settings);
      case RouteNames.studentChatConversation:
        return _page(
          ChatConversationScreen(
            conversationId: safeArgs['conversationId']?.toString() ?? '',
            title: safeArgs['title']?.toString() ?? 'Chat',
          ),
          settings,
        );
      case RouteNames.studentProfile:
        return _page(const StudentProfileScreen(), settings);
      case RouteNames.studentProfileEdit:
        return _page(const StudentProfileEditScreen(), settings);
      case RouteNames.studentCalendar:
        return _page(const StudentCalendarScreen(), settings);
      case RouteNames.studentCalendarEventDetail:
        return _page(
          CalendarEventDetailScreen(
            eventId: safeArgs['eventId']?.toString() ?? '',
          ),
          settings,
        );
      case RouteNames.studentSettings:
        return _page(const StudentSettingsScreen(), settings);
      case RouteNames.studentAiAssistant:
        return _page(const AiAssistantScreen(), settings);
      case RouteNames.studentLearningPath:
        return _page(const LearningPathScreen(), settings);
      case RouteNames.studentResourceRecommendation:
        return _page(const ResourceRecommendationScreen(), settings);
      case RouteNames.studentEvaluateMe:
        return _page(const EvaluateMeScreen(), settings);
      case RouteNames.studentGamification:
        return _page(const GamificationScreen(), settings);
      case RouteNames.studentLeaderboard:
        return _page(const LeaderboardScreen(), settings);
      case RouteNames.studentAchievements:
        return _page(const AchievementsListScreen(), settings);
      case RouteNames.studentQuiz:
        return _page(
          QuizScreen(subjectId: safeArgs['subjectId']?.toString() ?? 'general'),
          settings,
        );
      case RouteNames.studentFeedback:
        return _page(const StudentFeedbackScreen(), settings);
      case RouteNames.studentSubmitFeedback:
        return _page(
          SubmitFeedbackScreen(
            subjectId: safeArgs['subjectId']?.toString() ?? '',
            subjectName: safeArgs['subjectName']?.toString() ?? '',
          ),
          settings,
        );
      case RouteNames.studentAssignments:
        return _page(const StudentAssignmentsScreen(), settings);
      case RouteNames.studentAssignmentDetail:
        return _page(
          AssignmentDetailScreen(
            assignmentId: safeArgs['assignmentId']?.toString() ?? '',
          ),
          settings,
        );
      case RouteNames.studentCourses:
        return _page(const StudentCoursesScreen(), settings);
      case RouteNames.studentCourseDetail:
        return _page(
          StudentCourseDetailScreen(
            subjectId: safeArgs['subjectId']?.toString() ?? '',
            subjectName: safeArgs['subjectName']?.toString() ?? 'Course',
          ),
          settings,
        );
      case RouteNames.studentCourseResources:
        return _page(
          StudentCoursesResourcesScreen(
            subjectId: safeArgs['subjectId']?.toString(),
            subjectName: safeArgs['subjectName']?.toString(),
          ),
          settings,
        );
      case RouteNames.studentCourseResourceDetail:
        return _page(
          CourseResourceDetailScreen(
            resourceId: safeArgs['resourceId']?.toString() ?? '',
          ),
          settings,
        );
      case RouteNames.studentExams:
        return _page(const StudentExamsScreen(), settings);
      case RouteNames.studentExamAttempt:
        return _page(
          StudentExamAttemptScreen(examId: safeArgs['examId']?.toString()),
          settings,
        );
      case RouteNames.studentSyncStatus:
        return _page(const StudentSyncStatusScreen(), settings);
      case RouteNames.studentWeeklySnapshot:
        return _page(const StudentWeeklySnapshotScreen(), settings);
      case RouteNames.studentActionPlan:
        return _page(const StudentActionPlanScreen(), settings);
      case RouteNames.studentGoals:
        return _page(const StudentGoalsScreen(), settings);
      case RouteNames.studentPerformanceTrends:
        return _page(const StudentPerformanceTrendsScreen(), settings);
      case RouteNames.studentAttendanceInsights:
        return _page(const StudentAttendanceInsightsScreen(), settings);
      default:
        return null;
    }
  }

  static MaterialPageRoute<T> _page<T>(Widget child, RouteSettings settings) {
    return MaterialPageRoute<T>(builder: (_) => child, settings: settings);
  }
}
