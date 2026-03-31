import 'package:flutter/material.dart';
import 'route_names.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/services/auth_service.dart';

// Student imports
import '../../features/student/dashboard/screens/student_main_screen.dart';
import '../../features/student/grades/screens/student_grades_screen.dart';
import '../../features/student/grades/screens/subject_grades_screen.dart';
import '../../features/student/announcements/screens/student_announcements_screen.dart';
import '../../features/student/attendance/screens/student_attendance_screen.dart';
import '../../features/student/profile/screens/student_profile_screen.dart';
import '../../features/student/ai_assistant/screens/ai_assistant_screen.dart';
import '../../features/student/gamification/screens/gamification_screen.dart';
import '../../features/student/feedback/screens/student_feedback_screen.dart';
import '../../features/student/notifications/screens/student_notifications_screen.dart';
import '../../features/student/chat/screens/student_chat_screen.dart';
import '../../features/student/calendar/screens/student_calendar_screen.dart';
import '../../features/student/settings/screens/student_settings_screen.dart';
import '../../features/student/assignments/screens/student_assignments_screen.dart';
import '../../features/student/assignments/screens/assignment_detail_screen.dart';
import '../../features/student/courses/screens/student_courses_resources_screen.dart';
import '../../features/student/exams/screens/student_exam_attempt_screen.dart';
import '../../features/student/sync/screens/student_sync_status_screen.dart';

// Teacher imports
import '../../features/teacher/dashboard/screens/teacher_main_screen.dart';
import '../../features/teacher/attendance/screens/teacher_attendance_screen.dart';
import '../../features/teacher/exams/screens/create_exam_screen.dart';
import '../../features/teacher/exams/screens/live_exam_monitoring_screen.dart';
import '../../features/teacher/announcements/screens/create_announcement_screen.dart';
import '../../features/teacher/student_analytics/screens/student_list_screen.dart';
import '../../features/teacher/student_analytics/screens/student_analytics_screen.dart';
import '../../features/teacher/chat/screens/teacher_messages_screen.dart';
import '../../features/teacher/calendar/screens/teacher_calendar_screen.dart';

// Parent imports
import '../../features/parent/home/screens/parent_home_screen.dart';
import '../../features/parent/dashboard/screens/parent_dashboard_screen.dart';
import '../../features/parent/attendance/screens/parent_attendance_screen.dart';
import '../../features/parent/student_info/screens/parent_results_screen.dart';

class AppRouter {
  static const Set<String> _studentAllowedRoutes = {
    RouteNames.login,
    RouteNames.studentDashboard,
    RouteNames.studentAnnouncements,
    RouteNames.studentGrades,
    RouteNames.studentSubjectGrades,
    RouteNames.studentAttendance,
    RouteNames.studentNotifications,
    RouteNames.studentChat,
    RouteNames.studentAiAssistant,
    RouteNames.studentFeedback,
    RouteNames.studentGamification,
    RouteNames.studentCalendar,
    RouteNames.studentProfile,
    RouteNames.studentSettings,
    RouteNames.studentAssignments,
    RouteNames.studentAssignmentDetail,
    RouteNames.studentCourseResources,
    RouteNames.studentExamAttempt,
    RouteNames.studentSyncStatus,
  };

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final currentRole = AuthService().currentRole;
    if (currentRole == 'student' &&
        !_studentAllowedRoutes.contains(settings.name)) {
      return _buildNoopRoute();
    }

    switch (settings.name) {
      // Auth
      case RouteNames.login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());

