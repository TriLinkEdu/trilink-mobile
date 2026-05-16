import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';
import '../widgets/enhanced_textbook_viewer.dart';
import '../services/textbook_reading_service.dart';

class TextbookViewerScreen extends StatefulWidget {
  final String textbookId;
  final String localPath;
  final String title;
  final bool fromCache;

  const TextbookViewerScreen({
    super.key,
    required this.textbookId,
    required this.localPath,
    required this.title,
    required this.fromCache,
  });

  @override
  State<TextbookViewerScreen> createState() => _TextbookViewerScreenState();
}

class _TextbookViewerScreenState extends State<TextbookViewerScreen> {
  bool _useSimpleViewer = false; // Use enhanced viewer with all features

  @override
  Widget build(BuildContext context) {
    if (_useSimpleViewer) {
      return _SimpleTextbookViewer(
        localPath: widget.localPath,
        title: widget.title,
        fromCache: widget.fromCache,
      );
    }

    return FutureBuilder(
      future: TextbookReadingService.loadReadingState(widget.textbookId),
      builder: (context, snapshot) {
        return EnhancedTextbookViewer(
          textbookId: widget.textbookId,
          localPath: widget.localPath,
          title: widget.title,
          initialState: snapshot.data,
        );
      },
    );
  }
}

/// Simple fallback PDF viewer
class _SimpleTextbookViewer extends StatefulWidget {
  final String localPath;
  final String title;
  final bool fromCache;

  const _SimpleTextbookViewer({
    required this.localPath,
    required this.title,
    required this.fromCache,
  });

  @override
  State<_SimpleTextbookViewer> createState() => _SimpleTextbookViewerState();
}

class _SimpleTextbookViewerState extends State<_SimpleTextbookViewer> {
  PdfController? _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  Future<void> _initController() async {
    try {
      // Check if file exists first
      final file = File(widget.localPath);
      if (!await file.exists()) {
        throw Exception('PDF file not found at: ${widget.localPath}');
      }

      final fileSize = await file.length();
      if (fileSize == 0) {
        throw Exception('PDF file is empty');
      }

      _controller = PdfController(
        document: PdfDocument.openFile(widget.localPath),
      );
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Text(
                widget.fromCache ? 'Cached' : 'Updated',
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),
          ),
        ],
      ),
      body: _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text('Cannot open this PDF'),
                  const SizedBox(height: 8),
                  Text(
                    'Error: $_error',
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            )
          : _controller != null
              ? PdfView(
                  controller: _controller!,
                  scrollDirection: Axis.vertical,
                  renderer: _renderPage,
                )
              : const Center(child: CircularProgressIndicator()),
    );
  }

  Future<PdfPageImage?> _renderPage(PdfPage page) {
    final aspectRatio = page.width / page.height;
    final hasIssue = aspectRatio > 2.0 || aspectRatio < 0.3;
    final renderWidth = page.width * 2;
    final renderHeight = hasIssue ? renderWidth / 0.707 : page.height * 2;
    return page.render(
      width: renderWidth,
      height: renderHeight,
      format: PdfPageImageFormat.png,
      backgroundColor: '#FFFFFF',
    );
  }
}
