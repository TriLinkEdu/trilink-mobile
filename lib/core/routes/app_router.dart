import 'package:flutter/material.dart';
import 'route_names.dart';
import '../../features/auth/screens/login_screen.dart';

import '../../features/auth/screens/role_selection_screen.dart';

import '../../features/student/dashboard/screens/student_main_screen.dart';

import '../../features/teacher/dashboard/screens/teacher_main_screen.dart';
import '../../features/teacher/attendance/screens/teacher_attendance_screen.dart';
import '../../features/teacher/attendance/screens/attendance_analytics_screen.dart';
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
import '../../features/teacher/classes/screens/teacher_class_detail_screen.dart';
import '../../features/teacher/ai_assistant/screens/teacher_ai_assistant_screen.dart';
import '../../features/teacher/feedback/screens/teacher_feedback_screen.dart';
import '../../features/teacher/schedule/screens/teacher_schedule_screen.dart';
import '../../features/teacher/grades/screens/teacher_grade_analytics_screen.dart';
import '../../features/teacher/homeroom/screens/teacher_homeroom_screen.dart';
import '../../features/teacher/homeroom/screens/teacher_remark_form_screen.dart';
import '../../features/teacher/notifications/screens/broadcast_notification_screen.dart';
import '../../features/teacher/attendance/screens/teacher_all_sessions_screen.dart';
import '../../features/teacher/assignments/screens/teacher_assignments_screen.dart';
import '../../features/teacher/assignments/screens/assignment_form_screen.dart';
import '../../features/teacher/assignments/screens/assignment_submissions_screen.dart';
import '../../features/teacher/grades/screens/teacher_gradebook_screen.dart';
import '../../features/teacher/grades/screens/grade_entry_screen.dart';
import '../../features/teacher/report_cards/screens/class_ranking_screen.dart';

