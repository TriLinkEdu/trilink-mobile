import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';

class ThumbnailNavigator extends StatefulWidget {
  final PdfController pdfController;
  final int currentPage;
  final Function(int) onPageSelected;

  const ThumbnailNavigator({
    super.key,
    required this.pdfController,
    required this.currentPage,
    required this.onPageSelected,
  });

  @override
  State<ThumbnailNavigator> createState() => _ThumbnailNavigatorState();
}

class _ThumbnailNavigatorState extends State<ThumbnailNavigator> {
  late ScrollController _scrollController;
  List<Widget> _thumbnails = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _generateThumbnails();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _generateThumbnails() async {
    try {
      final document = await widget.pdfController.document;
      final pageCount = document.pagesCount;
      final thumbnails = <Widget>[];

      for (int i = 1; i <= pageCount; i++) {
        thumbnails.add(_ThumbnailItem(
          pageNumber: i,
          document: document,
          isSelected: i == widget.currentPage,
          onTap: () => widget.onPageSelected(i),
        ));
      }

      if (mounted) {
        setState(() {
          _thumbnails = thumbnails;
          _isLoading = false;
        });
        
        // Scroll to current page
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToCurrentPage();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _scrollToCurrentPage() {
    if (_thumbnails.isEmpty) return;
    
    const itemHeight = 120.0;
    const itemsPerRow = 3;
    final rowIndex = (widget.currentPage - 1) ~/ itemsPerRow;
    final targetOffset = rowIndex * itemHeight;
    
    _scrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  'Pages',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  'Page ${widget.currentPage}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Thumbnails
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : GridView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 0.7,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: _thumbnails.length,
                    itemBuilder: (context, index) => _thumbnails[index],
                  ),
          ),
        ],
      ),
    );
  }
}

class _ThumbnailItem extends StatefulWidget {
  final int pageNumber;
  final PdfDocument document;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThumbnailItem({
    required this.pageNumber,
    required this.document,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_ThumbnailItem> createState() => _ThumbnailItemState();
}

class _ThumbnailItemState extends State<_ThumbnailItem> {
  Widget? _thumbnail;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _generateThumbnail();
  }

  Future<void> _generateThumbnail() async {
    try {
      final page = await widget.document.getPage(widget.pageNumber);
      final pageImage = await page.render(
        width: 150,
        height: (150 * page.height / page.width).round().toDouble(),
      );
      
      if (mounted && pageImage != null && pageImage.bytes != null) {
        setState(() {
          _thumbnail = Image.memory(
            pageImage.bytes!,
            fit: BoxFit.cover,
          );
          _isLoading = false;
        });
      }
      
      page.close();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: widget.isSelected 
                ? theme.colorScheme.primary 
                : theme.colorScheme.outline.withOpacity(0.3),
            width: widget.isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(7),
                  ),
                ),
                child: _isLoading
                    ? const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : _thumbnail ?? const Icon(Icons.error_outline),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: widget.isSelected 
                    ? theme.colorScheme.primary.withOpacity(0.1)
                    : theme.colorScheme.surface,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(7),
                ),
              ),
              child: Text(
                '${widget.pageNumber}',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: widget.isSelected 
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface,
                  fontWeight: widget.isSelected 
                      ? FontWeight.w600 
                      : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}