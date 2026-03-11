class ApiConstants {
  ApiConstants._();

  static const String baseUrl = 'https://api.trilink.com';

  // Auth
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String logout = '/auth/logout';
  static const String refreshToken = '/auth/refresh';

  // Student
  static const String studentDashboard = '/student/dashboard';
  static const String studentGrades = '/student/grades';
  static const String studentAttendance = '/student/attendance';
  static const String studentAnnouncements = '/student/announcements';
  static const String studentNotifications = '/student/notifications';
  static const String studentFeedback = '/student/feedback';
  static const String studentGameData = '/student/gamification';

  // Teacher
  static const String teacherDashboard = '/teacher/dashboard';
  static const String teacherAttendance = '/teacher/attendance';
  static const String teacherAnnouncements = '/teacher/announcements';
  static const String teacherExams = '/teacher/exams';
  static const String teacherStudentAnalytics = '/teacher/student-analytics';

  // Parent
  static const String parentAttendance = '/parent/attendance';
  static const String parentStudentInfo = '/parent/student-info';

  // Chat
  static const String chatMessages = '/chat/messages';
  static const String chatGroups = '/chat/groups';
  static const String chatInbox = '/chat/inbox';

  // AI Assistant
  static const String aiLearningPath = '/ai/learning-path';
  static const String aiResources = '/ai/resources';
  static const String aiEvaluate = '/ai/evaluate';

  // Calendar
  static const String calendarEvents = '/calendar/events';
}
