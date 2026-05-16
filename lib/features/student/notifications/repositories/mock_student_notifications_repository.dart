import '../../../../core/routes/route_names.dart';
import '../models/notification_model.dart';
import 'student_notifications_repository.dart';

class MockStudentNotificationsRepository
    implements StudentNotificationsRepository {
  static const Duration _latency = Duration(milliseconds: 350);

  static final List<NotificationModel> _notifications = [
    NotificationModel(
      id: 'n1',
      title: 'Assignment Graded',
      body: 'Your "Themes in Hamlet" essay has been graded. You scored 88/100.',
      type: 'academic',
      isRead: false,
      createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
      routeName: RouteNames.studentAssignmentDetail,
      routeArgs: {'assignmentId': 'a3'},
    ),
    NotificationModel(
      id: 'n2',
      title: 'New Course Resource',
      body:
          'Prof. Williams uploaded "Thermodynamics Reference Sheet" for Physics.',
      type: 'academic',
      isRead: false,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      routeName: RouteNames.studentCourseResources,
      routeArgs: {'subjectId': 'physics', 'subjectName': 'Physics'},
    ),
    NotificationModel(
      id: 'n3',
      title: 'Exam Reminder',
      body: 'Your Calculus Midterm is scheduled in 5 days. Start preparing!',
      type: 'academic',
      isRead: false,
      createdAt: DateTime.now().subtract(const Duration(hours: 6)),
      routeName: RouteNames.studentExamAttempt,
      routeArgs: {'examId': 'e1'},
    ),
    NotificationModel(
      id: 'n4',
      title: 'Fee Payment Due',
      body: 'Your semester fee payment is due by the end of this month.',
      type: 'administrative',
      isRead: true,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    NotificationModel(
      id: 'n5',
      title: 'New Message',
      body: 'Alice Chen sent a message in Physics Study Group.',
      type: 'social',
      isRead: false,
      createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
      routeName: RouteNames.studentChatConversation,
      routeArgs: {'conversationId': 'conv1', 'title': 'Physics Study Group'},
    ),
    NotificationModel(
      id: 'n6',
      title: 'Campus Career Fair',
      body:
          'Don\'t miss the annual career fair on the 12th at the Student Union.',
      type: 'administrative',
      isRead: true,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      routeName: RouteNames.studentCalendarEventDetail,
      routeArgs: {'eventId': 'ev4'},
    ),
    NotificationModel(
      id: 'n7',
      title: 'Assignment Overdue',
      body: 'Your "Newton\'s Laws Lab Report" is past the due date.',
      type: 'academic',
      isRead: false,
      createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 3)),
      routeName: RouteNames.studentAssignmentDetail,
      routeArgs: {'assignmentId': 'a2'},
    ),
    NotificationModel(
      id: 'n8',
      title: 'Library Book Due',
      body: 'The book "Advanced Calculus" is due for return tomorrow.',
      type: 'administrative',
      isRead: true,
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
    NotificationModel(
      id: 'n9',
      title: 'Study Group Invitation',
      body: 'Bob Martinez invited you to join "History Review Group".',
      type: 'social',
      isRead: false,
      createdAt: DateTime.now().subtract(const Duration(hours: 8)),
    ),
    NotificationModel(
      id: 'n10',
      title: 'Schedule Change',
      body:
          'Your Literature Discussion on the 10th has been moved to Room 210.',
      type: 'administrative',
      isRead: true,
      createdAt: DateTime.now().subtract(const Duration(days: 2, hours: 5)),
      routeName: RouteNames.studentCalendarEventDetail,
      routeArgs: {'eventId': 'ev3'},
    ),
  ];

  @override
  Future<List<NotificationModel>> fetchNotifications() async {
    await Future<void>.delayed(_latency);
    return List<NotificationModel>.from(_notifications);
  }

  @override
  Future<void> markAsRead(String id) async {
    await Future<void>.delayed(_latency);
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
    }
  }

  @override
  Future<void> markAsUnread(String id) async {
    await Future<void>.delayed(_latency);
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: false);
    }
  }

  @override
  Future<void> markAllAsRead() async {
    await Future<void>.delayed(_latency);
    for (int i = 0; i < _notifications.length; i++) {
      if (!_notifications[i].isRead) {
        _notifications[i] = _notifications[i].copyWith(isRead: true);
      }
    }
  }

  @override
  void clearCache() {}
}
