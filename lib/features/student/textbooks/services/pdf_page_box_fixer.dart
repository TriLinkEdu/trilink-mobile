import 'dart:io';
import 'package:pdfx/pdfx.dart';

/// Fixes PDF page bounding box issues
class PdfPageBoxFixer {
  /// Analyze PDF and detect bounding box issues
  static Future<PdfBoxAnalysis> analyzePdf(String path) async {
    try {
      final document = await PdfDocument.openFile(path);
      final issues = <String>[];
      
      // Check first few pages for dimension issues
      for (int i = 1; i <= 3 && i <= document.pagesCount; i++) {
        final page = await document.getPage(i);
        
        // Check for excessive whitespace (aspect ratio issues)
        final aspectRatio = page.width / page.height;
        
        if (aspectRatio > 2.0 || aspectRatio < 0.3) {
          issues.add('Page $i has unusual aspect ratio: ${aspectRatio.toStringAsFixed(2)}');
        }
        
        // Check for very large dimensions (indicates wrong bounding box)
        if (page.width > 2000 || page.height > 2000) {
          issues.add('Page $i has excessive dimensions: ${page.width}x${page.height}');
        }
        
        await page.close();
      }
      
      await document.close();
      
      return PdfBoxAnalysis(
        hasIssues: issues.isNotEmpty,
        issues: issues,
        needsFixing: issues.isNotEmpty,
      );
    } catch (e) {
      return PdfBoxAnalysis(
        hasIssues: true,
        issues: ['Error analyzing PDF: $e'],
        needsFixing: false,
      );
    }
  }
  
  /// Get optimal render dimensions for a page
  static Future<RenderDimensions> getOptimalDimensions(
    PdfPage page,
    double targetWidth,
  ) async {
    // Calculate aspect ratio
    final aspectRatio = page.width / page.height;
    
    // Detect if this is a problematic page
    final isProblematic = aspectRatio > 2.0 || aspectRatio < 0.3;
    
    if (isProblematic) {
      // Use standard A4 aspect ratio (210/297 = 0.707)
      const standardAspectRatio = 0.707;
      final height = targetWidth / standardAspectRatio;
      
      return RenderDimensions(
        width: targetWidth,
        height: height,
        isFixed: true,
        originalAspectRatio: aspectRatio,
      );
    }
    
    // Normal page - use actual dimensions
    final height = targetWidth / aspectRatio;
    return RenderDimensions(
      width: targetWidth,
      height: height,
      isFixed: false,
      originalAspectRatio: aspectRatio,
    );
  }
}

class PdfBoxAnalysis {
  final bool hasIssues;
  final List<String> issues;
  final bool needsFixing;
  
  const PdfBoxAnalysis({
    required this.hasIssues,
    required this.issues,
    required this.needsFixing,
  });
}

class RenderDimensions {
  final double width;
  final double height;
  final bool isFixed;
  final double originalAspectRatio;
  
  const RenderDimensions({
    required this.width,
    required this.height,
    required this.isFixed,
    required this.originalAspectRatio,
  });
}
