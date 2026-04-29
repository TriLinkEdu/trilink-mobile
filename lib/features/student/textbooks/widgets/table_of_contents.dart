import 'package:flutter/material.dart';
import '../models/textbook_reading_models.dart';

class TableOfContents extends StatelessWidget {
  final List<TocEntry> entries;
  final int currentPage;
  final Function(int) onPageSelected;

  const TableOfContents({
    super.key,
    required this.entries,
    required this.currentPage,
    required this.onPageSelected,
  });

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
                Icon(
                  Icons.list_rounded,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Table of Contents',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Contents
          Expanded(
            child: entries.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.menu_book_outlined,
                          size: 48,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No table of contents available',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'This textbook doesn\'t have embedded navigation',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: entries.length,
                    itemBuilder: (context, index) {
                      return _TocEntryWidget(
                        entry: entries[index],
                        currentPage: currentPage,
                        onPageSelected: onPageSelected,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _TocEntryWidget extends StatelessWidget {
  final TocEntry entry;
  final int currentPage;
  final Function(int) onPageSelected;

  const _TocEntryWidget({
    required this.entry,
    required this.currentPage,
    required this.onPageSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCurrentSection = currentPage >= entry.pageNumber && 
        (entry.children.isEmpty || 
         currentPage < (entry.children.isNotEmpty 
             ? entry.children.first.pageNumber 
             : entry.pageNumber + 1));
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => onPageSelected(entry.pageNumber),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              left: entry.level * 16.0,
              right: 16,
              top: 12,
              bottom: 12,
            ),
            decoration: BoxDecoration(
              color: isCurrentSection 
                  ? theme.colorScheme.primaryContainer.withOpacity(0.3)
                  : null,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                // Level indicator
                if (entry.level > 0)
                  Container(
                    width: 2,
                    height: 20,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: _getLevelColor(theme, entry.level),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                
                // Icon based on level
                Icon(
                  _getIconForLevel(entry.level),
                  size: 18,
                  color: isCurrentSection 
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
                
                const SizedBox(width: 12),
                
                // Title
                Expanded(
                  child: Text(
                    entry.title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: isCurrentSection 
                          ? FontWeight.w600 
                          : FontWeight.normal,
                      color: isCurrentSection 
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                
                // Page number
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isCurrentSection 
                        ? theme.colorScheme.primary.withOpacity(0.1)
                        : theme.colorScheme.surfaceVariant.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${entry.pageNumber}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: isCurrentSection 
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Children
        if (entry.children.isNotEmpty)
          ...entry.children.map(
            (child) => _TocEntryWidget(
              entry: child,
              currentPage: currentPage,
              onPageSelected: onPageSelected,
            ),
          ),
      ],
    );
  }

  IconData _getIconForLevel(int level) {
    switch (level) {
      case 0:
        return Icons.book_rounded;
      case 1:
        return Icons.article_rounded;
      case 2:
        return Icons.article_rounded;
      default:
        return Icons.circle;
    }
  }

  Color _getLevelColor(ThemeData theme, int level) {
    final colors = [
      theme.colorScheme.primary,
      theme.colorScheme.secondary,
      theme.colorScheme.tertiary,
    ];
    return colors[level % colors.length];
  }
}

/// Mock TOC generator for PDFs without embedded navigation
class MockTocGenerator {
  static List<TocEntry> generateMockToc(int totalPages) {
    if (totalPages < 10) return [];
    
    final entries = <TocEntry>[];
    final chaptersCount = (totalPages / 20).ceil().clamp(3, 8);
    
    for (int i = 0; i < chaptersCount; i++) {
      final startPage = (i * totalPages / chaptersCount).round() + 1;
      final chapterTitle = _getChapterTitle(i + 1);
      
      entries.add(TocEntry(
        title: chapterTitle,
        pageNumber: startPage,
        level: 0,
        children: _generateSubsections(startPage, totalPages ~/ chaptersCount),
      ));
    }
    
    return entries;
  }

  static String _getChapterTitle(int chapterNumber) {
    final titles = [
      'Introduction',
      'Fundamentals',
      'Core Concepts',
      'Advanced Topics',
      'Applications',
      'Case Studies',
      'Summary',
      'Appendix',
    ];
    
    if (chapterNumber <= titles.length) {
      return 'Chapter $chapterNumber: ${titles[chapterNumber - 1]}';
    }
    
    return 'Chapter $chapterNumber';
  }

  static List<TocEntry> _generateSubsections(int startPage, int chapterLength) {
    if (chapterLength < 5) return [];
    
    final subsections = <TocEntry>[];
    final subsectionCount = (chapterLength / 5).ceil().clamp(2, 4);
    
    for (int i = 0; i < subsectionCount; i++) {
      final page = startPage + (i * chapterLength / subsectionCount).round();
      subsections.add(TocEntry(
        title: 'Section ${i + 1}',
        pageNumber: page,
        level: 1,
      ));
    }
    
    return subsections;
  }
}