      // Student routes
      case RouteNames.studentDashboard:
        return MaterialPageRoute(builder: (_) => const StudentMainScreen());
      case RouteNames.studentGrades:
        return MaterialPageRoute(builder: (_) => const StudentGradesScreen());
      case RouteNames.studentSubjectGrades:
        final args = settings.arguments;
        final safeArgs = args is Map
            ? Map<String, dynamic>.from(args)
            : const <String, dynamic>{};
        return MaterialPageRoute(
          builder: (_) => SubjectGradesScreen(
            subjectId: safeArgs['subjectId']?.toString() ?? '',
            subjectName: safeArgs['subjectName']?.toString() ?? 'Subject',
          ),
        );
      case RouteNames.studentAnnouncements:
        return MaterialPageRoute(
          builder: (_) => const StudentAnnouncementsScreen(),
        );
      case RouteNames.studentAttendance:
        return MaterialPageRoute(
          builder: (_) => const StudentAttendanceScreen(),
        );
      case RouteNames.studentNotifications:
        return MaterialPageRoute(
          builder: (_) => const StudentNotificationsScreen(),
        );
      case RouteNames.studentChat:
        return MaterialPageRoute(builder: (_) => const StudentChatScreen());
      case RouteNames.studentProfile:
        return MaterialPageRoute(builder: (_) => const StudentProfileScreen());
      case RouteNames.studentCalendar:
        return MaterialPageRoute(builder: (_) => const StudentCalendarScreen());
      case RouteNames.studentSettings:
        return MaterialPageRoute(builder: (_) => const StudentSettingsScreen());
      case RouteNames.studentAssignments:
        return MaterialPageRoute(builder: (_) => const StudentAssignmentsScreen());
      case RouteNames.studentAssignmentDetail:
        final args = settings.arguments;
        final safeArgs = args is Map
            ? Map<String, dynamic>.from(args)
            : const <String, dynamic>{};
        return MaterialPageRoute(
          builder: (_) => AssignmentDetailScreen(
            assignmentId: safeArgs['assignmentId']?.toString() ?? '',
            title: safeArgs['title']?.toString() ?? 'Assignment',
            subject: safeArgs['subject']?.toString() ?? 'Subject',
            dueDateLabel: safeArgs['dueDateLabel']?.toString() ?? 'TBD',
            statusLabel: safeArgs['statusLabel']?.toString() ?? 'Pending',
          ),
        );
      case RouteNames.studentCourseResources:
        return MaterialPageRoute(
          builder: (_) => const StudentCoursesResourcesScreen(),
        );
      case RouteNames.studentExamAttempt:
        return MaterialPageRoute(builder: (_) => const StudentExamAttemptScreen());
      case RouteNames.studentSyncStatus:
        return MaterialPageRoute(builder: (_) => const StudentSyncStatusScreen());
      case RouteNames.studentAiAssistant:
        return MaterialPageRoute(builder: (_) => const AiAssistantScreen());
      case RouteNames.studentGamification:
        return MaterialPageRoute(builder: (_) => const GamificationScreen());
      case RouteNames.studentFeedback:
        return MaterialPageRoute(builder: (_) => const StudentFeedbackScreen());

      // Teacher routes
      case RouteNames.teacherDashboard:
        return MaterialPageRoute(builder: (_) => const TeacherMainScreen());
      case RouteNames.teacherAttendance:
        return MaterialPageRoute(
          builder: (_) => const TeacherAttendanceScreen(),
        );
      case RouteNames.teacherCreateExam:
        return MaterialPageRoute(builder: (_) => const CreateExamScreen());
      case RouteNames.teacherLiveExam:
        return MaterialPageRoute(
          builder: (_) => const LiveExamMonitoringScreen(),
        );
      case RouteNames.teacherCreateAnnouncement:
        return MaterialPageRoute(
          builder: (_) => const CreateAnnouncementScreen(),
        );
      case RouteNames.teacherStudentList:
        return MaterialPageRoute(builder: (_) => const StudentListScreen());
      case RouteNames.teacherStudentAnalytics:
        final args = settings.arguments as Map<String, String>;
        return MaterialPageRoute(
          builder: (_) => StudentAnalyticsScreen(
            studentId: args['studentId'] ?? '',
            studentName: args['studentName'] ?? '',
          ),
        );
      case RouteNames.teacherMessages:
        return MaterialPageRoute(
          builder: (_) => const TeacherMessagesScreen(),
        );
      case RouteNames.teacherCalendar:
        return MaterialPageRoute(
          builder: (_) => const TeacherCalendarScreen(),
        );

      // Parent routes
      case RouteNames.parentHome:
        return MaterialPageRoute(builder: (_) => const ParentHomeScreen());
      case RouteNames.parentDashboard:
        final args = settings.arguments as Map<String, String>?;
        return MaterialPageRoute(
          builder: (_) => ParentDashboardScreen(
            childName: args?['childName'] ?? 'Sara Mekonnen',
            childId: args?['childId'] ?? '99281',
          ),
        );
      case RouteNames.parentAttendance:
        return MaterialPageRoute(
          builder: (_) => const ParentAttendanceScreen(),
        );
      case RouteNames.parentResults:
        final args = settings.arguments as Map<String, String>?;
        return MaterialPageRoute(
          builder: (_) => ParentResultsScreen(
            studentId: args?['studentId'] ?? '',
            studentName: args?['studentName'] ?? '',
          ),
        );

      default:
        return MaterialPageRoute(
          builder: (_) =>
              const Scaffold(body: Center(child: Text('Route not found'))),
        );
    }
  }

  static Route<dynamic> _buildNoopRoute() {
    return PageRouteBuilder(
      opaque: false,
      barrierColor: Colors.transparent,
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
      pageBuilder: (context, animation, secondaryAnimation) =>
          const _NavigationNoopScreen(),
    );
  }
}

class _NavigationNoopScreen extends StatefulWidget {
  const _NavigationNoopScreen();

  @override
  State<_NavigationNoopScreen> createState() => _NavigationNoopScreenState();
}

class _NavigationNoopScreenState extends State<_NavigationNoopScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
