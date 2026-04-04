import 'package:flutter/material.dart';
import 'route_names.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/role_selection_screen.dart';

import '../../features/student/dashboard/screens/student_main_screen.dart';

import '../../features/teacher/dashboard/screens/teacher_main_screen.dart';
import '../../features/teacher/attendance/screens/teacher_attendance_screen.dart';
import '../../features/teacher/exams/screens/create_exam_screen.dart';
import '../../features/teacher/exams/screens/live_exam_monitoring_screen.dart';
import '../../features/teacher/exams/screens/teacher_exams_screen.dart';
import '../../features/teacher/exams/screens/exam_bank_screen.dart';
import '../../features/teacher/announcements/screens/create_announcement_screen.dart';
import '../../features/teacher/announcements/screens/teacher_announcements_screen.dart';
import '../../features/teacher/student_analytics/screens/student_list_screen.dart';
import '../../features/teacher/student_analytics/screens/student_analytics_screen.dart';
import '../../features/teacher/chat/screens/teacher_messages_screen.dart';
import '../../features/teacher/calendar/screens/teacher_calendar_screen.dart';
import '../../features/teacher/settings/screens/teacher_settings_screen.dart';
import '../../features/teacher/notifications/screens/teacher_notifications_screen.dart';

import '../../features/parent/home/screens/parent_home_screen.dart';
import '../../features/parent/dashboard/screens/parent_dashboard_screen.dart';
import '../../features/parent/attendance/screens/parent_attendance_screen.dart';
import '../../features/parent/student_info/screens/parent_results_screen.dart';
import '../../features/parent/student_info/screens/parent_student_info_screen.dart';
import '../../features/parent/chat/screens/parent_chat_screen.dart';
import '../../features/parent/profile_settings/screens/parent_profile_screen.dart';
import '../../features/parent/profile_settings/screens/parent_settings_screen.dart';

class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      // ── Auth ──
      case RouteNames.login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case RouteNames.forgotPassword:
        return MaterialPageRoute(builder: (_) => const ForgotPasswordScreen());
      case RouteNames.register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      case RouteNames.roleSelection:
        return MaterialPageRoute(builder: (_) => const RoleSelectionScreen());

      // ── Student shell (nested nav handles all sub-routes) ──
      case RouteNames.studentDashboard:
        return MaterialPageRoute(builder: (_) => const StudentMainScreen());

      // ── Teacher routes ──
      case RouteNames.teacherDashboard:
        return MaterialPageRoute(builder: (_) => const TeacherMainScreen());
      case RouteNames.teacherAttendance:
        return MaterialPageRoute(builder: (_) => const TeacherAttendanceScreen());
      case RouteNames.teacherCreateExam:
        return MaterialPageRoute(builder: (_) => const CreateExamScreen());
      case RouteNames.teacherLiveExam:
        return MaterialPageRoute(builder: (_) => const LiveExamMonitoringScreen());
      case RouteNames.teacherCreateAnnouncement:
        return MaterialPageRoute(builder: (_) => const CreateAnnouncementScreen());
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
        return MaterialPageRoute(builder: (_) => const TeacherMessagesScreen());
      case RouteNames.teacherCalendar:
        return MaterialPageRoute(builder: (_) => const TeacherCalendarScreen());
      case RouteNames.teacherExams:
        return MaterialPageRoute(builder: (_) => const TeacherExamsScreen());
      case RouteNames.teacherExamBank:
        return MaterialPageRoute(builder: (_) => const ExamBankScreen());
      case RouteNames.teacherAnnouncements:
        return MaterialPageRoute(builder: (_) => const TeacherAnnouncementsScreen());
      case RouteNames.teacherSettings:
        return MaterialPageRoute(builder: (_) => const TeacherSettingsScreen());
      case RouteNames.teacherNotifications:
        return MaterialPageRoute(builder: (_) => const TeacherNotificationsScreen());

      // ── Parent routes ──
      case RouteNames.parentHome:
        return MaterialPageRoute(builder: (_) => const ParentHomeScreen());
      case RouteNames.parentDashboard:
        return MaterialPageRoute(
          builder: (_) => const ParentDashboardScreen(),
        );
      case RouteNames.parentAttendance:
        return MaterialPageRoute(builder: (_) => const ParentAttendanceScreen());
      case RouteNames.parentResults:
        return MaterialPageRoute(
          builder: (_) => const ParentResultsScreen(),
        );
      case RouteNames.parentStudentInfo:
        return MaterialPageRoute(builder: (_) => const ParentStudentInfoScreen());
      case RouteNames.parentChat:
        return MaterialPageRoute(builder: (_) => const ParentChatScreen());
      case RouteNames.parentProfile:
        return MaterialPageRoute(builder: (_) => const ParentProfileScreen());
      case RouteNames.parentSettings:
        return MaterialPageRoute(builder: (_) => const ParentSettingsScreen());

      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Route not found')),
          ),
        );
    }
  }
}