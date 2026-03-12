import 'package:flutter/material.dart';
import 'route_names.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/student/dashboard/screens/student_main_screen.dart';
import '../../features/student/grades/screens/student_grades_screen.dart';
import '../../features/student/grades/screens/subject_grades_screen.dart';
import '../../features/student/announcements/screens/student_announcements_screen.dart';
import '../../features/student/attendance/screens/student_attendance_screen.dart';
import '../../features/student/profile/screens/student_profile_screen.dart';
import '../../features/student/ai_assistant/screens/ai_assistant_screen.dart';
import '../../features/student/gamification/screens/gamification_screen.dart';
import '../../features/student/feedback/screens/student_feedback_screen.dart';

/// Central router for the application.
class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case RouteNames.login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
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
      default:
        return MaterialPageRoute(
          builder: (_) =>
              const Scaffold(body: Center(child: Text('Route not found'))),
        );
    }
  }
}
