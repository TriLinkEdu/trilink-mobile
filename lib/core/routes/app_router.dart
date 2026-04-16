import 'package:flutter/material.dart';
import 'route_names.dart';
import '../../features/auth/screens/login_screen.dart';


import '../../features/auth/screens/role_selection_screen.dart';

import '../../features/student/dashboard/screens/student_main_screen.dart';

import '../../features/teacher/dashboard/screens/teacher_main_screen.dart';
import '../../features/teacher/attendance/screens/teacher_attendance_screen.dart';
import '../../features/teacher/attendance/screens/attendance_analytics_screen.dart';
import '../../features/teacher/exams/screens/create_exam_screen.dart';
import '../../features/teacher/exams/screens/live_exam_monitoring_screen.dart';
import '../../features/teacher/exams/screens/teacher_exams_screen.dart';
import '../../features/teacher/exams/screens/exam_bank_screen.dart';
import '../../features/teacher/exams/screens/exam_analytics_screen.dart';
import '../../features/teacher/exams/screens/evaluate_submissions_screen.dart';
import '../../features/teacher/announcements/screens/create_announcement_screen.dart';
import '../../features/teacher/announcements/screens/teacher_announcements_screen.dart';
import '../../features/teacher/student_analytics/screens/student_list_screen.dart';
import '../../features/teacher/student_analytics/screens/student_analytics_screen.dart';
import '../../features/teacher/chat/screens/teacher_messages_screen.dart';
import '../../features/teacher/chat/screens/teacher_chat_conversation_screen.dart';
import '../../features/teacher/chat/screens/create_group_screen.dart';
import '../../features/teacher/calendar/screens/teacher_calendar_screen.dart';
import '../../features/teacher/settings/screens/teacher_settings_screen.dart';
import '../../features/teacher/notifications/screens/teacher_notifications_screen.dart';
import '../../features/teacher/classes/screens/class_list_screen.dart';
import '../../features/teacher/ai_assistant/screens/teacher_ai_assistant_screen.dart';

import '../../features/parent/home/screens/parent_home_screen.dart';
import '../../features/parent/dashboard/screens/parent_dashboard_screen.dart';
import '../../features/parent/attendance/screens/parent_attendance_screen.dart';
import '../../features/parent/student_info/screens/parent_results_screen.dart';
import '../../features/parent/student_info/screens/parent_student_info_screen.dart';
import '../../features/parent/chat/screens/parent_chat_screen.dart';
import '../../features/parent/profile_settings/screens/parent_profile_screen.dart';
import '../../features/parent/profile_settings/screens/parent_settings_screen.dart';
import '../../features/parent/notifications/screens/parent_notifications_screen.dart';
import '../../features/parent/announcements/screens/parent_announcements_screen.dart';
import '../../features/parent/feedback/screens/parent_feedback_screen.dart';
import '../../features/parent/reports/screens/weekly_report_screen.dart';
import '../../features/parent/reports/screens/report_comparison_screen.dart';
import '../../features/shared/screens/theme_customization_screen.dart';

