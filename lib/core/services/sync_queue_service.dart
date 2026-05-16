import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import '../network/api_client.dart';
import 'local_cache_service.dart';

class QueuedMutation {
  final String id;
  final String path;
  final String method;
  final dynamic data;
  final DateTime queuedAt;
  int retryCount;

  QueuedMutation({
    required this.id,
    required this.path,
    required this.method,
    this.data,
    required this.queuedAt,
    this.retryCount = 0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'path': path,
        'method': method,
        'data': data,
        'queuedAt': queuedAt.toIso8601String(),
        'retryCount': retryCount,
      };

  factory QueuedMutation.fromJson(Map<String, dynamic> json) => QueuedMutation(
        id: (json['id'] ?? '').toString(),
        path: (json['path'] ?? '').toString(),
        method: (json['method'] ?? '').toString(),
        data: json['data'],
        queuedAt: DateTime.tryParse((json['queuedAt'] ?? '').toString()) ??
            DateTime.now(),
        retryCount: (json['retryCount'] as num?)?.toInt() ?? 0,
      );
}

/// Handles optimistic UI by queueing failed mutations and retrying them later.
class SyncQueueService {
  static const String _queueKey = 'offline_sync_queue_v1';
  final LocalCacheService _cacheService;
  
  bool _isFlushing = false;

  SyncQueueService({
    required LocalCacheService cacheService,
  }) : _cacheService = cacheService;

  Dio get _dio => GetIt.instance<ApiClient>().dio;

  /// Enqueues a mutation to be retried later.
  Future<void> enqueue({
    required String path,
    required String method,
    dynamic data,
  }) async {
    final queue = _readQueue();
    final mutation = QueuedMutation(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      path: path,
      method: method,
      data: data,
      queuedAt: DateTime.now(),
    );
    
    queue.add(mutation);
    await _writeQueue(queue);
    
    if (kDebugMode) {
      print('SYNC QUEUE: Enqueued mutation to $path ($method). Queue size: ${queue.length}');
    }
  }

  /// Attempts to process all queued mutations.
  Future<void> flush() async {
    if (_isFlushing) return;
    
    final queue = _readQueue();
    if (queue.isEmpty) return;

    _isFlushing = true;
    
    if (kDebugMode) {
      print('SYNC QUEUE: Flushing ${queue.length} items...');
    }

    final successfulIds = <String>[];
    
    for (var i = 0; i < queue.length; i++) {
      final item = queue[i];
      try {
        await _dio.request(
          item.path,
          data: item.data,
          options: Options(method: item.method),
        );
        successfulIds.add(item.id);
        if (kDebugMode) {
          print('SYNC QUEUE: Successfully synced ${item.path}');
        }
      } catch (e) {
        item.retryCount++;
        if (kDebugMode) {
          print('SYNC QUEUE: Failed to sync ${item.path} (Retry ${item.retryCount})');
        }
      }
    }

    // Keep items that failed, unless they've been retried too many times
    final remainingQueue = queue.where((item) {
      if (successfulIds.contains(item.id)) return false;
      return item.retryCount < 5; // Drop after 5 failed syncs to prevent infinite blockage
    }).toList();

    await _writeQueue(remainingQueue);
    _isFlushing = false;
  }

  List<QueuedMutation> _readQueue() {
    final entry = _cacheService.read(_queueKey);
    if (entry == null || entry.data is! List) return [];
    
    try {
      return (entry.data as List)
          .whereType<Map<String, dynamic>>()
          .map(QueuedMutation.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _writeQueue(List<QueuedMutation> queue) async {
    await _cacheService.write(
      _queueKey,
      queue.map((m) => m.toJson()).toList(),
    );
  }
}
