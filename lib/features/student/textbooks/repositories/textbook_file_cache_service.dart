import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/services/storage_service.dart';
import '../models/textbook_model.dart';

class TextbookOpenResult {
  final String localPath;
  final bool fromCache;

  const TextbookOpenResult({required this.localPath, required this.fromCache});
}

/// Callback for download progress updates
typedef ProgressCallback = void Function(int downloadedBytes, int totalBytes);

/// Callback for download cancellation
typedef CancelCallback = bool Function();

class TextbookFileCacheService {
  final StorageService _storage;

  static final Map<String, Future<TextbookOpenResult>> _inFlight =
      <String, Future<TextbookOpenResult>>{};

  static const String _indexKey = 'student_textbook_cache_index_v1';
  static const int _maxCacheBytes = 450 * 1024 * 1024;

  TextbookFileCacheService({
    StorageService? storageService,
  }) : _storage = storageService ?? StorageService();

  /// Opens a PDF locally, downloading if necessary
  /// Optional [onProgress] callback receives (downloadedBytes, totalBytes)
  /// Optional [shouldCancel] callback should return true to cancel download
  Future<TextbookOpenResult> prepareLocalPdf(
    TextbookModel textbook, {
    ProgressCallback? onProgress,
    CancelCallback? shouldCancel,
  }) {
    final key = textbook.cacheKey;
    final inFlight = _inFlight[key];
    if (inFlight != null) return inFlight;
    final future = _prepare(textbook, onProgress: onProgress, shouldCancel: shouldCancel);
    _inFlight[key] = future;
    future.whenComplete(() => _inFlight.remove(key));
    return future;
  }

  Future<TextbookOpenResult> _prepare(
    TextbookModel textbook, {
    ProgressCallback? onProgress,
    CancelCallback? shouldCancel,
  }) async {
    late final Directory dir;
    late final String safeId;
    late final File file;
    late final Map<String, dynamic> index;
    
    try {
      final root = await getApplicationDocumentsDirectory();
      dir = Directory('${root.path}/textbook_cache');
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      safeId = textbook.fileRecordId.isEmpty
          ? textbook.id
          : textbook.fileRecordId;
      file = File('${dir.path}/$safeId.pdf');

      index = _readIndex();
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
    } catch (e) {
      print('Error accessing storage: $e');
      throw Exception('Failed to access device storage. Please restart the app.');
    }

    // The textbook model already carries the Cloudinary CDN URL — no extra
    // round-trip to /files/{id}/access needed. Cloudinary raw URLs are
    // permanent and don't require signing, so we can use them directly.
    final accessUrl = textbook.accessUrl;
    if (accessUrl.isEmpty) {
      throw StateError('Missing file access URL for textbook');
    }

    // Download with progress tracking and cancellation support
    await _downloadWithProgress(
      accessUrl,
      file.path,
      onProgress: onProgress,
      shouldCancel: shouldCancel,
    );
    
    final size = await file.length();
    index[safeId] = <String, dynamic>{
      'cacheKey': textbook.cacheKey,
      'sizeBytes': size,
      'lastAccessedAt': DateTime.now().toIso8601String(),
      'path': file.path,
    };
    await _evictIfNeeded(index);
    await _writeIndex(index);
    return TextbookOpenResult(localPath: file.path, fromCache: false);
  }

  /// Download file with progress tracking and cancellation support
  Future<void> _downloadWithProgress(
    String url,
    String filePath, {
    ProgressCallback? onProgress,
    CancelCallback? shouldCancel,
  }) async {
    final dio = Dio();
    final response = await dio.getUri<List<int>>(
      Uri.parse(url),
      options: Options(responseType: ResponseType.bytes),
      onReceiveProgress: (received, total) {
        if (onProgress != null) {
          onProgress(received, total);
        }
        // Check if download should be cancelled
        if (shouldCancel?.call() ?? false) {
          throw DioException(
            requestOptions: RequestOptions(path: url),
            error: 'Download cancelled by user',
            type: DioExceptionType.cancel,
          );
        }
      },
    );

    if (response.data == null) {
      throw DioException(
        requestOptions: RequestOptions(path: url),
        error: 'Empty response',
        type: DioExceptionType.badResponse,
      );
    }

    // Write the downloaded bytes to file
    final file = File(filePath);
    await file.writeAsBytes(response.data!, flush: true);
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