class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      // ── Auth ──
      case RouteNames.login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());

      case RouteNames.roleSelection:
        return MaterialPageRoute(builder: (_) => const RoleSelectionScreen());

      // ── Student shell (nested nav handles all sub-routes) ──
      case RouteNames.studentDashboard:
        return MaterialPageRoute(builder: (_) => const StudentMainScreen());

      // ── Teacher routes ──
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
        return MaterialPageRoute(builder: (_) => const TeacherMessagesScreen());
      case RouteNames.teacherCalendar:
        return MaterialPageRoute(builder: (_) => const TeacherCalendarScreen());
      case RouteNames.teacherExams:
        return MaterialPageRoute(builder: (_) => const TeacherExamsScreen());
      case RouteNames.teacherExamBank:
        return MaterialPageRoute(builder: (_) => const ExamBankScreen());
      case RouteNames.teacherExamAnalytics:
        final args = settings.arguments as Map<String, String>?;
        return MaterialPageRoute(
          builder: (_) => ExamAnalyticsScreen(examId: args?['examId'] ?? ''),
        );
      case RouteNames.teacherEvaluateSubmissions:
        final args = settings.arguments as Map<String, String>?;
        return MaterialPageRoute(
          builder: (_) =>
              EvaluateSubmissionsScreen(examId: args?['examId'] ?? ''),
        );
      case RouteNames.teacherAnnouncements:
        return MaterialPageRoute(
          builder: (_) => const TeacherAnnouncementsScreen(),
        );
      case RouteNames.teacherAttendanceAnalytics:
        return MaterialPageRoute(
          builder: (_) => const AttendanceAnalyticsScreen(),
        );
      case RouteNames.teacherClasses:
        return MaterialPageRoute(builder: (_) => const ClassListScreen());
      case RouteNames.teacherSettings:
        return MaterialPageRoute(builder: (_) => const TeacherSettingsScreen());
      case RouteNames.teacherNotifications:
        return MaterialPageRoute(
          builder: (_) => const TeacherNotificationsScreen(),
        );
      case RouteNames.teacherChatConversation:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => TeacherChatConversationScreen(
            threadName: args?['threadName'] as String? ?? 'Chat',
            conversationId: args?['conversationId'] as String? ?? '',
            isParent: args?['isParent'] as bool? ?? false,
          ),
        );
      case RouteNames.teacherCreateGroup:
        return MaterialPageRoute(builder: (_) => const CreateGroupScreen());
      case RouteNames.teacherAiAssistant:
        return MaterialPageRoute(
          builder: (_) => const TeacherAiAssistantScreen(),
        );

      // ── Parent routes ──
      case RouteNames.parentHome:
        return MaterialPageRoute(builder: (_) => const ParentHomeScreen());
      case RouteNames.parentDashboard:
        return MaterialPageRoute(builder: (_) => const ParentDashboardScreen());
      case RouteNames.parentAttendance:
        return MaterialPageRoute(
          builder: (_) => const ParentAttendanceScreen(),
        );
      case RouteNames.parentResults:
        return MaterialPageRoute(builder: (_) => const ParentResultsScreen());
      case RouteNames.parentStudentInfo:
        final args = settings.arguments as Map<String, String>?;
        return MaterialPageRoute(
          builder: (_) =>
              ParentStudentInfoScreen(childName: args?['childName'] ?? ''),
        );
      case RouteNames.parentChat:
        return MaterialPageRoute(builder: (_) => const ParentChatScreen());
      case RouteNames.parentProfile:
        return MaterialPageRoute(builder: (_) => const ParentProfileScreen());
      case RouteNames.parentSettings:
        return MaterialPageRoute(builder: (_) => const ParentSettingsScreen());
      case RouteNames.parentNotifications:
        return MaterialPageRoute(
          builder: (_) => const ParentNotificationsScreen(),
        );
      case RouteNames.parentAnnouncements:
        return MaterialPageRoute(
          builder: (_) => const ParentAnnouncementsScreen(),
        );
      case RouteNames.parentFeedback:
        return MaterialPageRoute(builder: (_) => const ParentFeedbackScreen());
      case RouteNames.parentWeeklyReport:
        final args = settings.arguments as Map<String, String>?;
        return MaterialPageRoute(
          builder: (_) =>
              WeeklyReportScreen(childName: args?['childName'] ?? ''),
        );
      case RouteNames.parentReportComparison:
        return MaterialPageRoute(
          builder: (_) => const ReportComparisonScreen(),
        );

      case RouteNames.themeCustomization:
        return MaterialPageRoute(
          builder: (_) => const ThemeCustomizationScreen(),
        );

      default:
        return MaterialPageRoute(
          builder: (_) =>
              const Scaffold(body: Center(child: Text('Route not found'))),
        );
    }
  }
}
