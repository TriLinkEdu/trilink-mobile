import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';

/// Custom PDF page widget that handles cropbox/mediabox issues
class FixedPdfPageView extends StatefulWidget {
  final PdfDocument document;
  final int pageNumber;
  final BoxFit fit;
  
  const FixedPdfPageView({
    super.key,
    required this.document,
    required this.pageNumber,
    this.fit = BoxFit.contain,
  });

  @override
  State<FixedPdfPageView> createState() => _FixedPdfPageViewState();
}

class _FixedPdfPageViewState extends State<FixedPdfPageView> {
  PdfPageImage? _pageImage;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _renderPage();
  }

  @override
  void didUpdateWidget(FixedPdfPageView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pageNumber != widget.pageNumber) {
      _renderPage();
    }
  }

  Future<void> _renderPage() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final page = await widget.document.getPage(widget.pageNumber);
      
      // Get screen width for optimal rendering
      final screenWidth = MediaQuery.of(context).size.width;
      final pixelRatio = MediaQuery.of(context).devicePixelRatio;
      
      // Calculate render dimensions
      // Force standard aspect ratio if page has issues
      final aspectRatio = page.width / page.height;
      final hasIssue = aspectRatio > 2.0 || aspectRatio < 0.3;
      
      double renderWidth;
      double renderHeight;
      
      if (hasIssue) {
        // Use standard A4 aspect ratio
        renderWidth = screenWidth * pixelRatio;
        renderHeight = renderWidth / 0.707; // A4 ratio
      } else {
        // Use actual page dimensions
        renderWidth = screenWidth * pixelRatio;
        renderHeight = renderWidth / aspectRatio;
      }
      
      // Render with fixed dimensions
      final pageImage = await page.render(
        width: renderWidth.toInt().toDouble(),
        height: renderHeight.toInt().toDouble(),
        format: PdfPageImageFormat.png,
        backgroundColor: '#FFFFFF',
        // Crop to remove excessive whitespace
        cropRect: hasIssue ? null : null, // pdfx doesn't support cropRect
      );
      
      await page.close();
      
      if (mounted) {
        setState(() {
          _pageImage = pageImage;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red),
            SizedBox(height: 16),
            Text('Failed to render page'),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: _renderPage,
              child: Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_pageImage == null) {
      return Center(child: Text('No image'));
    }

    return Container(
      color: Colors.white,
      child: Image.memory(
        _pageImage!.bytes,
        fit: widget.fit,
        filterQuality: FilterQuality.high,
      ),
    );
  }

  @override
  void dispose() {
    _pageImage?.dispose();
    super.dispose();
  }
}