import '../../features/parent/home/screens/parent_home_screen.dart';
import '../../features/parent/dashboard/screens/parent_dashboard_screen.dart';
import '../../features/parent/attendance/screens/parent_attendance_screen.dart';
import '../../features/parent/student_info/screens/parent_results_screen.dart';
import '../../features/parent/student_info/screens/parent_student_info_screen.dart';
import '../../features/parent/student_info/screens/parent_subject_list_screen.dart';
import '../../features/parent/student_info/screens/parent_subject_detail_screen.dart';
import '../../features/parent/chat/screens/parent_chat_screen.dart';
import '../../features/parent/chat/screens/parent_child_chat_history_screen.dart';
import '../../features/parent/chat/screens/parent_child_conversation_view_screen.dart';
import '../../features/parent/profile_settings/screens/parent_profile_screen.dart';
import '../../features/parent/profile_settings/screens/parent_settings_screen.dart';
import '../../features/parent/notifications/screens/parent_notifications_screen.dart';
import '../../features/parent/announcements/screens/parent_announcements_screen.dart';
import '../../features/parent/feedback/screens/parent_feedback_screen.dart';
import '../../features/parent/reports/screens/weekly_report_screen.dart';
import '../../features/parent/reports/screens/report_comparison_screen.dart';
import '../../features/parent/upcoming/screens/parent_upcoming_screen.dart';
import '../../features/parent/report_cards/screens/parent_report_card_screen.dart';
import '../../features/parent/report_cards/screens/parent_yearly_report_card_screen.dart';
import '../../features/parent/student_info/screens/student_mastery_screen.dart';
import '../../features/shared/screens/theme_customization_screen.dart';
import '../../features/shared/screens/route_not_found_screen.dart';
import '../../features/shared/screens/global_search_screen.dart';
import '../../features/shared/screens/sync_status_screen.dart';

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
      case RouteNames.teacherClassDetail:
        final args = settings.arguments as Map<String, dynamic>? ?? {};
        return MaterialPageRoute(
          builder: (_) => TeacherClassDetailScreen(
            classId: args['classId'] as String? ?? '',
            className: args['className'] as String? ?? 'Class',
            classPeriod: args['classPeriod'] as String? ?? '',
          ),
        );
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
      case RouteNames.teacherFeedback:
        return MaterialPageRoute(builder: (_) => const TeacherFeedbackScreen());
      case RouteNames.teacherSchedule:
        return MaterialPageRoute(builder: (_) => const TeacherScheduleScreen());
      case RouteNames.teacherGradeAnalytics:
        return MaterialPageRoute(
          builder: (_) => const TeacherGradeAnalyticsScreen(),
        );

      // ── Teacher §4 features ──
      case RouteNames.teacherHomeroom:
        return MaterialPageRoute(builder: (_) => const TeacherHomeroomScreen());
      case RouteNames.teacherHomeroomRemark:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => TeacherRemarkFormScreen(
            studentId: (args?['studentId'] ?? '') as String,
            studentName: (args?['studentName'] ?? '') as String,
          ),
        );
      case RouteNames.teacherBroadcast:
        return MaterialPageRoute(
          builder: (_) => const BroadcastNotificationScreen(),
        );
      case RouteNames.teacherSessionsMine:
        return MaterialPageRoute(
          builder: (_) => const TeacherAllSessionsScreen(),
        );
      case RouteNames.teacherAssignments:
        return MaterialPageRoute(
          builder: (_) => const TeacherAssignmentsScreen(),
        );
      case RouteNames.teacherAssignmentForm:
        final args = settings.arguments as Map<String, dynamic>? ?? {};
        return MaterialPageRoute(
          builder: (_) => AssignmentFormScreen(
            existing: args['existing'] as Map<String, dynamic>?,
            classes: ((args['classes'] as List?) ?? const [])
                .whereType<Map<String, dynamic>>()
                .toList(),
            terms: ((args['terms'] as List?) ?? const [])
                .whereType<Map<String, dynamic>>()
                .toList(),
          ),
        );
      case RouteNames.teacherAssignmentSubmissions:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => AssignmentSubmissionsScreen(
            assignmentId: (args?['assignmentId'] ?? '') as String,
            title: args?['title'] as String?,
          ),
        );
      case RouteNames.teacherGradebook:
        return MaterialPageRoute(
          builder: (_) => const TeacherGradebookScreen(),
        );
      case RouteNames.teacherGradebookEntry:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => GradeEntryScreen(
            classOfferingId: (args?['classOfferingId'] ?? '') as String,
            termId: (args?['termId'] ?? '') as String,
            termLabel: args?['termLabel'] as String?,
            existingGroup: args?['existingGroup'] as Map<String, dynamic>?,
          ),
        );
      case RouteNames.teacherClassRanking:
        final args = settings.arguments as Map<String, String>?;
        return MaterialPageRoute(
          builder: (_) => ClassRankingScreen(
            gradeId: args?['gradeId'] ?? '',
            sectionId: args?['sectionId'] ?? '',
          ),
        );

      // ── Shared §4 features ──
      case RouteNames.globalSearch:
        return MaterialPageRoute(builder: (_) => const GlobalSearchScreen());
      case RouteNames.syncStatus:
        return MaterialPageRoute(builder: (_) => const SyncStatusScreen());

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
      case RouteNames.parentSubjectList:
        final args = settings.arguments as Map<String, String>?;
        return MaterialPageRoute(
          builder: (_) => ParentSubjectListScreen(
            studentId: args?['studentId'] ?? '',
            childName: args?['childName'] ?? '',
          ),
        );
      case RouteNames.parentSubjectDetail:
        final args = settings.arguments as Map<String, String>?;
        return MaterialPageRoute(
          builder: (_) => ParentSubjectDetailScreen(
            studentId: args?['studentId'] ?? '',
            subjectId: args?['subjectId'] ?? '',
            subjectName: args?['subjectName'] ?? '',
            childName: args?['childName'] ?? '',
          ),
        );
      case RouteNames.parentChildChatHistory:
        final args = settings.arguments as Map<String, String>?;
        return MaterialPageRoute(
          builder: (_) => ParentChildChatHistoryScreen(
            studentId: args?['studentId'] ?? '',
            childName: args?['childName'] ?? '',
          ),
        );
      case RouteNames.parentChildConversationView:
        final args = settings.arguments as Map<String, String>?;
        return MaterialPageRoute(
          builder: (_) => ParentChildConversationViewScreen(
            studentId: args?['studentId'] ?? '',
            conversationId: args?['conversationId'] ?? '',
            conversationTitle: args?['conversationTitle'] ?? 'Conversation',
            childName: args?['childName'] ?? '',
          ),
        );

      // ── Parent §4 features ──
      case RouteNames.parentUpcoming:
        final args = settings.arguments as Map<String, String>?;
        return MaterialPageRoute(
          builder: (_) => ParentUpcomingScreen(
            studentId: args?['studentId'] ?? '',
            childName: args?['childName'],
          ),
        );
      case RouteNames.parentReportCard:
        final args = settings.arguments as Map<String, String>?;
        return MaterialPageRoute(
          builder: (_) => ParentReportCardScreen(
            studentId: args?['studentId'] ?? '',
            childName: args?['childName'],
          ),
        );
      case RouteNames.parentYearlyReportCard:
        final args = settings.arguments as Map<String, String>?;
        return MaterialPageRoute(
          builder: (_) => ParentYearlyReportCardScreen(
            studentId: args?['studentId'] ?? '',
            academicYearId: args?['academicYearId'] ?? '',
            childName: args?['childName'],
          ),
        );
      case RouteNames.parentMastery:
        final args = settings.arguments as Map<String, String>?;
        return MaterialPageRoute(
          builder: (_) => StudentMasteryScreen(
            studentId: args?['studentId'] ?? '',
            childName: args?['childName'],
          ),
        );

      case RouteNames.themeCustomization:
        return MaterialPageRoute(
          builder: (_) => const ThemeCustomizationScreen(),
        );

      default:
        return MaterialPageRoute(
          builder: (_) => RouteNotFoundScreen(attemptedRoute: settings.name),
        );
    }
  }
}
