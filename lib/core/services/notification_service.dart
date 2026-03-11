/// Push notification service.
/// TODO: Implement with firebase_messaging or similar.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // TODO: Initialize, handle foreground/background notifications
}
