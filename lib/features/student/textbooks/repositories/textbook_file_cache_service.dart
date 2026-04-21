import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/storage_service.dart';
import '../models/textbook_model.dart';

class TextbookOpenResult {
  final String localPath;
  final bool fromCache;

  const TextbookOpenResult({required this.localPath, required this.fromCache});
}

class TextbookFileCacheService {
  final ApiClient _api;
  final StorageService _storage;

  static final Map<String, Future<TextbookOpenResult>> _inFlight =
      <String, Future<TextbookOpenResult>>{};

  static const String _indexKey = 'student_textbook_cache_index_v1';
  static const int _maxCacheBytes = 450 * 1024 * 1024;

  TextbookFileCacheService({
    ApiClient? apiClient,
    StorageService? storageService,
  }) : _api = apiClient ?? ApiClient(),
       _storage = storageService ?? StorageService();

  Future<TextbookOpenResult> prepareLocalPdf(TextbookModel textbook) {
    final key = textbook.cacheKey;
    final inFlight = _inFlight[key];
    if (inFlight != null) return inFlight;
    final future = _prepare(textbook);
    _inFlight[key] = future;
    future.whenComplete(() => _inFlight.remove(key));
    return future;
  }

  Future<TextbookOpenResult> _prepare(TextbookModel textbook) async {
    final root = await getApplicationDocumentsDirectory();
    final dir = Directory('${root.path}/textbook_cache');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    final safeId = textbook.fileRecordId.isEmpty
        ? textbook.id
        : textbook.fileRecordId;
    final file = File('${dir.path}/$safeId.pdf');

    final index = _readIndex();
    final entry = index[safeId];
    if (entry is Map<String, dynamic> && await file.exists()) {
      final cachedKey = (entry['cacheKey'] ?? '').toString();
      if (cachedKey == textbook.cacheKey) {
        entry['lastAccessedAt'] = DateTime.now().toIso8601String();
        index[safeId] = entry;
        await _writeIndex(index);
        return TextbookOpenResult(localPath: file.path, fromCache: true);
      }
    }

    final accessMeta = await _api.get(ApiConstants.fileAccess(safeId));
    final accessUrl = (accessMeta['accessUrl'] ?? '').toString();
    if (accessUrl.isEmpty) {
      throw StateError('Missing file access URL for textbook');
    }

    await Dio().download(accessUrl, file.path);
    final size = await file.length();
    index[safeId] = <String, dynamic>{
      'cacheKey': (accessMeta['cacheKey'] ?? textbook.cacheKey).toString(),
      'sizeBytes': size,
      'lastAccessedAt': DateTime.now().toIso8601String(),
      'path': file.path,
    };
    await _evictIfNeeded(index);
    await _writeIndex(index);
    return TextbookOpenResult(localPath: file.path, fromCache: false);
  }

  Future<void> _evictIfNeeded(Map<String, dynamic> index) async {
    int totalBytes = 0;
    final records = <MapEntry<String, Map<String, dynamic>>>[];
    for (final entry in index.entries) {
      final value = entry.value;
      if (value is! Map<String, dynamic>) continue;
      totalBytes += (value['sizeBytes'] as int?) ?? 0;
      records.add(MapEntry(entry.key, value));
    }
    if (totalBytes <= _maxCacheBytes) return;

    records.sort((a, b) {
      final aTime =
          DateTime.tryParse((a.value['lastAccessedAt'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final bTime =
          DateTime.tryParse((b.value['lastAccessedAt'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0);
      return aTime.compareTo(bTime);
    });

    for (final entry in records) {
      if (totalBytes <= _maxCacheBytes) break;
      final path = (entry.value['path'] ?? '').toString();
      if (path.isNotEmpty) {
        final f = File(path);
        if (await f.exists()) {
          try {
            await f.delete();
          } catch (_) {
            // ignore file delete failures
          }
        }
      }
      totalBytes -= (entry.value['sizeBytes'] as int?) ?? 0;
      index.remove(entry.key);
    }
  }

  Map<String, dynamic> _readIndex() {
    final raw = _storage.getString(_indexKey);
    if (raw == null || raw.isEmpty) return <String, dynamic>{};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
      return <String, dynamic>{};
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  Future<void> _writeIndex(Map<String, dynamic> index) {
    return _storage.setString(_indexKey, jsonEncode(index));
  }
}
