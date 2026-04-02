import '../network/api_client.dart';
import '../constants/api_constants.dart';
import 'dummy_data.dart';

/// Set to false to force dummy data without trying the API.
/// Set to true to try API first, fallback to dummy on failure.
const bool _tryApiFirst = true;

/// Centralized service wrapping all backend API calls.
/// Falls back to dummy data when the API is unreachable or returns errors.
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final ApiClient _api = ApiClient();

  Future<T> _tryOr<T>(Future<T> Function() apiCall, T fallback) async {
    if (!_tryApiFirst) return fallback;
    try {
      return await apiCall();
    } catch (_) {
      return fallback;
    }
  }

  // ─── Dashboard ──────────────────────────────────────────
  Future<Map<String, dynamic>> getTeacherDashboard() =>
      _tryOr(() => _api.get(ApiConstants.dashboardTeacher),
          DummyData.teacherDashboard);

  Future<Map<String, dynamic>> getParentDashboard() =>
      _tryOr(() => _api.get(ApiConstants.dashboardParent),
          DummyData.parentDashboard);

  Future<Map<String, dynamic>> getChildSummary(String studentId) =>
      _tryOr(() => _api.get(ApiConstants.childSummary(studentId)),
          DummyData.childSummary(studentId));

  // ─── Academic year ──────────────────────────────────────
  Future<Map<String, dynamic>> getActiveAcademicYear() =>
      _tryOr(() => _api.get(ApiConstants.activeAcademicYear),
          DummyData.activeAcademicYear);

  // ─── Class offerings ────────────────────────────────────
  Future<List<dynamic>> getMyClassOfferings(String academicYearId) =>
      _tryOr(
          () => _api.getList(ApiConstants.classOfferingsMine,
              queryParameters: {'academicYearId': academicYearId}),
          DummyData.classOfferings);

  Future<Map<String, dynamic>> getClassOffering(String id) =>
      _tryOr(() => _api.get(ApiConstants.classOffering(id)),
          DummyData.classOfferings.firstWhere(
              (c) => c['id'] == id,
              orElse: () => DummyData.classOfferings.first));

  // ─── Attendance ─────────────────────────────────────────
  Future<List<dynamic>> getAttendanceSessions({
    required String classOfferingId,
  }) =>
      _tryOr(
          () => _api.getList(ApiConstants.attendanceSessions,
              queryParameters: {'classOfferingId': classOfferingId}),
          DummyData.attendanceSessions(classOfferingId));

  Future<Map<String, dynamic>> createAttendanceSession({
    required String classOfferingId,
    required String date,
  }) =>
      _tryOr(
          () => _api.post(ApiConstants.attendanceSessions,
              data: {'classOfferingId': classOfferingId, 'date': date}),
          {'id': 'new-session', 'classOfferingId': classOfferingId, 'date': date});

  Future<Map<String, dynamic>> saveAttendanceMarks(
          String sessionId, List<Map<String, dynamic>> marks) =>
      _tryOr(
          () => _api.put(ApiConstants.attendanceMarks(sessionId), data: marks),
          {'ok': true});

  Future<List<dynamic>> getAttendanceMarks(String sessionId) =>
      _tryOr(() => _api.getList(ApiConstants.attendanceMarks(sessionId)),
          DummyData.attendanceMarks);

  Future<Map<String, dynamic>> getStudentAttendanceReport(String studentId) =>
      _tryOr(() => _api.get(ApiConstants.attendanceStudentReport(studentId)),
          DummyData.studentAttendanceReport(studentId));

  Future<Map<String, dynamic>> getClassAttendanceReport(
          String classOfferingId) =>
      _tryOr(
          () => _api.get(ApiConstants.attendanceClassReport(classOfferingId)),
          DummyData.classAttendanceReport);

  // ─── Calendar ───────────────────────────────────────────
  Future<List<dynamic>> getCalendarEvents(
          {Map<String, dynamic>? filters}) =>
      _tryOr(
          () => _api.getList(ApiConstants.calendarEvents,
              queryParameters: filters),
          DummyData.calendarEvents);

  Future<Map<String, dynamic>> createCalendarEvent(
          Map<String, dynamic> data) =>
      _tryOr(() => _api.post(ApiConstants.calendarEvents, data: data),
          {'id': 'new-event', ...data});

  Future<Map<String, dynamic>> updateCalendarEvent(
          String id, Map<String, dynamic> data) =>
      _tryOr(
          () => _api.patch('${ApiConstants.calendarEvents}/$id', data: data),
          {'id': id, ...data});

  // ─── Announcements ─────────────────────────────────────
  Future<List<dynamic>> getAnnouncements(
          {Map<String, dynamic>? filters}) =>
      _tryOr(
          () => _api.getList(ApiConstants.announcements,
              queryParameters: filters),
          DummyData.announcements);

  Future<List<dynamic>> getAnnouncementsForMe() =>
      _tryOr(() => _api.getList(ApiConstants.announcementsForMe),
          DummyData.announcements);

  Future<Map<String, dynamic>> createAnnouncement(
          Map<String, dynamic> data) =>
      _tryOr(() => _api.post(ApiConstants.announcements, data: data),
          {'id': 'new-ann', ...data, 'createdAt': DateTime.now().toIso8601String()});

  // ─── Exams ──────────────────────────────────────────────
  Future<List<dynamic>> getExams({Map<String, dynamic>? filters}) =>
      _tryOr(
          () => _api.getList(ApiConstants.exams, queryParameters: filters),
          DummyData.exams);

  Future<Map<String, dynamic>> createExam(Map<String, dynamic> data) =>
      _tryOr(() => _api.post(ApiConstants.exams, data: data),
          {'id': 'new-exam', ...data, 'status': data['status'] ?? 'draft'});

  Future<Map<String, dynamic>> updateExam(
          String id, Map<String, dynamic> data) =>
      _tryOr(() => _api.patch(ApiConstants.exam(id), data: data),
          {'id': id, ...data});

  Future<Map<String, dynamic>> publishExam(String examId) =>
      _tryOr(() => _api.post(ApiConstants.examPublish(examId)),
          {'id': examId, 'status': 'published'});

  Future<List<dynamic>> getExamQuestions(String examId) =>
      _tryOr(() => _api.getList(ApiConstants.examQuestions(examId)),
          DummyData.questions);

  Future<Map<String, dynamic>> addExamQuestions(
          String examId, List<String> questionIds) =>
      _tryOr(() => _api.post(ApiConstants.examQuestions(examId), data: questionIds),
          {'ok': true});

  Future<List<dynamic>> getExamAttempts(String examId) =>
      _tryOr(() => _api.getList(ApiConstants.examAttempts(examId)),
          DummyData.examAttempts);

  // ─── Questions bank ─────────────────────────────────────
  Future<List<dynamic>> getQuestions({String? subjectId}) =>
      _tryOr(
          () => _api.getList(ApiConstants.questions,
              queryParameters:
                  subjectId != null ? {'subjectId': subjectId} : null),
          DummyData.questions);

  Future<Map<String, dynamic>> createQuestion(Map<String, dynamic> data) =>
      _tryOr(() => _api.post(ApiConstants.questions, data: data),
          {'id': 'new-q', ...data});

  // ─── Attempts / grading ─────────────────────────────────
  Future<Map<String, dynamic>> getAttemptForGrader(String attemptId) =>
      _tryOr(() => _api.get(ApiConstants.attemptForGrader(attemptId)),
          DummyData.attemptForGrader(attemptId));

  Future<Map<String, dynamic>> gradeAttempt(
          String attemptId, Map<String, dynamic> data) =>
      _tryOr(() => _api.post(ApiConstants.attemptGrade(attemptId), data: data),
          {'ok': true, 'attemptId': attemptId, ...data});

  Future<Map<String, dynamic>> releaseAttempt(String attemptId) =>
      _tryOr(() => _api.post(ApiConstants.attemptRelease(attemptId)),
          {'ok': true, 'attemptId': attemptId, 'releasedAt': DateTime.now().toIso8601String()});

  Future<Map<String, dynamic>> getAttemptResult(String attemptId) =>
      _tryOr(() => _api.get(ApiConstants.attemptResult(attemptId)),
          DummyData.attemptResult(attemptId));

  // ─── Notifications ──────────────────────────────────────
  Future<List<dynamic>> getNotifications() =>
      _tryOr(() => _api.getList(ApiConstants.notifications),
          DummyData.notifications);

  Future<void> markNotificationRead(String id) async {
    await _tryOr(() async {
      await _api.patch(ApiConstants.notificationRead(id));
      return true;
    }, true);
  }

  Future<void> markAllNotificationsRead() async {
    await _tryOr(() async {
      await _api.post(ApiConstants.notificationsReadAll);
      return true;
    }, true);
  }

  // ─── Chat / Conversations ──────────────────────────────
  Future<List<dynamic>> getConversations() =>
      _tryOr(() => _api.getList(ApiConstants.conversations),
          DummyData.conversations);

  Future<Map<String, dynamic>> createConversation(
          Map<String, dynamic> data) =>
      _tryOr(() => _api.post(ApiConstants.conversations, data: data),
          {'id': 'new-conv', ...data, 'createdAt': DateTime.now().toIso8601String()});

  Future<Map<String, dynamic>> getConversation(String id) =>
      _tryOr(() => _api.get(ApiConstants.conversation(id)),
          DummyData.conversations.firstWhere(
              (c) => c['id'] == id,
              orElse: () => DummyData.conversations.first));

  Future<List<dynamic>> getMessages(String conversationId) =>
      _tryOr(
          () => _api.getList(ApiConstants.conversationMessages(conversationId)),
          DummyData.messages(conversationId));

  Future<Map<String, dynamic>> sendMessage(
          String conversationId, Map<String, dynamic> data) =>
      _tryOr(
          () => _api.post(ApiConstants.conversationMessages(conversationId),
              data: data),
          {'id': 'new-msg', 'conversationId': conversationId, ...data,
           'createdAt': DateTime.now().toIso8601String()});

  // ─── Settings ───────────────────────────────────────────
  Future<Map<String, dynamic>> getUserSettings() =>
      _tryOr(() => _api.get(ApiConstants.userSettings),
          DummyData.userSettings);

  Future<Map<String, dynamic>> updateUserSettings(
          Map<String, dynamic> data) =>
      _tryOr(() => _api.patch(ApiConstants.userSettings, data: data),
          {...DummyData.userSettings, ...data});

  // ─── Feedback ───────────────────────────────────────────
  Future<Map<String, dynamic>> submitFeedback(Map<String, dynamic> data) =>
      _tryOr(() => _api.post(ApiConstants.feedback, data: data),
          DummyData.feedbackResponse);

  // ─── Reports ────────────────────────────────────────────
  Future<Map<String, dynamic>> getStudentPerformance(String studentId) =>
      _tryOr(() => _api.get(ApiConstants.studentPerformance(studentId)),
          DummyData.studentPerformance(studentId));

  Future<Map<String, dynamic>> getStudentCompare(String studentId,
          {Map<String, dynamic>? params}) =>
      _tryOr(
          () => _api.get(ApiConstants.studentCompare(studentId),
              queryParameters: params),
          DummyData.studentCompare(studentId));

  Future<Map<String, dynamic>> getParentWeeklySummary() =>
      _tryOr(() => _api.get(ApiConstants.parentWeeklySummary),
          DummyData.parentWeeklySummary);

  // ─── Student profiles ──────────────────────────────────
  Future<Map<String, dynamic>> getStudentProfile(String userId) =>
      _tryOr(() => _api.get(ApiConstants.studentProfile(userId)),
          DummyData.studentProfile(userId));

  // ─── Gamification ──────────────────────────────────────
  Future<List<dynamic>> getLeaderboard() =>
      _tryOr(() => _api.getList(ApiConstants.gamificationLeaderboard), []);

  Future<List<dynamic>> getStudentBadges(String studentId) =>
      _tryOr(() => _api.getList(ApiConstants.studentBadges(studentId)), []);

  Future<Map<String, dynamic>> awardBadge(
          String userId, String badgeId) =>
      _tryOr(
          () => _api.post('/gamification/users/$userId/badges/$badgeId'),
          {'ok': true});

  // ─── AI ─────────────────────────────────────────────────
  Future<Map<String, dynamic>> getAiRecommendations(String studentId) =>
      _tryOr(() => _api.get(ApiConstants.aiRecommendations(studentId)),
          {'recommendations': []});

  Future<Map<String, dynamic>> getAiLearningPath(String studentId) =>
      _tryOr(() => _api.get(ApiConstants.aiLearningPath(studentId)),
          {'learningPath': []});
}
