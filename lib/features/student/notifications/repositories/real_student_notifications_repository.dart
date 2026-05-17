import 'dart:convert';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/routes/route_names.dart';
import '../../../../core/services/local_cache_service.dart';
import '../../../../core/services/storage_service.dart';
import '../models/notification_model.dart';
import 'student_notifications_repository.dart';

class RealStudentNotificationsRepository
    implements StudentNotificationsRepository {
  final ApiClient _api;
  final StorageService _storage;
  final LocalCacheService _cacheService;

  List<NotificationModel>? _cache;
  DateTime? _fetchedAt;
  Future<List<NotificationModel>>? _inFlight;
  static const Duration _ttl = Duration(minutes: 2);

  RealStudentNotificationsRepository({
    ApiClient? apiClient,
    required StorageService storageService,
    required LocalCacheService cacheService,
  }) : _api = apiClient ?? ApiClient(),
       _storage = storageService,
       _cacheService = cacheService;

  @override
  Future<List<NotificationModel>> fetchNotifications() async {
    final userId = await _currentUserId();
    _restoreCache(userId);
    if (_cache != null && _fetchedAt != null) {
      final age = DateTime.now().difference(_fetchedAt!);
      if (age < _ttl) return _cache!;
    }

    if (_inFlight != null) return _inFlight!;

    final future = _fetchFresh();
    _inFlight = future;
    try {
      final data = await future;
      _cache = data;
      _fetchedAt = DateTime.now();
      await _persistCache(userId);
      return data;
    } catch (_) {
      if (_cache != null) return _cache!;
      rethrow;
    } finally {
      _inFlight = null;
    }
  }

  Future<List<NotificationModel>> _fetchFresh() async {
    final list = await _api.getList(ApiConstants.notifications);
    final results = <NotificationModel>[];
    
    for (final raw in list.whereType<Map>()) {
      try {
        final map = Map<String, dynamic>.from(raw);
        results.add(_toNotification(map));
      } catch (e) {
        print('Skipping malformed notification: $e');
      }
    }
    return results;
  }

  @override
  Future<void> markAsRead(String id) async {
    await _api.patch(ApiConstants.notificationRead(id));
    _cache = _cache
        ?.map((item) => item.id == id ? item.copyWith(isRead: true) : item)
        .toList();
    _fetchedAt = DateTime.now();
    await _persistCache(await _currentUserId());
  }

  @override
  Future<void> markAsUnread(String id) async {
    await _api.patch(ApiConstants.notificationUnread(id));
    _cache = _cache
        ?.map((item) => item.id == id ? item.copyWith(isRead: false) : item)
        .toList();
    _fetchedAt = DateTime.now();
    await _persistCache(await _currentUserId());
  }

  @override
  Future<void> markAllAsRead() async {
    await _api.post(ApiConstants.notificationsReadAll);
    _cache = _cache?.map((item) => item.copyWith(isRead: true)).toList();
    _fetchedAt = DateTime.now();
    await _persistCache(await _currentUserId());
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

  Future<String> _currentUserId() async {
    final user = await _storage.getUser();
    return (user?['id'] ?? '').toString();
  }

  String _cacheKey(String userId) => userId.isEmpty
      ? 'student_notifications_v1'
      : 'student_notifications_v1_$userId';

  @override
  void clearCache() {
    _cache = null;
    _fetchedAt = null;
    _inFlight = null;
  }

  void _restoreCache(String userId) {
    if (_cache != null) return;
    final entry = _cacheService.read(_cacheKey(userId));
    if (entry == null || entry.data is! List) return;
    _cache = (entry.data as List)
        .whereType<Map<String, dynamic>>()
        .map(NotificationModel.fromJson)
        .toList();
    _fetchedAt = entry.savedAt;
  }

  Future<void> _persistCache(String userId) async {
    if (_cache == null) return;
    await _cacheService.write(
      _cacheKey(userId),
      _cache!.map((item) => item.toJson()).toList(),
    );
  }
}
