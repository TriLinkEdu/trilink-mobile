import 'dart:async';
import 'dart:isolate';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:pdfx/pdfx.dart';

/// Manages PDF rendering performance with memory optimization
class PdfPerformanceManager {
  static const int _maxCachedPages = 5;
  static const int _prefetchDistance = 2;
  static const double _highResScale = 2.0;
  static const double _lowResScale = 1.0;
  
  final Map<int, ui.Image?> _highResCache = {};
  final Map<int, ui.Image?> _lowResCache = {};
  final Set<int> _renderingPages = {};
  
  PdfDocument? _document;
  int _currentPage = 1;
  
  /// Initialize with PDF document
  Future<void> initialize(String path) async {
    _document = await PdfDocument.openFile(path);
  }
  
  /// Update current page and trigger pre-fetching
  void updateCurrentPage(int page) {
    _currentPage = page;
    _prefetchAdjacentPages();
    _evictDistantPages();
  }
  
  /// Get page image with fallback to low-res if high-res fails
  Future<ui.Image?> getPageImage(int pageNumber) async {
    // Return cached high-res if available
    if (_highResCache.containsKey(pageNumber)) {
      return _highResCache[pageNumber];
    }
    
    // Return cached low-res while loading high-res
    if (_lowResCache.containsKey(pageNumber)) {
      _renderHighRes(pageNumber); // Async upgrade
      return _lowResCache[pageNumber];
    }
    
    // Render low-res first for immediate display
    return await _renderLowRes(pageNumber);
  }
  
  /// Render low-resolution page (fast, for immediate display)
  Future<ui.Image?> _renderLowRes(int pageNumber) async {
    if (_document == null || _renderingPages.contains(pageNumber)) {
      return null;
    }
    
    _renderingPages.add(pageNumber);
    
    try {
      final page = await _document!.getPage(pageNumber);
      final pageImage = await page.render(
        width: (page.width * _lowResScale).toInt().toDouble(),
        height: (page.height * _lowResScale).toInt().toDouble(),
        format: PdfPageImageFormat.png,
      );
      await page.close();
      
      if (pageImage != null) {
        final image = await _bytesToImage(pageImage.bytes);
        _lowResCache[pageNumber] = image;
        
        // Start high-res rendering in background
        _renderHighRes(pageNumber);
        
        return image;
      }
    } catch (e) {
      debugPrint('Error rendering low-res page $pageNumber: $e');
    } finally {
      _renderingPages.remove(pageNumber);
    }
    
    return null;
  }
  
  /// Render high-resolution page in background
  Future<void> _renderHighRes(int pageNumber) async {
    if (_document == null || 
        _renderingPages.contains(pageNumber) ||
        _highResCache.containsKey(pageNumber)) {
      return;
    }
    
    _renderingPages.add(pageNumber);
    
    try {
      // Run in compute isolate to avoid blocking UI
      final result = await compute(_renderPageIsolate, {
        'path': _document!.sourceName,
        'pageNumber': pageNumber,
        'scale': _highResScale,
      });
      
      if (result != null) {
        final image = await _bytesToImage(result);
        _highResCache[pageNumber] = image;
      }
    } catch (e) {
      debugPrint('Error rendering high-res page $pageNumber: $e');
    } finally {
      _renderingPages.remove(pageNumber);
    }
  }
  
  /// Pre-fetch adjacent pages based on scroll direction
  void _prefetchAdjacentPages() {
    for (int i = 1; i <= _prefetchDistance; i++) {
      final nextPage = _currentPage + i;
      final prevPage = _currentPage - i;
      
      if (nextPage <= (_document?.pagesCount ?? 0)) {
        _renderLowRes(nextPage);
      }
      if (prevPage > 0) {
        _renderLowRes(prevPage);
      }
    }
  }
  
  /// Evict pages far from current view to free memory
  void _evictDistantPages() {
    final pagesToKeep = <int>{};
    
    // Keep current page and nearby pages
    for (int i = -_maxCachedPages ~/ 2; i <= _maxCachedPages ~/ 2; i++) {
      final page = _currentPage + i;
      if (page > 0 && page <= (_document?.pagesCount ?? 0)) {
        pagesToKeep.add(page);
      }
    }
    
    // Remove distant pages from cache
    _highResCache.removeWhere((page, _) => !pagesToKeep.contains(page));
    _lowResCache.removeWhere((page, _) => !pagesToKeep.contains(page));
  }
  
  /// Convert bytes to UI image
  Future<ui.Image> _bytesToImage(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  }
  
  /// Dispose resources
  void dispose() {
    _highResCache.clear();
    _lowResCache.clear();
    _renderingPages.clear();
    _document?.close();
  }
}

/// Isolate function for rendering pages in background
Future<Uint8List?> _renderPageIsolate(Map<String, dynamic> params) async {
  try {
    final document = await PdfDocument.openFile(params['path'] as String);
    final page = await document.getPage(params['pageNumber'] as int);
    final scale = params['scale'] as double;
    
    final pageImage = await page.render(
      width: (page.width * scale).toInt().toDouble(),
      height: (page.height * scale).toInt().toDouble(),
      format: PdfPageImageFormat.png,
    );
    
    await page.close();
    await document.close();
    
    return pageImage?.bytes;
  } catch (e) {
    debugPrint('Isolate rendering error: $e');
    return null;
  }
}
