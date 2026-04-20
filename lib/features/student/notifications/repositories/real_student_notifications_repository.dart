import 'dart:convert';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/routes/route_names.dart';
import '../models/notification_model.dart';
import 'student_notifications_repository.dart';

class RealStudentNotificationsRepository
    implements StudentNotificationsRepository {
  final ApiClient _api;

  static List<NotificationModel>? _cache;
  static DateTime? _fetchedAt;
  static Future<List<NotificationModel>>? _inFlight;
  static const Duration _ttl = Duration(seconds: 20);

  RealStudentNotificationsRepository({ApiClient? apiClient})
    : _api = apiClient ?? ApiClient();

  @override
  Future<List<NotificationModel>> fetchNotifications() async {
    if (_cache != null && _fetchedAt != null) {
      final age = DateTime.now().difference(_fetchedAt!);
      if (age < _ttl) return _cache!;
    }

    if (_inFlight != null) return _inFlight!;

    final future = _fetchFresh();
    _inFlight = future;
    final data = await future;
    _inFlight = null;
    _cache = data;
    _fetchedAt = DateTime.now();
    return data;
  }

  Future<List<NotificationModel>> _fetchFresh() async {
    final list = await _api.getList(ApiConstants.notifications);

    return list.whereType<Map<String, dynamic>>().map(_toNotification).toList();
  }

  @override
  Future<void> markAsRead(String id) async {
    await _api.patch(ApiConstants.notificationRead(id));
  }

  @override
  Future<void> markAsUnread(String id) async {
    // Backend currently supports read + read-all only.
    // Keep this as a no-op to avoid breaking UI toggle flows.
    return;
  }

  @override
  Future<void> markAllAsRead() async {
    await _api.post(ApiConstants.notificationsReadAll);
  }

  NotificationModel _toNotification(Map<String, dynamic> raw) {
    final payload = _decodePayload(raw['payloadJson']);
    final route = _routeName(payload);
    final routeArgs = _routeArgs(payload);

    return NotificationModel(
      id: (raw['id'] ?? '').toString(),
      title: (raw['title'] ?? 'Notification').toString(),
      body: (raw['body'] ?? '').toString(),
      type: (raw['type'] ?? 'system').toString(),
      isRead: raw['readAt'] != null,
      createdAt:
          DateTime.tryParse((raw['createdAt'] ?? '').toString()) ??
          DateTime.now(),
      routeName: route,
      routeArgs: routeArgs,
    );
  }

  Map<String, dynamic>? _decodePayload(dynamic value) {
    if (value == null) return null;
    if (value is Map<String, dynamic>) return value;
    if (value is String && value.isNotEmpty) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
        return null;
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  String? _routeName(Map<String, dynamic>? payload) {
    final announcementId = (payload?['announcementId'] ?? '').toString();
    if (announcementId.isNotEmpty) {
      return RouteNames.studentAnnouncementDetail;
    }
    return null;
  }

  Map<String, String>? _routeArgs(Map<String, dynamic>? payload) {
    final announcementId = (payload?['announcementId'] ?? '').toString();
    if (announcementId.isNotEmpty) {
      return {'announcementId': announcementId};
    }
    return null;
  }
}
