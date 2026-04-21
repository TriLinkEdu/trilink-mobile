import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';

class TextbookViewerScreen extends StatefulWidget {
  final String localPath;
  final String title;
  final bool fromCache;

  const TextbookViewerScreen({
    super.key,
    required this.localPath,
    required this.title,
    required this.fromCache,
  });

  @override
  State<TextbookViewerScreen> createState() => _TextbookViewerScreenState();
}

class _TextbookViewerScreenState extends State<TextbookViewerScreen> {
  late final PdfControllerPinch _controller;

  @override
  void initState() {
    super.initState();
    _controller = PdfControllerPinch(
      document: PdfDocument.openFile(widget.localPath),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
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
      body: PdfViewPinch(controller: _controller),
    );
  }
}
