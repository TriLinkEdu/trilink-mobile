import 'dart:convert';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/local_cache_service.dart';
import '../../../../core/services/storage_service.dart';
import 'student_settings_repository.dart';

class RealStudentSettingsRepository implements StudentSettingsRepository {
  final ApiClient _api;
  final StorageService _storage;
  final LocalCacheService _cacheService;

  static Map<String, dynamic>? _cache;
  static DateTime? _fetchedAt;
  static Future<Map<String, dynamic>>? _inFlight;
  static const Duration _ttl = Duration(seconds: 20);

  RealStudentSettingsRepository({
    ApiClient? apiClient,
    required StorageService storageService,
    required LocalCacheService cacheService,
  }) : _api = apiClient ?? ApiClient(),
       _storage = storageService,
       _cacheService = cacheService;

  @override
  Future<Map<String, dynamic>> fetchSettings() async {
    final userId = await _currentUserId();
    _restoreCache(userId);
    if (_cache != null && _fetchedAt != null) {
      final age = DateTime.now().difference(_fetchedAt!);
      if (age < _ttl) return Map<String, dynamic>.from(_cache!);
    }

    final inFlight = _inFlight;
    if (inFlight != null) return inFlight;

    final future = _fetchFresh();
    _inFlight = future;
    try {
      final data = await future;
      _cache = data;
      _fetchedAt = DateTime.now();
      await _persistCache(userId);
      return Map<String, dynamic>.from(data);
    } catch (_) {
      if (_cache != null) return Map<String, dynamic>.from(_cache!);
      rethrow;
    } finally {
      _inFlight = null;
    }
  }

  @override
  Future<void> saveSettings(Map<String, dynamic> settings) async {
    final payload = jsonEncode(settings);
    await _api.patch(
      ApiConstants.userSettings,
      data: {'settingsJson': payload},
    );
    _cache = Map<String, dynamic>.from(settings);
    _fetchedAt = DateTime.now();
    await _persistCache(await _currentUserId());
  }

  Future<Map<String, dynamic>> _fetchFresh() async {
    final raw = await _api.get(ApiConstants.userSettings);
    final settingsJson = (raw['settingsJson'] ?? '{}').toString();
    try {
      final decoded = jsonDecode(settingsJson);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return const <String, dynamic>{};
    } catch (_) {
      return const <String, dynamic>{};
    }
  }

  Future<String> _currentUserId() async {
    final user = await _storage.getUser();
    return (user?['id'] ?? '').toString();
  }

  String _cacheKey(String userId) => userId.isEmpty
      ? 'student_settings_v1'
      : 'student_settings_v1_$userId';

  void _restoreCache(String userId) {
    if (_cache != null) return;
    final entry = _cacheService.read(_cacheKey(userId));
    if (entry == null || entry.data is! Map<String, dynamic>) return;
    _cache = Map<String, dynamic>.from(entry.data as Map);
    _fetchedAt = entry.savedAt;
  }

  Future<void> _persistCache(String userId) async {
    if (_cache == null) return;
    await _cacheService.write(_cacheKey(userId), _cache);
  }
}
