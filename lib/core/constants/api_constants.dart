class ApiConstants {
  ApiConstants._();

  static const String baseUrl = 'http://localhost:4000/api';

  // Auth
  static const String login = '/auth/login';
  static const String refresh = '/auth/refresh';
  static const String me = '/auth/me';
  static const String changePassword = '/auth/change-password';

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

  // Attempts
  static String attemptGrade(String id) => '/attempts/$id/grade';
  static String attemptRelease(String id) => '/attempts/$id/release';
  static String attemptForGrader(String id) => '/attempts/$id/for-grader';
  static String attemptResult(String id) => '/attempts/$id/result';

  // Notifications
  static const String notifications = '/notifications';
  static String notificationRead(String id) => '/notifications/$id/read';
  static const String notificationsReadAll = '/notifications/read-all';

  // Chat
  static const String chatWsInfo = '/chat/ws-info';
  static const String conversations = '/conversations';
  static String conversation(String id) => '/conversations/$id';
  static String conversationMessages(String id) =>
      '/conversations/$id/messages';

  // Settings
  static const String userSettings = '/me/settings';
  static const String schoolSettings = '/school/settings';

  // Feedback
  static const String feedback = '/feedback';

  // Reports
  static String studentPerformance(String studentId) =>
      '/reports/students/$studentId/performance';
  static String studentCompare(String studentId) =>
      '/reports/students/$studentId/compare';
  static const String parentWeeklySummary = '/reports/parent/weekly-summary';

  // Files
  static const String filesUpload = '/files/upload';
  static String file(String id) => '/files/$id';

  // Gamification
  static const String gamificationBadges = '/gamification/badges';
  static const String gamificationMyBadges = '/gamification/me/badges';
  static const String gamificationMyPoints = '/gamification/me/badge-points';
  static const String gamificationLeaderboard =
      '/gamification/leaderboard/exam-average';
  static String studentBadges(String studentId) =>
      '/gamification/students/$studentId/badges';

  // Student profiles
  static const String myProfile = '/student-profiles/me';
  static String studentProfile(String userId) =>
      '/student-profiles/$userId';

  // AI
  static String aiRecommendations(String studentId) =>
      '/ai/students/$studentId/recommendations';
  static String aiLearningPath(String studentId) =>
      '/ai/students/$studentId/learning-path';
  static const String aiFeedbackAssistant = '/ai/feedback-assistant';
}
