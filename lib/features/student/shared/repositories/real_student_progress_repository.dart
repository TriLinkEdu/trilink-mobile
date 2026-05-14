import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/local_cache_service.dart';
import '../../../../core/services/storage_service.dart';
import '../models/student_progress_model.dart';
import 'student_progress_repository.dart';

class RealStudentProgressRepository implements StudentProgressRepository {
  final ApiClient _api;
  final StorageService _storage;
  final LocalCacheService _cacheService;

  static StudentProgressModel? _cache;
  static DateTime? _fetchedAt;
  static Future<StudentProgressModel>? _inFlight;
  static const Duration _ttl = Duration(seconds: 30);

  RealStudentProgressRepository({
    ApiClient? apiClient,
    required StorageService storageService,
    required LocalCacheService cacheService,
  }) : _api = apiClient ?? ApiClient(),
       _storage = storageService,
       _cacheService = cacheService;

  @override
  Future<StudentProgressModel> fetchProgress() async {
    final userId = await _currentUserId();
    _restoreCache(userId);
    if (_cache != null && _fetchedAt != null) {
      final age = DateTime.now().difference(_fetchedAt!);
      if (age < _ttl) return _cache!;
    }

    final inFlight = _inFlight;
    if (inFlight != null) return inFlight;

    final future = _fetchFresh();
    _inFlight = future;
    try {
      final data = await future;
      _cache = data;
      _fetchedAt = DateTime.now();
      await _cacheService.write(_cacheKey(userId), data.toJson());
      return data;
    } catch (_) {
      if (_cache != null) return _cache!;
      rethrow;
    } finally {
      _inFlight = null;
    }
  }

  Future<StudentProgressModel> _fetchFresh() async {
    final progress = await _safeGet(ApiConstants.gamificationMyProgress);

    final currentStreak = _asInt(progress['currentStreak'], fallback: 0);
    final longestStreak = _asInt(
      progress['longestStreak'],
      fallback: currentStreak,
    );
    final totalXp = _asInt(progress['totalXp'], fallback: 0);
    final level = (totalXp ~/ 100).clamp(1, 999);
    final levelTitle = (progress['levelTitle'] ?? '').toString().trim();

    return StudentProgressModel(
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      totalXp: totalXp,
      level: level,
      levelTitle: levelTitle.isNotEmpty ? levelTitle : _levelTitle(level),
    );
  }

  Future<Map<String, dynamic>> _safeGet(String path) async {
    try {
      return await _api.get(path);
    } catch (_) {
      return const <String, dynamic>{};
    }
  }

  int _asInt(dynamic value, {required int fallback}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  String _levelTitle(int level) {
    if (level >= 20) return 'Legend';
    if (level >= 15) return 'Master';
    if (level >= 10) return 'Scholar';
    if (level >= 5) return 'Learner';
    return 'Starter';
  }

  Future<String> _currentUserId() async {
    final user = await _storage.getUser();
    return (user?['id'] ?? '').toString();
  }

  String _cacheKey(String userId) => userId.isEmpty
      ? 'student_progress_v1'
      : 'student_progress_v1_$userId';

  void _restoreCache(String userId) {
    if (_cache != null) return;
    final entry = _cacheService.read(_cacheKey(userId));
    if (entry == null || entry.data is! Map<String, dynamic>) return;
    _cache = StudentProgressModel.fromJson(
      Map<String, dynamic>.from(entry.data as Map),
    );
    _fetchedAt = entry.savedAt;
  }
}
