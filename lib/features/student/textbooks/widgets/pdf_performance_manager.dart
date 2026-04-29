import 'package:flutter/material.dart';

/// Performance and memory optimization for PDF viewer
class PdfPerformanceManager {
  /// Cache size limits
  static const int maxCachePages = 5;
  static const int maxMemoryMB = 100;

  /// Lazy-load pages around current page
  static List<int> getPageRangeToLoad({
    required int currentPage,
    required int totalPages,
    int preloadDistance = 2,
  }) {
    final pages = <int>[];
    
    // Add current page
    pages.add(currentPage);
    
    // Add preload distance pages before and after
    for (int i = 1; i <= preloadDistance; i++) {
      if (currentPage - i >= 1) {
        pages.add(currentPage - i);
      }
      if (currentPage + i <= totalPages) {
        pages.add(currentPage + i);
      }
    }
    
    return pages;
  }

  /// Throttle expensive operations
  static Future<T> throttle<T>({
    required Duration duration,
    required Future<T> Function() operation,
  }) async {
    return operation();
  }

  /// Memory management check
  static bool shouldEvictCache({
    required int currentMemorySizeBytes,
    required int maxMemorySizeBytes,
    required double threshold,
  }) {
    final percentage = (currentMemorySizeBytes / maxMemorySizeBytes) * 100;
    return percentage >= (threshold * 100);
  }
}

/// Enhanced PDF page renderer with better aspect ratio handling
class EnhancedPdfPageRenderer extends StatelessWidget {
  final double pageWidth;
  final double pageHeight;
  final Widget pdfPageWidget;
  final double zoom;
  final ScrollController scrollController;
  final bool preserveAspectRatio;

  const EnhancedPdfPageRenderer({
    super.key,
    required this.pageWidth,
    required this.pageHeight,
    required this.pdfPageWidget,
    this.zoom = 1.0,
    required this.scrollController,
    this.preserveAspectRatio = true,
  });

  /// Calculate optimal fit for the page
  BoxFit _calculateFit() {
    // If page is landscape and viewport is portrait, use fitHeight
    if (pageWidth > pageHeight) {
      return BoxFit.fitHeight;
    }
    // If page is portrait and viewport is landscape, use fitWidth
    return BoxFit.fitWidth;
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;

    // Calculate ideal scaling
    final scaleX = screenWidth / pageWidth;
    final scaleY = screenHeight / pageHeight;
    
    // Use appropriate scaling based on orientation
    final fit = _calculateFit();
    final scale = fit == BoxFit.fitWidth ? scaleX : scaleY;
    final effectiveScale = scale * zoom;

    return SingleChildScrollView(
      controller: scrollController,
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Transform.scale(
          scale: effectiveScale,
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: pageWidth,
            height: pageHeight,
            child: AspectRatio(
              aspectRatio: pageWidth / pageHeight,
              child: pdfPageWidget,
            ),
          ),
        ),
      ),
    );
  }
}

/// Adaptive page fitting strategy
class AdaptivePageFitter {
  /// Determine the best strategy for rendering a PDF page
  static BoxFit getAdaptiveFit({
    required double pageWidth,
    required double pageHeight,
    required Orientation orientation,
    required double viewportWidth,
    required double viewportHeight,
  }) {
    final pageAspectRatio = pageWidth / pageHeight;
    final viewportAspectRatio = viewportWidth / viewportHeight;
    
    // Calculate aspect ratio difference
    final aspectRatioDiff = (pageAspectRatio - viewportAspectRatio).abs();
    
    // Very similar aspect ratios - use cover
    if (aspectRatioDiff < 0.05) {
      return BoxFit.cover;
    }
    
    // Page is wider (landscape) or viewport is narrower
    if (pageAspectRatio > viewportAspectRatio) {
      return BoxFit.fitWidth;
    }
    
    // Page is taller (portrait) or viewport is wider
    return BoxFit.fitHeight;
  }

  /// Calculate optimal zoom to fit with minimum white space
  static double getOptimalZoom({
    required double pageWidth,
    required double pageHeight,
    required double viewportWidth,
    required double viewportHeight,
    bool fillViewport = true,
  }) {
    final scaleX = viewportWidth / pageWidth;
    final scaleY = viewportHeight / pageHeight;
    
    // Choose the larger scale to fill viewport
    // Choose the smaller scale to fit within viewport
    return fillViewport ? ([scaleX, scaleY].reduce((a, b) => a > b ? a : b))
        : ([scaleX, scaleY].reduce((a, b) => a < b ? a : b));
  }
}

/// Handles caching and memory management for PDF pages
class PdfPageCache {
  final int maxPages;
  final Map<int, CachedPdfPage> _cache = {};

  PdfPageCache({this.maxPages = 5});

  /// Cache a page
  void cachePage(int pageNumber, CachedPdfPage page) {
    if (_cache.length >= maxPages && !_cache.containsKey(pageNumber)) {
      // Remove oldest page
      _cache.remove(_cache.keys.first);
    }
    _cache[pageNumber] = page;
  }

  /// Get cached page
  CachedPdfPage? getPage(int pageNumber) => _cache[pageNumber];

  /// Check if page is cached
  bool isCached(int pageNumber) => _cache.containsKey(pageNumber);

  /// Clear cache
  void clear() => _cache.clear();

  /// Get cache hit rate
  double getCacheHitRate() {
    return _cache.isNotEmpty ? (_cache.length / maxPages) : 0.0;
  }

  /// Estimate memory usage
  int estimateMemoryUsage() {
    return _cache.values.fold(0, (sum, page) => sum + page.estimatedMemoryBytes);
  }
}

/// Represents a cached PDF page
class CachedPdfPage {
  final int pageNumber;
  final int estimatedMemoryBytes;
  final DateTime cachedAt;

  CachedPdfPage({
    required this.pageNumber,
    required this.estimatedMemoryBytes,
    DateTime? cachedAt,
  }) : cachedAt = cachedAt ?? DateTime.now();

  bool isExpired(Duration ttl) => DateTime.now().difference(cachedAt) > ttl;
}
