import '../network/api_client.dart';
import '../constants/api_constants.dart';
import 'dummy_data.dart';
import 'feature_flags.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

/// Centralized service wrapping all backend API calls.
/// Falls back to dummy data when the API is unreachable or returns errors.
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final ApiClient _api = ApiClient();

  Future<T> _tryOr<T>(Future<T> Function() apiCall, T fallback) async {
    // Use feature flag to determine behavior
    if (!FeatureFlags.useRealApi) {
      if (FeatureFlags.verboseLogging) {
        print('[API] Using mock data (FeatureFlags.useRealApi = false)');
      }
      return fallback;
    }

    // Simulate slow network if enabled
    if (FeatureFlags.simulateSlowNetwork) {
      await Future.delayed(Duration(milliseconds: FeatureFlags.networkDelayMs));
    }

    // Try real API, fallback to mock on error
    try {
      if (FeatureFlags.verboseLogging) {
        print('[API] Attempting real API call...');
      }
      final result = await apiCall();
      if (FeatureFlags.verboseLogging) {
        print('[API] Real API call succeeded');
      }
      return result;
    } catch (e) {
      if (FeatureFlags.verboseLogging) {
        print('[API] Real API call failed: $e, using mock data');
      }
      return fallback;
    }
  }

  // ─── Dashboard ──────────────────────────────────────────
  Future<Map<String, dynamic>> getTeacherDashboard() => _tryOr(
    () => _api.get(ApiConstants.dashboardTeacher),
    DummyData.teacherDashboard,
  );

  Future<Map<String, dynamic>> getParentDashboard() => _tryOr(
    () => _api.get(ApiConstants.dashboardParent),
    DummyData.parentDashboard,
  );

  Future<Map<String, dynamic>> getChildSummary(String studentId) => _tryOr(
    () => _api.get(ApiConstants.childSummary(studentId)),
    DummyData.childSummary(studentId),
  );

  // ─── Academic year ──────────────────────────────────────
  Future<Map<String, dynamic>> getActiveAcademicYear() => _tryOr(
    () => _api.get(ApiConstants.activeAcademicYear),
    DummyData.activeAcademicYear,
  );

  // ─── Class offerings ────────────────────────────────────
  Future<List<dynamic>> getMyClassOfferings(String academicYearId) => _tryOr(
    () => _api.getList(
      ApiConstants.classOfferingsMine,
      queryParameters: {'academicYearId': academicYearId},
    ),
    DummyData.classOfferings,
  );

  Future<Map<String, dynamic>> getClassOffering(String id) => _tryOr(
    () => _api.get(ApiConstants.classOffering(id)),
    DummyData.classOfferings.firstWhere(
      (c) => c['id'] == id,
      orElse: () => DummyData.classOfferings.first,
    ),
  );

  // ─── Attendance ─────────────────────────────────────────
  Future<List<dynamic>> getAttendanceSessions({
    required String classOfferingId,
  }) => _tryOr(
    () => _api.getList(
      ApiConstants.attendanceSessions,
      queryParameters: {'classOfferingId': classOfferingId},
    ),
    DummyData.attendanceSessions(classOfferingId),
  );

  Future<Map<String, dynamic>> createAttendanceSession({
    required String classOfferingId,
    required String date,
  }) => _tryOr(
    () => _api.post(
      ApiConstants.attendanceSessions,
      data: {'classOfferingId': classOfferingId, 'date': date},
    ),
    {'id': 'new-session', 'classOfferingId': classOfferingId, 'date': date},
  );

  Future<Map<String, dynamic>> saveAttendanceMarks(
    String sessionId,
    List<Map<String, dynamic>> marks,
  ) => _tryOr(
    () => _api.put(ApiConstants.attendanceMarks(sessionId), data: {'marks': marks}),
    {'ok': true},
  );

  Future<List<dynamic>> getAttendanceMarks(String sessionId) => _tryOr(
    () => _api.getList(ApiConstants.attendanceMarks(sessionId)),
    DummyData.attendanceMarks,
  );

  Future<Map<String, dynamic>> getStudentAttendanceReport(String studentId) =>
      _tryOr(
        () => _api.get(ApiConstants.attendanceStudentReport(studentId)),
        DummyData.studentAttendanceReport(studentId),
      );

  Future<Map<String, dynamic>> getClassAttendanceReport(
    String classOfferingId,
  ) => _tryOr(
    () => _api.get(ApiConstants.attendanceClassReport(classOfferingId)),
    DummyData.classAttendanceReport,
  );

  // ─── Calendar ───────────────────────────────────────────
  Future<List<dynamic>> getCalendarEvents({Map<String, dynamic>? filters}) =>
      _tryOr(
        () =>
            _api.getList(ApiConstants.calendarEvents, queryParameters: filters),
        DummyData.calendarEvents,
      );

  Future<Map<String, dynamic>> createCalendarEvent(Map<String, dynamic> data) =>
      _tryOr(() => _api.post(ApiConstants.calendarEvents, data: data), {
        'id': 'new-event',
        ...data,
      });

  Future<Map<String, dynamic>> updateCalendarEvent(
    String id,
    Map<String, dynamic> data,
  ) => _tryOr(
    () => _api.patch('${ApiConstants.calendarEvents}/$id', data: data),
    {'id': id, ...data},
  );

  // ─── Announcements ─────────────────────────────────────
  Future<List<dynamic>> getAnnouncements({Map<String, dynamic>? filters}) =>
      _tryOr(
        () =>
            _api.getList(ApiConstants.announcements, queryParameters: filters),
        DummyData.announcements,
      );

  Future<List<dynamic>> getAnnouncementsForMe() => _tryOr(
    () => _api.getList(ApiConstants.announcementsForMe),
    DummyData.announcements,
  );

  Future<Map<String, dynamic>> createAnnouncement(Map<String, dynamic> data) =>
      _tryOr(() => _api.post(ApiConstants.announcements, data: data), {
        'id': 'new-ann',
        ...data,
        'createdAt': DateTime.now().toIso8601String(),
      });

  Future<Map<String, dynamic>> updateAnnouncement(
    String id,
    Map<String, dynamic> data,
  ) => _tryOr(
    () => _api.patch('${ApiConstants.announcements}/$id', data: data),
    {'id': id, ...data},
  );

  // ─── Exams ──────────────────────────────────────────────
  Future<List<dynamic>> getExams({Map<String, dynamic>? filters}) => _tryOr(
    () => _api.getList(ApiConstants.exams, queryParameters: filters),
    DummyData.exams,
  );

  Future<Map<String, dynamic>> createExam(Map<String, dynamic> data) => _tryOr(
    () => _api.post(ApiConstants.exams, data: data),
    {'id': 'new-exam', ...data, 'status': data['status'] ?? 'draft'},
  );

  Future<Map<String, dynamic>> updateExam(
    String id,
    Map<String, dynamic> data,
  ) => _tryOr(() => _api.patch(ApiConstants.exam(id), data: data), {
    'id': id,
    ...data,
  });

  Future<Map<String, dynamic>> publishExam(String examId) => _tryOr(
    () => _api.post(ApiConstants.examPublish(examId)),
    {'id': examId, 'status': 'published'},
  );

  Future<List<dynamic>> getExamQuestions(String examId) => _tryOr(
    () => _api.getList(ApiConstants.examQuestions(examId)),
    DummyData.questions,
  );

  Future<Map<String, dynamic>> addExamQuestions(
    String examId,
    List<String> questionIds,
  ) => _tryOr(
    () => _api.post(ApiConstants.examQuestions(examId), data: questionIds),
    {'ok': true},
  );

  Future<List<dynamic>> getExamAttempts(String examId) => _tryOr(
    () => _api.getList(ApiConstants.examAttempts(examId)),
    DummyData.examAttempts,
  );

  // ─── Questions bank ─────────────────────────────────────
  Future<List<dynamic>> getQuestions({String? subjectId}) => _tryOr(
    () => _api.getList(
      ApiConstants.questions,
      queryParameters: subjectId != null ? {'subjectId': subjectId} : null,
    ),
    DummyData.questions,
  );

  Future<Map<String, dynamic>> createQuestion(Map<String, dynamic> data) =>
      _tryOr(() => _api.post(ApiConstants.questions, data: data), {
        'id': 'new-q',
        ...data,
      });

  // ─── Attempts / grading ─────────────────────────────────
  Future<Map<String, dynamic>> getAttemptForGrader(String attemptId) => _tryOr(
    () => _api.get(ApiConstants.attemptForGrader(attemptId)),
    DummyData.attemptForGrader(attemptId),
  );

  Future<Map<String, dynamic>> gradeAttempt(
    String attemptId,
    Map<String, dynamic> data,
  ) => _tryOr(
    () => _api.post(ApiConstants.attemptGrade(attemptId), data: data),
    {'ok': true, 'attemptId': attemptId, ...data},
  );

  Future<Map<String, dynamic>> releaseAttempt(String attemptId) =>
      _tryOr(() => _api.post(ApiConstants.attemptRelease(attemptId)), {
        'ok': true,
        'attemptId': attemptId,
        'releasedAt': DateTime.now().toIso8601String(),
      });

  Future<Map<String, dynamic>> getAttemptResult(String attemptId) => _tryOr(
    () => _api.get(ApiConstants.attemptResult(attemptId)),
    DummyData.attemptResult(attemptId),
  );

  // ─── Notifications ──────────────────────────────────────
  Future<List<dynamic>> getNotifications() => _tryOr(
    () => _api.getList(ApiConstants.notifications),
    DummyData.notifications,
  );

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
  Future<List<dynamic>> getConversations() => _tryOr(
    () => _api.getList(ApiConstants.conversations),
    DummyData.conversations,
  );

  Future<Map<String, dynamic>> createConversation(Map<String, dynamic> data) =>
      _tryOr(() => _api.post(ApiConstants.conversations, data: data), {
        'id': 'new-conv',
        ...data,
        'createdAt': DateTime.now().toIso8601String(),
      });

  Future<Map<String, dynamic>> getConversation(String id) => _tryOr(
    () => _api.get(ApiConstants.conversation(id)),
    DummyData.conversations.firstWhere(
      (c) => c['id'] == id,
      orElse: () => DummyData.conversations.first,
    ),
  );

  Future<List<dynamic>> getMessages(String conversationId) => _tryOr(
    () => _api.getList(ApiConstants.conversationMessages(conversationId)),
    DummyData.messages(conversationId),
  );

  Future<Map<String, dynamic>> sendMessage(
    String conversationId,
    Map<String, dynamic> data,
  ) => _tryOr(
    () => _api.post(
      ApiConstants.conversationMessages(conversationId),
      data: data,
    ),
    {
      'id': 'new-msg',
      'conversationId': conversationId,
      ...data,
      'createdAt': DateTime.now().toIso8601String(),
    },
  );

  // ─── Settings ───────────────────────────────────────────
  Future<Map<String, dynamic>> getUserSettings() =>
      _tryOr(() => _api.get(ApiConstants.userSettings), DummyData.userSettings);

  Future<Map<String, dynamic>> updateUserSettings(Map<String, dynamic> data) =>
      _tryOr(() => _api.patch(ApiConstants.userSettings, data: data), {
        ...DummyData.userSettings,
        ...data,
      });

  /// Change user password
  Future<void> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    await _tryOr(() async {
      await _api.post(
        ApiConstants.changePassword,
        data: {'currentPassword': currentPassword, 'newPassword': newPassword},
      );
      return true;
    }, true);
  }

  /// Update user profile
  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    print('DEBUG API: updateProfile called with data: $data');
    return await _tryOr(() async {
      print('DEBUG API: Making PATCH request to ${ApiConstants.updateProfile}');
      final response = await _api.patch(ApiConstants.updateProfile, data: data);
      print('DEBUG API: Received response: $response');
      return response;
    }, {...data}); // Return the input data as mock response
  }

  /// Upload profile image and return uploaded file id.
  Future<String> uploadProfileImage(dynamic file) async {
    if (!FeatureFlags.useRealApi) {
      return 'mock-profile-image-file-id';
    }

    try {
      List<int> bytes;
      String filename = 'profile.jpg';

      if (file is XFile) {
        bytes = await file.readAsBytes();
        if (file.name.isNotEmpty) {
          filename = file.name;
        }
      } else {
        final dynamic readAsBytes = file.readAsBytes;
        if (readAsBytes is! Function) {
          throw Exception('Selected image cannot be read.');
        }
        bytes = await readAsBytes();
        final dynamic rawPath = file.path;
        if (rawPath is String && rawPath.trim().isNotEmpty) {
          final segments = rawPath.split(RegExp(r'[\\/]'));
          final last = segments.isNotEmpty ? segments.last : '';
          if (last.isNotEmpty) {
            filename = last;
          }
        }
      }

      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: filename),
      });

      final response = await _api.post(
        ApiConstants.filesUpload,
        data: formData,
      );

      final topLevelId = response['id'];
      if (topLevelId is String && topLevelId.isNotEmpty) return topLevelId;

      final fileId = response['fileId'];
      if (fileId is String && fileId.isNotEmpty) return fileId;

      final nestedData = response['data'];
      if (nestedData is Map<String, dynamic>) {
        final nestedId = nestedData['id'];
        if (nestedId is String && nestedId.isNotEmpty) return nestedId;

        final nestedFileId = nestedData['fileId'];
        if (nestedFileId is String && nestedFileId.isNotEmpty) {
          return nestedFileId;
        }
      }

      throw Exception('Upload succeeded but file id was not returned.');
    } catch (e) {
      rethrow;
    }
  }

  // ─── Feedback ───────────────────────────────────────────
  Future<Map<String, dynamic>> submitFeedback(Map<String, dynamic> data) =>
      _tryOr(
        () => _api.post(ApiConstants.feedback, data: data),
        DummyData.feedbackResponse,
      );

  // ─── Reports ────────────────────────────────────────────
  Future<Map<String, dynamic>> getStudentPerformance(String studentId) =>
      _tryOr(
        () => _api.get(ApiConstants.studentPerformance(studentId)),
        DummyData.studentPerformance(studentId),
      );

  Future<Map<String, dynamic>> getStudentCompare(
    String studentId, {
    Map<String, dynamic>? params,
  }) => _tryOr(
    () => _api.get(
      ApiConstants.studentCompare(studentId),
      queryParameters: params,
    ),
    DummyData.studentCompare(studentId),
  );

  Future<Map<String, dynamic>> getParentWeeklySummary() => _tryOr(
    () => _api.get(ApiConstants.parentWeeklySummary),
    DummyData.parentWeeklySummary,
  );

  // ─── Student profiles ──────────────────────────────────
  Future<Map<String, dynamic>> getStudentProfile(String userId) => _tryOr(
    () => _api.get(ApiConstants.studentProfile(userId)),
    DummyData.studentProfile(userId),
  );

  // ─── Gamification ──────────────────────────────────────
  Future<List<dynamic>> getLeaderboard() =>
      _tryOr(() => _api.getList(ApiConstants.gamificationLeaderboard), []);

  Future<List<dynamic>> getStudentBadges(String studentId) =>
      _tryOr(() => _api.getList(ApiConstants.studentBadges(studentId)), []);

  Future<Map<String, dynamic>> awardBadge(String userId, String badgeId) =>
      _tryOr(() => _api.post('/gamification/users/$userId/badges/$badgeId'), {
        'ok': true,
      });

  // ─── AI ─────────────────────────────────────────────────
  Future<Map<String, dynamic>> getAiRecommendations(String studentId) => _tryOr(
    () => _api.get(ApiConstants.aiRecommendations(studentId)),
    {'recommendations': []},
  );

  Future<Map<String, dynamic>> getAiLearningPath(String studentId) => _tryOr(
    () => _api.get(ApiConstants.aiLearningPath(studentId)),
    {'learningPath': []},
  );

  // ═══════════════════════════════════════════════════════
  // ─── PARENT-SPECIFIC ENDPOINTS ─────────────────────────
  // ═══════════════════════════════════════════════════════

  /// Get list of children linked to current parent
  Future<List<dynamic>> getMyChildren() =>
      _tryOr(() => _api.getList(ApiConstants.myChildren), DummyData.myChildren);

  /// Get child enrollments (classes)
  Future<List<dynamic>> getChildEnrollments(String studentId) => _tryOr(
    () => _api.getList(ApiConstants.childEnrollments(studentId)),
    DummyData.childEnrollments(studentId),
  );

  /// Get child goals
  Future<List<dynamic>> getChildGoals(String studentId) => _tryOr(
    () => _api.getList(ApiConstants.childGoals(studentId)),
    DummyData.childGoals(studentId),
  );

  /// Get parent-specific notifications
  Future<List<dynamic>> getParentNotifications({bool? unreadOnly}) => _tryOr(
    () => _api.getList(
      ApiConstants.notifications,
      queryParameters: unreadOnly != null ? {'unreadOnly': unreadOnly} : null,
    ),
    DummyData.parentNotifications,
  );

  /// Get parent-specific announcements
  Future<List<dynamic>> getParentAnnouncements() => _tryOr(
    () => _api.getList(ApiConstants.announcementsForMe),
    DummyData.parentAnnouncements,
  );

  /// Get child performance report
  Future<Map<String, dynamic>> getChildPerformanceReport(String studentId) =>
      _tryOr(
        () => _api.get(ApiConstants.studentPerformance(studentId)),
        DummyData.childPerformanceReport(studentId),
      );

  /// Get period comparison report
  Future<Map<String, dynamic>> getPeriodComparisonReport(
    String studentId, {
    required String period1Start,
    required String period1End,
    required String period2Start,
    required String period2End,
  }) => _tryOr(
    () => _api.get(
      ApiConstants.studentCompare(studentId),
      queryParameters: {
        'period1Start': period1Start,
        'period1End': period1End,
        'period2Start': period2Start,
        'period2End': period2End,
      },
    ),
    DummyData.periodComparisonReport(studentId),
  );

  /// Get weekly parent summary
  Future<Map<String, dynamic>> getWeeklyParentSummary({
    String? childStudentId,
  }) => _tryOr(
    () => _api.get(
      ApiConstants.parentWeeklySummary,
      queryParameters: childStudentId != null
          ? {'childStudentId': childStudentId}
          : null,
    ),
    DummyData.weeklyParentSummary(childStudentId: childStudentId),
  );

  /// Get parent calendar events
  Future<List<dynamic>> getParentCalendarEvents({
    String? from,
    String? to,
    String? academicYearId,
    String? classOfferingId,
  }) => _tryOr(
    () => _api.getList(
      ApiConstants.calendarEvents,
      queryParameters: {
        if (from != null) 'from': from,
        if (to != null) 'to': to,
        if (academicYearId != null) 'academicYearId': academicYearId,
        if (classOfferingId != null) 'classOfferingId': classOfferingId,
      },
    ),
    DummyData.parentCalendarEvents,
  );

  /// Get child exam results
  Future<List<dynamic>> getChildExamResults(String studentId) => _tryOr(
    () => _api.getList('/attempts/student/$studentId/results'),
    DummyData.childExamResults(studentId),
  );

  /// Get student detail (profile + classes + teachers)
  Future<Map<String, dynamic>> getStudentDetail(String studentUserId) =>
      _tryOr(() => _api.get(ApiConstants.studentDetail(studentUserId)), {});

  /// Get comprehensive student report (weekly/monthly/custom)
  Future<Map<String, dynamic>> getStudentReport(
    String studentId, {
    String periodType = 'monthly',
    String? startDate,
    String? endDate,
  }) =>
      _tryOr(
        () => _api.get(
          ApiConstants.studentReport(studentId),
          queryParameters: {
            'periodType': periodType,
            if (startDate != null) 'startDate': startDate,
            if (endDate != null) 'endDate': endDate,
          },
        ),
        {},
      );

  /// Get teachers for a student
  Future<Map<String, dynamic>> getStudentTeachers(String studentId) =>
      _tryOr(() => _api.get(ApiConstants.studentTeachers(studentId)), {});
  
  /// Get enrollments for a class offering (teacher use)
  Future<List<dynamic>> getClassEnrollments(String classOfferingId) =>
      _tryOr(
        () => _api.getList(
          ApiConstants.enrollments,
          queryParameters: {'classOfferingId': classOfferingId},
        ),
        [],
      );

  /// Search users (for messaging)
  Future<List<dynamic>> searchUsers({String? role, String? q}) =>
      _tryOr(() => _api.getList(ApiConstants.usersSearch, queryParameters: {
        if (role != null) 'role': role,
        if (q != null) 'q': q,
      }), []);

  /// Initiate conversation with a user
  Future<Map<String, dynamic>> initiateConversation(String targetUserId) =>
      _tryOr(() => _api.post(ApiConstants.conversationsInitiate, data: {
        'targetUserId': targetUserId,
      }), {
        'conversation': {
          'id': 'mock-conversation-id',
          'type': 'direct',
          'title': 'Mock Conversation',
          'createdAt': DateTime.now().toIso8601String(),
        },
        'isNew': true,
      });

  /// Get messages from conversation
  Future<List<dynamic>> getConversationMessages(String conversationId, {int? limit, int? skip}) =>
      _tryOr(() => _api.getList(ApiConstants.conversationMessages(conversationId), queryParameters: {
        if (limit != null) 'limit': limit.toString(),
        if (skip != null) 'skip': skip.toString(),
      }), []);
}
