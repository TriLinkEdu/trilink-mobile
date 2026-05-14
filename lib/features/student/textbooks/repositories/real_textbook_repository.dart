import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/local_cache_service.dart';
import '../../../../core/services/storage_service.dart';
import '../models/textbook_model.dart';
import 'textbook_repository.dart';

/// Offline-first textbook repository.
///
/// Behaviour:
///   1. On cold start, immediately restore the last-good list from disk.
///   2. Return the in-memory list immediately if it is within TTL.
///   3. Fetch fresh data in the background; update in-memory + disk on success.
///   4. On network failure, serve whatever is in the cache rather than throwing.
class RealTextbookRepository implements TextbookRepository {
  final ApiClient _api;
  final LocalCacheService _cacheService;

  static const Duration _ttl = Duration(hours: 1);

  // Separate caches keyed by "grade_subject" to handle filtered queries.
  final Map<String, List<TextbookModel>> _cache = {};
  final Map<String, DateTime> _fetchedAt = {};
  final Map<String, Future<List<TextbookModel>>> _inFlight = {};

  RealTextbookRepository({
    ApiClient? apiClient,
    required LocalCacheService cacheService,
  })  : _api = apiClient ?? ApiClient(),
        _cacheService = cacheService;

  // ── Cache key ─────────────────────────────────────────────

  static String _key({String? subject, int? grade}) {
    final s = subject?.isNotEmpty == true ? subject! : '_';
    final g = grade != null ? '$grade' : '_';
    return 'textbooks_v1_${g}_$s';
  }

  // ── Public API ────────────────────────────────────────────

  @override
  Future<List<TextbookModel>> fetchTextbooks({
    String? subject,
    int? grade,
  }) async {
    final cacheKey = _key(subject: subject, grade: grade);

    // 1. Restore from disk if in-memory is cold.
    if (!_cache.containsKey(cacheKey)) {
      _restoreFromDisk(cacheKey);
    }

    // 2. Return from memory if fresh.
    final memData = _cache[cacheKey];
    final memAt = _fetchedAt[cacheKey];
    if (memData != null && memAt != null) {
      final age = DateTime.now().difference(memAt);
      if (age < _ttl) return memData;
    }

    // 3. Deduplicate concurrent requests.
    final inFlight = _inFlight[cacheKey];
    if (inFlight != null) return inFlight;

    final future = _fetchFresh(subject: subject, grade: grade);
    _inFlight[cacheKey] = future;

    try {
      final data = await future;
      _cache[cacheKey] = data;
      _fetchedAt[cacheKey] = DateTime.now();
      await _cacheService.write(
        cacheKey,
        data.map((t) => t.toJson()).toList(),
      );
      return data;
    } catch (_) {
      // On failure, serve stale cache if available rather than crashing.
      if (_cache[cacheKey] != null) return _cache[cacheKey]!;
      rethrow;
    } finally {
      _inFlight.remove(cacheKey);
    }
  }

  @override
  Future<TextbookModel?> fetchTextbookById(String id) async {
    // Check all cached lists first to avoid a network round-trip.
    for (final list in _cache.values) {
      for (final t in list) {
        if (t.id == id) return t;
      }
    }
    try {
      final response = await _api.get(ApiConstants.textbook(id));
      return TextbookModel.fromJson(response);
    } catch (_) {
      return null; // Non-fatal: caller handles null gracefully.
    }
  }

  // ── Internal helpers ──────────────────────────────────────

  void _restoreFromDisk(String cacheKey) {
    final entry = _cacheService.read(cacheKey);
    if (entry == null || entry.data is! List) return;
    try {
      _cache[cacheKey] = (entry.data as List)
          .whereType<Map<String, dynamic>>()
          .map(TextbookModel.fromJson)
          .toList();
      _fetchedAt[cacheKey] = entry.savedAt;
    } catch (_) {
      // Ignore malformed cache entries.
    }
  }

  @override
  List<TextbookModel>? getCached() {
    // Return the most recent cache entry (unfiltered list)
    return _cache.values.isNotEmpty ? _cache.values.first : null;
  }

  @override
  void clearCache() {
    _cache.clear();
    _fetchedAt.clear();
    _inFlight.clear();
  }

  Future<List<TextbookModel>> _fetchFresh({
    String? subject,
    int? grade,
  }) async {
    final queryParameters = <String, dynamic>{
      if (subject != null && subject.isNotEmpty) 'subject': subject,
      if (grade != null) 'grade': grade,
    };
    final rows = await _api.getList(
      ApiConstants.textbooks,
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
    );
    return rows
        .whereType<Map<String, dynamic>>()
        .map(TextbookModel.fromJson)
        .toList();
  }
}
