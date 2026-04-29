import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';
import '../models/textbook_reading_models.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/storage_service.dart';

/// LRU cache for PDF pages with memory management
class TextbookPageCache {
  final int _maxCacheSize;
  final Map<String, _CacheEntry> _cache = {};
  final List<String> _accessOrder = [];

  TextbookPageCache({int maxCacheSize = 20}) : _maxCacheSize = maxCacheSize;

  /// Get cached page or null if not cached
  ui.Image? getPage(String textbookId, int pageNumber) {
    final key = _cacheKey(textbookId, pageNumber);
    final entry = _cache[key];
    if (entry == null) return null;

    // Update access order (move to end)
    _accessOrder.remove(key);
    _accessOrder.add(key);
    entry.lastAccessed = DateTime.now();
    
    return entry.image;
  }

  /// Cache a rendered page
  void cachePage(String textbookId, int pageNumber, ui.Image image) {
    final key = _cacheKey(textbookId, pageNumber);
    
    // Remove if already exists
    if (_cache.containsKey(key)) {
      _accessOrder.remove(key);
    }
    
    // Add to cache
    _cache[key] = _CacheEntry(image: image, lastAccessed: DateTime.now());
    _accessOrder.add(key);
    
    // Evict if over limit
    _evictIfNeeded();
  }

  /// Pre-cache adjacent pages
  Future<void> preCacheAdjacent(
    String textbookId, 
    int currentPage, 
    PdfDocument document,
    {int radius = 2}
  ) async {
    final totalPages = document.pagesCount;
    final startPage = (currentPage - radius).clamp(1, totalPages);
    final endPage = (currentPage + radius).clamp(1, totalPages);

    for (int page = startPage; page <= endPage; page++) {
      if (page == currentPage) continue; // Skip current page
      
      final key = _cacheKey(textbookId, page);
      if (_cache.containsKey(key)) continue; // Skip if already cached
      
      try {
        final pdfPage = await document.getPage(page);
        final pageImage = await pdfPage.render(
          width: 800, // Standard width for caching
          height: (800 * pdfPage.height / pdfPage.width).round().toDouble(),
        );
        // Skip caching for now - just close the page
        // TODO: Implement proper image caching when pdfx supports it
        pdfPage.close();
        
        pdfPage.close();
      } catch (e) {
        // Ignore pre-cache errors
      }
    }
  }

  /// Clear cache for specific textbook
  void clearTextbook(String textbookId) {
    final keysToRemove = _cache.keys
        .where((key) => key.startsWith('$textbookId:'))
        .toList();
    
    for (final key in keysToRemove) {
      _cache.remove(key);
      _accessOrder.remove(key);
    }
  }

  /// Clear all cache
  void clearAll() {
    _cache.clear();
    _accessOrder.clear();
  }

  /// Get cache statistics
  CacheStats get stats {
    final totalMemory = _cache.values
        .map((entry) => _estimateImageMemory(entry.image))
        .fold<int>(0, (sum, size) => sum + size);
    
    return CacheStats(
      cachedPages: _cache.length,
      totalMemoryBytes: totalMemory,
      maxCacheSize: _maxCacheSize,
    );
  }

  String _cacheKey(String textbookId, int pageNumber) => '$textbookId:$pageNumber';

  void _evictIfNeeded() {
    while (_cache.length > _maxCacheSize && _accessOrder.isNotEmpty) {
      final oldestKey = _accessOrder.removeAt(0);
      _cache.remove(oldestKey);
    }
  }

  int _estimateImageMemory(ui.Image image) {
    return image.width * image.height * 4; // 4 bytes per pixel (RGBA)
  }
}

class _CacheEntry {
  final ui.Image image;
  DateTime lastAccessed;

  _CacheEntry({required this.image, required this.lastAccessed});
}

class CacheStats {
  final int cachedPages;
  final int totalMemoryBytes;
  final int maxCacheSize;

  const CacheStats({
    required this.cachedPages,
    required this.totalMemoryBytes,
    required this.maxCacheSize,
  });

  String get memoryDisplay {
    if (totalMemoryBytes < 1024 * 1024) {
      return '${(totalMemoryBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(totalMemoryBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

/// Service for managing textbook reading state and caching
class TextbookReadingService {
  static final TextbookPageCache _pageCache = TextbookPageCache();
  static const String _storageKey = 'textbook_reading_states';

  /// Get page cache instance
  static TextbookPageCache get pageCache => _pageCache;

  /// Save reading state to storage
  static Future<void> saveReadingState(
    String textbookId, 
    TextbookReadingState state,
  ) async {
    try {
      final storage = sl<StorageService>();
      final key = '${_storageKey}_$textbookId';
      await storage.setString(key, jsonEncode(state.toJson()));
    } catch (e) {
      // Ignore storage errors
    }
  }

  /// Load reading state from storage
  static Future<TextbookReadingState?> loadReadingState(String textbookId) async {
    try {
      final storage = sl<StorageService>();
      final key = '${_storageKey}_$textbookId';
      final jsonString = storage.getString(key);
      if (jsonString != null && jsonString.isNotEmpty) {
        final json = jsonDecode(jsonString) as Map<String, dynamic>;
        return TextbookReadingState.fromJson(json);
      }
    } catch (e) {
      // Ignore storage errors
    }
    return null;
  }

  /// Update reading progress
  static Future<void> updateProgress(
    String textbookId,
    int currentPage,
    int totalPages,
    {Duration? additionalReadingTime}
  ) async {
    final existing = await loadReadingState(textbookId);
    final now = DateTime.now();
    
    final newState = (existing ?? TextbookReadingState(
      textbookId: textbookId,
      lastReadAt: now,
    )).copyWith(
      currentPage: currentPage,
      totalPages: totalPages,
      lastReadAt: now,
      totalReadingTime: existing != null 
          ? existing.totalReadingTime + (additionalReadingTime ?? Duration.zero)
          : (additionalReadingTime ?? Duration.zero),
    );
    
    await saveReadingState(textbookId, newState);
  }
}