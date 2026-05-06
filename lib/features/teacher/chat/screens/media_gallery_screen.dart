import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/constants/api_constants.dart';

class MediaGalleryScreen extends StatefulWidget {
  final String conversationId;

  const MediaGalleryScreen({super.key, required this.conversationId});

  @override
  State<MediaGalleryScreen> createState() => _MediaGalleryScreenState();
}

class _MediaGalleryScreenState extends State<MediaGalleryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _loading = true;
  List<Map<String, dynamic>> _images = [];
  List<Map<String, dynamic>> _files = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadMedia();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMedia() async {
    setState(() => _loading = true);
    try {
      final raw = await ApiService().getConversationMedia(widget.conversationId);
      if (!mounted) return;

      // raw is a grouped object: { images: [...], videos: [...], audio: [...], files: [...] }
      List<Map<String, dynamic>> images = [];
      List<Map<String, dynamic>> files = [];

      if (raw is List) {
        // Flat list fallback
        for (final item in raw) {
          final m = item as Map<String, dynamic>;
          final type = m['mediaType'] as String? ?? '';
          if (type == 'image' || type == 'video') {
            images.add(m);
          } else {
            files.add(m);
          }
        }
      } else if (raw is Map) {
        final grouped = raw as Map<String, dynamic>;
        images = [
          ...(grouped['images'] as List<dynamic>? ?? [])
              .cast<Map<String, dynamic>>(),
          ...(grouped['videos'] as List<dynamic>? ?? [])
              .cast<Map<String, dynamic>>(),
        ];
        files = [
          ...(grouped['files'] as List<dynamic>? ?? [])
              .cast<Map<String, dynamic>>(),
          ...(grouped['audio'] as List<dynamic>? ?? [])
              .cast<Map<String, dynamic>>(),
        ];
      }

      setState(() {
        _images = images;
        _files = files;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  String _mediaUrl(Map<String, dynamic> item) {
    final fileId = item['mediaFileId'] as String?;
    if (fileId != null && fileId.isNotEmpty) {
      return '${ApiConstants.fileBaseUrl}/api${ApiConstants.file(fileId)}';
    }
    return item['mediaUrl'] as String? ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new,
              color: theme.colorScheme.onSurface, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Media & Files',
          style: TextStyle(
              color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Media'),
            Tab(text: 'Files'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildMediaGrid(),
                _buildFilesList(),
              ],
            ),
    );
  }

  Widget _buildMediaGrid() {
    if (_images.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.photo_library_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              'No media shared yet',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: _images.length,
      itemBuilder: (context, index) {
        final item = _images[index];
        final url = _mediaUrl(item);
        final isVideo = (item['mediaType'] as String? ?? '') == 'video';

        return GestureDetector(
          onTap: () => _openFullScreen(url, isVideo),
          child: Stack(
            fit: StackFit.expand,
            children: [
              url.isNotEmpty
                  ? Image.network(
                      url,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Theme.of(context).colorScheme.surfaceContainerLow,
                        child: Icon(Icons.broken_image_outlined,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant),
                      ),
                    )
                  : Container(
                      color: Theme.of(context).colorScheme.surfaceContainerLow,
                    ),
              if (isVideo)
                const Center(
                  child: Icon(Icons.play_circle_outline,
                      color: Colors.white, size: 32),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilesList() {
    if (_files.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.folder_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              'No files shared yet',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _files.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = _files[index];
        final name = item['mediaName'] as String? ?? 'File';
        final size = item['mediaSize'] as int?;
        final type = item['mediaType'] as String? ?? 'file';
        final url = _mediaUrl(item);

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  type == 'audio' ? Icons.audio_file : Icons.insert_drive_file,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (size != null)
                      Text(
                        _formatSize(size),
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              if (url.isNotEmpty)
                IconButton(
                  icon: Icon(Icons.open_in_new,
                      color: AppColors.primary, size: 20),
                  onPressed: () => _openUrl(url),
                ),
            ],
          ),
        );
      },
    );
  }

  void _openFullScreen(String url, bool isVideo) {
    if (url.isEmpty) return;
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.broken_image_outlined,
                    color: Colors.white,
                    size: 64,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openUrl(String url) {
    // url_launcher would be used here in production
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Opening: $url')),
    );
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
