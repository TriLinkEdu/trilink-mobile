import '../models/notification_model.dart';

abstract class StudentNotificationsRepository {
  Future<List<NotificationModel>> fetchNotifications();
  Future<void> markAsRead(String id);
  Future<void> markAsUnread(String id);
  Future<void> markAllAsRead();
}
