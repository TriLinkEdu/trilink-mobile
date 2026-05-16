import 'package:flutter/foundation.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/local_cache_service.dart';
import '../../../../core/services/storage_service.dart';
import '../models/announcement_model.dart';
import 'student_announcements_repository.dart';

class RealStudentAnnouncementsRepository
    implements StudentAnnouncementsRepository {
  final ApiClient _api;
  final StorageService _storage;
  final LocalCacheService _cacheService;

  List<AnnouncementModel>? _cache;
  DateTime? _fetchedAt;
  Future<List<AnnouncementModel>>? _inFlight;
  static const Duration _ttl = Duration(minutes: 15);

  RealStudentAnnouncementsRepository({
    ApiClient? apiClient,
    required StorageService storageService,
    required LocalCacheService cacheService,
  }) : _api = apiClient ?? ApiClient(),
       _storage = storageService,
       _cacheService = cacheService;

  @override
  Future<List<AnnouncementModel>> fetchAnnouncements() async {
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
      await _cacheService.write(
        _cacheKey(userId),
        data.map((item) => item.toJson()).toList(),
      );
      return data;
    } catch (e) {
      debugPrint('[AnnouncementsRepo] fetchAnnouncements error: $e');
      if (_cache != null) return _cache!;
      rethrow;
    } finally {
      _inFlight = null;
    }
  }

  Future<List<AnnouncementModel>> _fetchFresh() async {
    debugPrint('[AnnouncementsRepo] fetching ${ApiConstants.announcementsForMe}');
    final list = await _api.getList(ApiConstants.announcementsForMe);
    debugPrint('[AnnouncementsRepo] received ${list.length} items');

    return list
        .whereType<Map<String, dynamic>>()
        .map(
          (raw) => AnnouncementModel(
            id: (raw['id'] ?? '').toString(),
            title: (raw['title'] ?? 'Announcement').toString(),
            body: (raw['body'] ?? '').toString(),
            authorName: 'TriLink',
            authorRole: 'Admin',
            createdAt:
                DateTime.tryParse((raw['createdAt'] ?? '').toString()) ??
                DateTime.now(),
            category: (raw['audience'] ?? '').toString(),
          ),
        )
        .toList();
  }

  Future<String> _currentUserId() async {
    final user = await _storage.getUser();
    return (user?['id'] ?? '').toString();
  }

  String _cacheKey(String userId) => userId.isEmpty
      ? 'student_announcements_v2'
      : 'student_announcements_v2_$userId';

  @override
  List<AnnouncementModel>? getCached() => _cache;

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
        .map(AnnouncementModel.fromJson)
        .toList();
    _fetchedAt = entry.savedAt;
  }
}
