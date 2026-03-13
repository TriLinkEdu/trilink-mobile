class RouteNames {
  RouteNames._();

  // Auth
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String roleSelection = '/role-selection';

  // Student
  static const String studentDashboard = '/student/dashboard';
  static const String studentAnnouncements = '/student/announcements';
  static const String studentNotifications = '/student/notifications';
  static const String studentGrades = '/student/grades';
  static const String studentSubjectGrades = '/student/grades/subject';
  static const String studentAttendance = '/student/attendance';
  static const String studentChat = '/student/chat';
  static const String studentAiAssistant = '/student/ai-assistant';
  static const String studentFeedback = '/student/feedback';
  static const String studentGamification = '/student/gamification';
  static const String studentCalendar = '/student/calendar';
  static const String studentProfile = '/student/profile';
  static const String studentSettings = '/student/settings';

  // Teacher
  static const String teacherDashboard = '/teacher/dashboard';
  static const String teacherAttendance = '/teacher/attendance';
  static const String teacherMarkAttendance = '/teacher/attendance/mark';
  static const String teacherAnnouncements = '/teacher/announcements';
  static const String teacherCreateAnnouncement = '/teacher/announcements/create';
  static const String teacherExams = '/teacher/exams';
  static const String teacherCreateExam = '/teacher/exams/create';
  static const String teacherExamBank = '/teacher/exams/bank';
  static const String teacherLiveExam = '/teacher/exams/live';
  static const String teacherNotifications = '/teacher/notifications';
  static const String teacherStudentList = '/teacher/students';
  static const String teacherStudentAnalytics = '/teacher/student/analytics';
  static const String teacherCalendar = '/teacher/calendar';
  static const String teacherMessages = '/teacher/messages';
  static const String teacherSettings = '/teacher/settings';

  // Parent
  static const String parentHome = '/parent/home';
  static const String parentDashboard = '/parent/dashboard';
  static const String parentAttendance = '/parent/attendance';
  static const String parentResults = '/parent/results';
  static const String parentStudentInfo = '/parent/student-info';
  static const String parentChat = '/parent/chat';
  static const String parentProfile = '/parent/profile';
  static const String parentSettings = '/parent/settings';
}
