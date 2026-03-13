import 'package:flutter/material.dart';
import 'route_names.dart';
import '../../features/auth/screens/login_screen.dart';

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
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
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
        final args = settings.arguments as Map<String, String>;
        return MaterialPageRoute(
          builder: (_) => SubjectGradesScreen(
            subjectId: args['subjectId'] ?? '',
            subjectName: args['subjectName'] ?? 'Subject',
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
      case RouteNames.studentProfile:
        return MaterialPageRoute(builder: (_) => const StudentProfileScreen());
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
}
