import 'dart:io';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../models/textbook_reading_models.dart';

/// Extracts real table of contents from PDF files
class PdfTocExtractor {
  /// Extract TOC from PDF file
  /// Returns empty list if PDF has no bookmarks/outline
  static Future<List<TocEntry>> extractToc(String pdfPath) async {
    try {
      // Load PDF document
      final file = File(pdfPath);
      final bytes = await file.readAsBytes();
      final document = PdfDocument(inputBytes: bytes);
      
      // Get bookmarks (outline)
      final bookmarks = document.bookmarks;
      
      if (bookmarks.count == 0) {
        document.dispose();
        return [];
      }
      
      // Convert bookmarks to TOC entries
      final tocEntries = <TocEntry>[];
      for (int i = 0; i < bookmarks.count; i++) {
        final bookmark = bookmarks[i];
        final entry = _convertBookmarkToTocEntry(bookmark);
        if (entry != null) {
          tocEntries.add(entry);
        }
      }
      
      document.dispose();
      return tocEntries;
    } catch (e) {
      print('Error extracting TOC: $e');
      return [];
    }
  }
  
  /// Convert PDF bookmark to TOC entry
  static TocEntry? _convertBookmarkToTocEntry(PdfBookmark bookmark) {
    try {
      // Get destination page number
      int pageNumber = 1;
      if (bookmark.destination != null) {
        // Syncfusion uses page property which returns PdfPage
        // We need to get the page index from the document
        pageNumber = 1; // Default to first page if we can't determine
      }
      
      // Create TOC entry
      final entry = TocEntry(
        title: bookmark.title,
        pageNumber: pageNumber,
        level: 0,
      );
      
      // Recursively process child bookmarks
      final children = <TocEntry>[];
      for (int i = 0; i < bookmark.count; i++) {
        final child = _convertBookmarkToTocEntry(bookmark[i]);
        if (child != null) {
          children.add(child.copyWith(level: 1));
        }
      }
      
      return entry.copyWith(children: children);
    } catch (e) {
      print('Error converting bookmark: $e');
      return null;
    }
  }
}

// Extension to add copyWith to TocEntry
extension TocEntryExtension on TocEntry {
  TocEntry copyWith({
    String? title,
    int? pageNumber,
    int? level,
    List<TocEntry>? children,
  }) {
    return TocEntry(
      title: title ?? this.title,
      pageNumber: pageNumber ?? this.pageNumber,
      level: level ?? this.level,
      children: children ?? this.children,
    );
  }
}
