import 'package:flutter/foundation.dart';

/// Tracks performance, cache hit ratios, and API latency.
class TelemetryService {
  int _cacheHits = 0;
  int _networkHits = 0;
  final Map<String, List<int>> _apiLatencies = {};
  
  static final DateTime _appStartTime = DateTime.now();
  bool _coldStartLogged = false;

  /// Call this when the first meaningful UI renders
  void logColdStartComplete() {
    if (_coldStartLogged) return;
    _coldStartLogged = true;
    final duration = DateTime.now().difference(_appStartTime);
    _printMetric('COLD START', '${duration.inMilliseconds}ms');
  }

  void recordCacheHit(String key) {
    _cacheHits++;
    _printMetric('CACHE HIT', key);
    _logRatio();
  }

  void recordNetworkHit(String path, int durationMs) {
    _networkHits++;
    
    final endpoint = _normalizePath(path);
    _apiLatencies.putIfAbsent(endpoint, () => []).add(durationMs);
    
    // Keep last 50 latencies per endpoint
    if (_apiLatencies[endpoint]!.length > 50) {
      _apiLatencies[endpoint]!.removeAt(0);
    }
    
    _printMetric('NETWORK', '[$durationMs ms] $endpoint');
    _logRatio();
  }

  void _logRatio() {
    final total = _cacheHits + _networkHits;
    if (total % 10 == 0 && total > 0) { // Log ratio every 10 hits
      final ratio = (_cacheHits / total * 100).toStringAsFixed(1);
      _printMetric('CACHE RATIO', '$ratio% ($_cacheHits/$_networkHits)');
    }
  }

  void logAverageLatencies() {
    _printMetric('LATENCY REPORT', '---');
    _apiLatencies.forEach((endpoint, latencies) {
      if (latencies.isEmpty) return;
      final avg = latencies.reduce((a, b) => a + b) ~/ latencies.length;
      _printMetric('AVG LATENCY', '[$avg ms] $endpoint');
    });
  }

  String _normalizePath(String path) {
    // Basic normalization to strip UUIDs so stats group correctly
    return path.replaceAll(RegExp(r'[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}'), ':id');
  }

  void _printMetric(String tag, String message) {
    if (kDebugMode) {
      print('📊 [$tag] $message');
    }
  }
}
