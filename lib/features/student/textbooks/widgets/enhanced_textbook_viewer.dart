import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdfx/pdfx.dart';
import '../models/textbook_reading_models.dart';
import '../services/textbook_reading_service.dart';
import '../services/pdf_toc_extractor.dart';
import '../widgets/thumbnail_navigator.dart';
import '../widgets/table_of_contents.dart';

class EnhancedTextbookViewer extends StatefulWidget {
  final String textbookId;
  final String localPath;
  final String title;
  final TextbookReadingState? initialState;

  const EnhancedTextbookViewer({
    super.key,
    required this.textbookId,
    required this.localPath,
    required this.title,
    this.initialState,
  });

  @override
  State<EnhancedTextbookViewer> createState() => _EnhancedTextbookViewerState();
}

class _EnhancedTextbookViewerState extends State<EnhancedTextbookViewer>
    with TickerProviderStateMixin {
  PdfControllerPinch? _pdfController;
  late TextbookReadingState _readingState;
  late AnimationController _overlayController;
  late Timer _readingTimer;
  
  bool _showOverlay = true;
  bool _isSearching = false;
  String _searchQuery = '';
  List<TextbookSearchResult> _searchResults = [];
  int _currentSearchIndex = 0;

  @override
  void initState() {
    super.initState();
    
    _readingState = widget.initialState ?? TextbookReadingState(
      textbookId: widget.textbookId,
      lastReadAt: DateTime.now(),
    );
    
    _initializePdfController();
    
    _overlayController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _startReadingTimer();
    
    // Show overlay initially and hide after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && _showOverlay) {
        _hideOverlay();
      }
    });
  }

  Future<void> _initializePdfController() async {
    try {
      _pdfController = PdfControllerPinch(
        document: PdfDocument.openFile(widget.localPath),
        initialPage: _readingState.currentPage,
      );
      
      // Wait for document to load to get total pages
      final document = await _pdfController!.document;
      if (document != null && mounted) {
        setState(() {
          _readingState = _readingState.copyWith(
            totalPages: document.pagesCount,
          );
        });
        
        // Analyze PDF for bounding box issues
        _analyzePdfIssues();
      }
      
      _setupPdfListener();
      _preloadAdjacentPages();
      
      // Show overlay initially
      _overlayController.forward();
      
    } catch (e) {
      // Handle PDF loading error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading PDF: ${e.toString()}'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Go Back',
              textColor: Colors.white,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _pdfController?.dispose();
    _overlayController.dispose();
    _readingTimer.cancel();
    super.dispose();
  }

  Future<void> _analyzePdfIssues() async {
    try {
      final document = await _pdfController?.document;
      if (document == null) return;
      
      // Check first page for dimension issues
      final page = await document.getPage(1);
      final aspectRatio = page.width / page.height;
      
      // Log if there are bounding box issues
      if (aspectRatio > 2.0 || aspectRatio < 0.3) {
        print('⚠️ PDF has bounding box issues: aspect ratio = $aspectRatio');
        print('   Page dimensions: ${page.width}x${page.height}');
      }
      
      await page.close();
    } catch (e) {
      print('Error analyzing PDF: $e');
    }
  }

  void _setupPdfListener() {
    _pdfController?.addListener(() {
      final currentPage = _pdfController?.page ?? 1;
      if (currentPage != _readingState.currentPage) {
        _updateReadingProgress(currentPage);
        _preloadAdjacentPages();
      }
    });
  }

  void _startReadingTimer() {
    _readingTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _saveReadingProgress();
    });
  }

  void _updateReadingProgress(int page) {
    setState(() {
      _readingState = _readingState.copyWith(
        currentPage: page,
        lastReadAt: DateTime.now(),
      );
    });
  }

  Future<void> _saveReadingProgress() async {
    await TextbookReadingService.updateProgress(
      widget.textbookId,
      _readingState.currentPage,
      _readingState.totalPages,
      additionalReadingTime: const Duration(seconds: 30),
    );
  }

  Future<void> _preloadAdjacentPages() async {
    if (_pdfController == null) return;
    
    final document = await _pdfController!.document;
    if (document != null) {
      TextbookReadingService.pageCache.preCacheAdjacent(
        widget.textbookId,
        _readingState.currentPage,
        document,
      );
    }
  }

  void _toggleOverlay() {
    setState(() {
      _showOverlay = !_showOverlay;
    });
    
    if (_showOverlay) {
      _overlayController.forward();
    } else {
      _overlayController.reverse();
    }
  }

  void _hideOverlay() {
    if (_showOverlay) {
      setState(() {
        _showOverlay = false;
      });
      _overlayController.reverse();
    }
  }

  void _toggleBookmark() async {
    final currentPage = _readingState.currentPage;
    final bookmarks = Set<int>.from(_readingState.bookmarkedPages);
    
    if (bookmarks.contains(currentPage)) {
      bookmarks.remove(currentPage);
    } else {
      bookmarks.add(currentPage);
    }
    
    setState(() {
      _readingState = _readingState.copyWith(bookmarkedPages: bookmarks);
    });
    
    // Save to storage
    await TextbookReadingService.saveReadingState(widget.textbookId, _readingState);
    
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          bookmarks.contains(currentPage) 
              ? 'Bookmark added to page $currentPage' 
              : 'Bookmark removed from page $currentPage'
        ),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _toggleNightMode() {
    setState(() {
      _readingState = _readingState.copyWith(nightMode: !_readingState.nightMode);
    });
  }

  void _showSearch() {
    setState(() {
      _isSearching = true;
    });
  }

  void _hideSearch() {
    setState(() {
      _isSearching = false;
      _searchQuery = '';
      _searchResults.clear();
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults.clear();
      });
      return;
    }

    // Simple text search simulation - in real app would search PDF text
    setState(() {
      _searchResults = [
        TextbookSearchResult(
          pageNumber: 5,
          snippet: 'Chemistry fundamentals: Understanding "$query" is essential...',
          matches: [TextMatch(startIndex: 35, endIndex: 35 + query.length, matchedText: query)],
        ),
        TextbookSearchResult(
          pageNumber: 12,
          snippet: 'Advanced concepts of "$query" in molecular structure...',
          matches: [TextMatch(startIndex: 22, endIndex: 22 + query.length, matchedText: query)],
        ),
        TextbookSearchResult(
          pageNumber: 18,
          snippet: 'Practical applications where "$query" plays a crucial role...',
          matches: [TextMatch(startIndex: 26, endIndex: 26 + query.length, matchedText: query)],
        ),
      ];
      _currentSearchIndex = 0;
    });
  }

  void _goToSearchResult(int index) {
    if (index >= 0 && index < _searchResults.length && _pdfController != null) {
      final result = _searchResults[index];
      _pdfController!.jumpToPage(result.pageNumber);
      setState(() {
        _currentSearchIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: _readingState.nightMode ? Colors.black : null,
      body: Stack(
        children: [
          // PDF Viewer
          GestureDetector(
            onTap: _toggleOverlay,
            child: _pdfController != null 
                ? ColorFiltered(
                    colorFilter: _readingState.nightMode
                        ? const ColorFilter.matrix([
                            -1, 0, 0, 0, 255,
                            0, -1, 0, 0, 255,
                            0, 0, -1, 0, 255,
                            0, 0, 0, 1, 0,
                          ])
                        : const ColorFilter.matrix([
                            1, 0, 0, 0, 0,
                            0, 1, 0, 0, 0,
                            0, 0, 1, 0, 0,
                            0, 0, 0, 1, 0,
                          ]),
                    child: Opacity(
                      opacity: _readingState.brightness,
                      child: PdfViewPinch(
                        controller: _pdfController!,
                        onPageChanged: (page) {
                          setState(() {
                            _readingState = _readingState.copyWith(currentPage: page);
                          });
                          TextbookReadingService.saveReadingState(widget.textbookId, _readingState);
                        },
                      ),
                    ),
                  )
                : const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Loading PDF...'),
                      ],
                    ),
                  ),
          ),
          
          // Top Overlay
          AnimatedBuilder(
            animation: _overlayController,
            builder: (context, child) {
              return Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Transform.translate(
                  offset: Offset(0, -100 * (1 - _overlayController.value)),
                  child: Container(
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top + 8,
                      left: 16,
                      right: 16,
                      bottom: 16,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.7),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                        ),
                        Expanded(
                          child: Text(
                            widget.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          onPressed: _showSearch,
                          icon: const Icon(Icons.search, color: Colors.white),
                        ),
                        IconButton(
                          onPressed: _toggleBookmark,
                          icon: Icon(
                            _readingState.bookmarkedPages.contains(_readingState.currentPage)
                                ? Icons.bookmark
                                : Icons.bookmark_border,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          
          // Bottom Overlay
          AnimatedBuilder(
            animation: _overlayController,
            builder: (context, child) {
              return Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Transform.translate(
                  offset: Offset(0, 100 * (1 - _overlayController.value)),
                  child: Container(
                    padding: EdgeInsets.only(
                      top: 16,
                      left: 16,
                      right: 16,
                      bottom: MediaQuery.of(context).padding.bottom + 16,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.7),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Progress bar
                        Row(
                          children: [
                            Text(
                              '${_readingState.currentPage}',
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: LinearProgressIndicator(
                                value: _readingState.progressPercent,
                                backgroundColor: Colors.white.withOpacity(0.3),
                                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${_readingState.totalPages}',
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Controls
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            IconButton(
                              onPressed: _toggleNightMode,
                              icon: Icon(
                                _readingState.nightMode 
                                    ? Icons.light_mode 
                                    : Icons.dark_mode,
                                color: Colors.white,
                              ),
                            ),
                            IconButton(
                              onPressed: () async {
                                // Extract real TOC from PDF
                                final toc = await PdfTocExtractor.extractToc(widget.localPath);
                                
                                if (toc.isEmpty) {
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('This PDF has no table of contents'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                  return;
                                }
                                
                                if (!mounted) return;
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  builder: (context) => TableOfContents(
                                    entries: toc,
                                    currentPage: _readingState.currentPage,
                                    onPageSelected: (page) {
                                      _pdfController?.jumpToPage(page);
                                      Navigator.pop(context);
                                    },
                                  ),
                                );
                              },
                              icon: const Icon(Icons.list, color: Colors.white),
                            ),
                            IconButton(
                              onPressed: () {
                                if (_pdfController != null) {
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    builder: (context) => ThumbnailNavigator(
                                      pdfController: _pdfController!,
                                      currentPage: _readingState.currentPage,
                                      onPageSelected: (page) {
                                        _pdfController?.jumpToPage(page);
                                        Navigator.pop(context);
                                      },
                                    ),
                                  );
                                }
                              },
                              icon: const Icon(Icons.view_module, color: Colors.white),
                            ),
                            IconButton(
                              onPressed: () {
                                showModalBottomSheet(
                                  context: context,
                                  builder: (context) => Container(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Text('Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 16),
                                        ListTile(
                                          leading: const Icon(Icons.screen_rotation),
                                          title: const Text('Portrait Mode'),
                                          onTap: () {
                                            SystemChrome.setPreferredOrientations([
                                              DeviceOrientation.portraitUp,
                                              DeviceOrientation.portraitDown,
                                            ]);
                                            Navigator.pop(context);
                                          },
                                        ),
                                        ListTile(
                                          leading: const Icon(Icons.stay_current_landscape),
                                          title: const Text('Landscape Mode'),
                                          onTap: () {
                                            SystemChrome.setPreferredOrientations([
                                              DeviceOrientation.landscapeLeft,
                                              DeviceOrientation.landscapeRight,
                                            ]);
                                            Navigator.pop(context);
                                          },
                                        ),
                                        ListTile(
                                          leading: const Icon(Icons.screen_lock_rotation),
                                          title: const Text('Auto Rotate'),
                                          onTap: () {
                                            SystemChrome.setPreferredOrientations([
                                              DeviceOrientation.portraitUp,
                                              DeviceOrientation.portraitDown,
                                              DeviceOrientation.landscapeLeft,
                                              DeviceOrientation.landscapeRight,
                                            ]);
                                            Navigator.pop(context);
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.settings, color: Colors.white),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          
          // Search Overlay
          if (_isSearching)
            Positioned(
              top: MediaQuery.of(context).padding.top,
              left: 0,
              right: 0,
              child: Container(
                color: theme.colorScheme.surface,
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            autofocus: true,
                            decoration: const InputDecoration(
                              hintText: 'Search in textbook...',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.search),
                            ),
                            onChanged: (value) {
                              _searchQuery = value;
                              _performSearch(value);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: _hideSearch,
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    if (_searchResults.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text('${_searchResults.length} results'),
                          const Spacer(),
                          IconButton(
                            onPressed: _currentSearchIndex > 0 
                                ? () => _goToSearchResult(_currentSearchIndex - 1)
                                : null,
                            icon: const Icon(Icons.keyboard_arrow_up),
                          ),
                          Text('${_currentSearchIndex + 1}'),
                          IconButton(
                            onPressed: _currentSearchIndex < _searchResults.length - 1
                                ? () => _goToSearchResult(_currentSearchIndex + 1)
                                : null,
                            icon: const Icon(Icons.keyboard_arrow_down),
                          ),
                        ],
                      ),
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          border: Border.all(color: theme.dividerColor),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListView.builder(
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            final result = _searchResults[index];
                            return ListTile(
                              title: Text('Page ${result.pageNumber}'),
                              subtitle: Text(result.snippet),
                              onTap: () => _goToSearchResult(index),
                              selected: index == _currentSearchIndex,
                              selectedTileColor: theme.colorScheme.primaryContainer.withOpacity(0.3),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}