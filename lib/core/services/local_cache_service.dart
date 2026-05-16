import 'dart:convert';
import 'storage_service.dart';
import 'telemetry_service.dart';

class CacheEntry<T> {
  final DateTime savedAt;
  final T data;

  const CacheEntry({required this.savedAt, required this.data});
}

class LocalCacheService {
  LocalCacheService(this._storage, {this.telemetry});

  final StorageService _storage;
  final TelemetryService? telemetry;
  static const String _prefix = 'cache_';

  String _key(String key) => '$_prefix$key';

  Future<void> write(String key, dynamic data) async {
    final payload = jsonEncode({
      'savedAt': DateTime.now().toIso8601String(),
      'data': data,
    });
    await _storage.setString(_key(key), payload);
  }

  CacheEntry<dynamic>? read(String key, {Duration? maxAge}) {
    final raw = _storage.getString(_key(key));
    if (raw == null || raw.isEmpty) return null;
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) return null;
    final savedAtRaw = decoded['savedAt'];
    if (savedAtRaw is! String) return null;
    final savedAt = DateTime.tryParse(savedAtRaw);
    if (savedAt == null) return null;
    
    // Check expiration if maxAge is provided
    if (maxAge != null && DateTime.now().difference(savedAt) > maxAge) {
      remove(key); // clear stale entry
      return null;
    }
    
    // Record cache hit
    telemetry?.recordCacheHit(key);
    
    return CacheEntry<dynamic>(savedAt: savedAt, data: decoded['data']);
  }

  Future<void> remove(String key) async {
    await _storage.remove(_key(key));
  }
}
