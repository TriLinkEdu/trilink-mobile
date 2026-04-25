import 'package:flutter/foundation.dart';

enum ApiEnvironment { local, production }

class ApiConstants {
  ApiConstants._();

  static ApiEnvironment get environment {
    const fromDefine = String.fromEnvironment('API_ENV', defaultValue: '');
    if (fromDefine.toLowerCase() == 'production') {
      return ApiEnvironment.production;
    }
    if (fromDefine.toLowerCase() == 'local') {
      return ApiEnvironment.local;
    }
    return ApiEnvironment.local;
  }

  // Single switch point for data source mode.
  // Keep true to use real backend APIs.
  // Set false to force mock repositories.
  static const bool useRealApi = true;

  static String get localBaseUrl {
    const explicitLocalHost = String.fromEnvironment(
      'API_LOCAL_HOST',
      defaultValue: '',
    );
    if (explicitLocalHost.isNotEmpty) {
      return 'http://$explicitLocalHost:4000/api';
    }

    if (kIsWeb) return 'http://localhost:4000/api';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:4000/api';
    }
    return 'http://localhost:4000/api';
  }

  static const String productionBaseUrl =
      'https://trilink-backend-ms68.onrender.com/api';
  static const String productionDocsUrl =
      'https://trilink-backend-ms68.onrender.com/api-docs';

  // Optional override for special cases:
  // --dart-define=API_BASE_URL=...
  static String get baseUrl {
    const overrideUrl = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: '',
    );
    if (overrideUrl.isNotEmpty) return overrideUrl;

    return environment == ApiEnvironment.production
        ? productionBaseUrl
        : localBaseUrl;
  }

  // Base URL without /api suffix for file downloads
  static String get fileBaseUrl {
    const overrideUrl = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: '',
    );
    if (overrideUrl.isNotEmpty) {
      // Remove /api suffix if present
      return overrideUrl.endsWith('/api')
          ? overrideUrl.substring(0, overrideUrl.length - 4)
          : overrideUrl;
    }

    if (environment == ApiEnvironment.production) {
      return 'https://trilink-backend-ms68.onrender.com';
    }
    return localBaseUrl.endsWith('/api')
        ? localBaseUrl.substring(0, localBaseUrl.length - 4)
        : localBaseUrl;
  }

  // Auth
  static const String login = '/auth/login';
  static const String refresh = '/auth/refresh';
  static const String me = '/auth/me';
  static const String changePassword = '/auth/change-password';

  // Users
  static const String updateProfile = '/users/me';

  // Dashboard
  static const String dashboardTeacher = '/dashboard/teacher';
  static const String dashboardParent = '/dashboard/parent';
  static const String dashboardStudent = '/dashboard/student';
  static String childSummary(String studentId) =>
      '/dashboard/children/$studentId/summary';

  // Academic years
  static const String activeAcademicYear = '/academic-years/active';

  // Class offerings
  static const String classOfferingsMine = '/class-offerings/mine';
  static String classOffering(String id) => '/class-offerings/$id';

  // Attendance
  static const String attendanceSessions = '/attendance-sessions';
  static String attendanceMarks(String sessionId) =>
      '/attendance-sessions/$sessionId/marks';
  static String attendanceStudentReport(String studentId) =>
      '/reports/attendance/student/$studentId';
  static String attendanceClassReport(String classOfferingId) =>
      '/reports/attendance/class/$classOfferingId';

  // Calendar
  static const String calendarEvents = '/calendar-events';

  // Announcements
  static const String announcements = '/announcements';
  static const String announcementsForMe = '/announcements/for-me';

  // Exams
  static const String exams = '/exams';
  static String exam(String id) => '/exams/$id';
  static String examQuestions(String examId) => '/exams/$examId/questions';
  static String examPublish(String examId) => '/exams/$examId/publish';
  static String examAttempts(String examId) => '/exams/$examId/attempts';
  static String examResultsExport(String examId) =>
      '/exams/$examId/results/export';

  // Questions bank
  static const String questions = '/questions';

  // Assignments
  static const String assignmentsMe = '/assignments/me';
  static String assignmentById(String id) => '/assignments/$id';
  static String assignmentSubmission(String id) =>
      '/assignments/$id/submissions';

  // Attempts
  static String attemptGrade(String id) => '/attempts/$id/grade';
  static String attemptRelease(String id) => '/attempts/$id/release';
  static String attemptForGrader(String id) => '/attempts/$id/for-grader';
  static String attemptResult(String id) => '/attempts/$id/result';
  static String attemptAnswers(String id) => '/attempts/$id/answers';
  static String attemptSubmit(String id) => '/attempts/$id/submit';

  // Notifications
  static const String notifications = '/notifications';
  static String notificationRead(String id) => '/notifications/$id/read';
  static String notificationUnread(String id) => '/notifications/$id/unread';
  static const String notificationsReadAll = '/notifications/read-all';

  // Chat
  static const String chatWsInfo = '/chat/ws-info';
  static const String conversations = '/conversations';
  static String conversation(String id) => '/conversations/$id';
  static String conversationMessages(String id) =>
      '/conversations/$id/messages';
  static String messageReadReceipts(String id) => '/messages/$id/read-receipts';

  // Settings
  static const String userSettings = '/me/settings';
  static const String schoolSettings = '/school/settings';
  static const String studentSyncStatus = '/sync/student/status';
  static const String studentSyncTrigger = '/sync/student/trigger';
  static const String integrationsSyncHints = '/integrations/sync-hints';

  // Feedback
  static const String feedback = '/feedback';
  static const String feedbackMe = '/feedback/me';

  // Reports
  static String studentPerformance(String studentId) =>
      '/reports/students/$studentId/performance';
  static String studentCompare(String studentId) =>
      '/reports/students/$studentId/compare';
  static String studentMastery(String studentId) =>
      '/reports/students/$studentId/mastery';
  static const String parentWeeklySummary = '/reports/parent/weekly-summary';

  // Files
  static const String filesUpload = '/files/upload';
  static String file(String id) => '/files/$id';
  static String fileAccess(String id) => '/files/$id/access';

  // Gamification
  static const String gamificationBadges = '/gamification/badges';
  static const String gamificationMyBadges = '/gamification/me/badges';
  static const String gamificationMyPoints = '/gamification/me/badge-points';
  static const String gamificationMyProgress = '/gamification/me/progress';
  static const String gamificationLeaderboard =
      '/gamification/leaderboard/exam-average';
  static String studentBadges(String studentId) =>
      '/gamification/students/$studentId/badges';

  // Student profiles
  static const String myProfile = '/student-profiles/me';
  static String studentProfile(String userId) => '/student-profiles/$userId';

  // AI
  static String aiRecommendations(String studentId) =>
      '/ai/students/$studentId/recommendations';
  static String aiLearningPath(String studentId) =>
      '/ai/students/$studentId/learning-path';
  static const String aiFeedbackAssistant = '/ai/feedback-assistant';

  // Textbooks
  static const String textbooks = '/textbooks';
  static String textbook(String id) => '/textbooks/$id';

  // Learning Materials (teacher resources)
  static const String learningMaterialsMe = '/learning-materials/student/me';
  static String learningMaterial(String id) => '/learning-materials/$id';

  // AI/ML Endpoints
  static const String aiChat = '/ai/chat';
  static String aiChatHistory(String studentId) => '/ai/chat/history/$studentId';
  static String aiRecommendations(String studentId) => '/ai/students/$studentId/recommendations';
  static String aiLearningPath(String studentId) => '/ai/students/$studentId/learning-path';
  static const String aiMasteryUpdate = '/ai/mastery/update';
  static String aiMastery(String studentId, String topicId) => '/ai/mastery/$studentId/$topicId';
  static String aiWeakTopics(String studentId, String subjectId) => '/ai/mastery/$studentId/weak/$subjectId';
  static String aiNextQuestion(String studentId, String topicId) => '/ai/content/next-question/$studentId/$topicId';
  static String aiWeeklySummary(String studentId) => '/ai/analytics/student/$studentId/weekly-summary';
  static String aiEvaluate(String studentId) => '/ai/students/$studentId/evaluate';

  // ═══════════════════════════════════════════════════════
  // ─── PARENT-SPECIFIC ENDPOINTS ─────────────────────────
  // ═══════════════════════════════════════════════════════

  // Parent-Children Links
  static const String myChildren = '/parent-students/mychildren';

  // Child Academic Data
  static String childEnrollments(String studentId) =>
      '/enrollments/children/$studentId';
  static String childGoals(String studentId) => '/goals/students/$studentId';
  static const String myGoals = '/goals/me';
  static String goalById(String goalId) => '/goals/$goalId';

  // Student reports
  static String studentReport(String studentId) =>
      '/reports/students/$studentId/report';
}
