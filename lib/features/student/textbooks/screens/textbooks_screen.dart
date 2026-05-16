import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/subject_visuals.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/illustrations.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../../shared/widgets/student_page_background.dart';
import '../cubit/textbook_cubit.dart';
import '../cubit/download_progress_cubit.dart';
import '../models/textbook_model.dart';
import '../repositories/textbook_file_cache_service.dart';
import '../repositories/textbook_repository.dart';
import '../widgets/enhanced_textbook_card.dart';
import '../widgets/download_progress_dialog.dart';
import 'textbook_viewer_screen.dart';

class TextbooksScreen extends StatelessWidget {
  const TextbooksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => TextbookCubit(sl<TextbookRepository>())..loadTextbooks(),
        ),
        BlocProvider(
          create: (_) => DownloadProgressCubit(),
        ),
      ],
      child: const _TextbooksView(),
    );
  }
}

class _TextbooksView extends StatefulWidget {
  const _TextbooksView();

  @override
  State<_TextbooksView> createState() => _TextbooksViewState();
}

class _TextbooksViewState extends State<_TextbooksView> {
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _colorForSubject(String subject) => SubjectVisuals.colorOf(subject);

  IconData _iconForSubject(String subject) => SubjectVisuals.iconOf(subject);

  Future<void> _openTextbook(
    BuildContext context,
    TextbookModel textbook,
  ) async {
    // Create a unique download ID
    final downloadId = 'textbook_${textbook.id}_${DateTime.now().millisecondsSinceEpoch}';
    
    try {
      // Use a DownloadProgressCubit to track progress
      if (!context.mounted) return;
      
      // Get or create the progress cubit
      final progressCubit = context.read<DownloadProgressCubit>();
      
      // Flag to track cancellation
      bool cancelled = false;

      // Start the download and show progress dialog
      progressCubit.startDownload(
        id: downloadId,
        name: textbook.title,
        totalBytes: textbook.sizeBytes ?? 0,
      );

      // Show progress dialog
      showDownloadProgressDialog(
        context,
        downloadId: downloadId,
        onCancel: () {
          cancelled = true;
        },
      );

      // Prepare the PDF with progress tracking
      final result = await sl<TextbookFileCacheService>().prepareLocalPdf(
        textbook,
        onProgress: (downloaded, total) {
          if (!cancelled) {
            progressCubit.updateProgress(
              id: downloadId,
              downloadedBytes: downloaded,
            );
          }
        },
        shouldCancel: () => cancelled,
      );

      // Mark as complete
      progressCubit.completeDownload(downloadId);

      // Wait a bit for the UI to update
      await Future.delayed(const Duration(milliseconds: 500));

      if (!context.mounted) return;

      // dismiss dialog
      Navigator.of(context, rootNavigator: true).pop(null);

      // Navigate to viewer
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => TextbookViewerScreen(
            textbookId: textbook.id,
            localPath: result.localPath,
            title: textbook.title,
            fromCache: result.fromCache,
          ),
        ),
      );

      // Clean up
      progressCubit.removeDownload(downloadId);
    } catch (e, stackTrace) {
      debugPrint('Error opening textbook: $e');
      debugPrint('StackTrace: $stackTrace');
      
      // Mark as failed
      final progressCubit = context.read<DownloadProgressCubit>();
      progressCubit.failDownload(
        id: downloadId,
        errorMessage: e.toString().split('\n').first,
      );

      // The dialog is already showing the error state, no need for another snackbar
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TextbookCubit, TextbookState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Textbooks'),
            actions: [
              if (state.textbooks.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Center(
                    child: Chip(
                      label: Text('${state.textbooks.length} Textbooks'),
                      backgroundColor: AppColors.primary.withAlpha(30),
                      labelStyle: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          body: StudentPageBackground(
            child: state.status == TextbookStatus.loading
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: ShimmerList(),
                  )
                : state.status == TextbookStatus.error
                ? AppErrorWidget(
                    message: state.errorMessage ?? 'Unable to load textbooks.',
                    onRetry: () =>
                        context.read<TextbookCubit>().loadTextbooks(),
                  )
                : state.textbooks.isEmpty
                ? EmptyStateWidget(
                    illustration: BooksIllustration(),
                    icon: Icons.menu_book_rounded,
                    title: 'No textbooks available',
                    subtitle: 'Textbooks will appear here when added.',
                    actionLabel: 'Refresh',
                    onAction: () => context.read<TextbookCubit>().loadTextbooks(),
                  )
                : Column(
                    children: [
                      // Search bar
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search textbooks...',
                            prefixIcon: const Icon(Icons.search_rounded),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded),
                                    onPressed: () {
                                      _searchController.clear();
                                      context
                                          .read<TextbookCubit>()
                                          .searchTextbooks('');
                                    },
                                  )
                                : null,
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(AppRadius.md),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          onChanged: (value) {
                            setState(() {});
                            context
                                .read<TextbookCubit>()
                                .searchTextbooks(value);
                          },
                        ),
                      ),

                      // Filter chips
                      if (state.availableSubjects.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                // "All" chip
                                FilterChip(
                                  label: const Text('All'),
                                  selected: state.selectedSubject == null,
                                  onSelected: (_) {
                                    context
                                        .read<TextbookCubit>()
                                        .filterBySubject(null);
                                  },
                                ),
                                const SizedBox(width: 8),
                                // Subject chips
                                ...state.availableSubjects.map((subject) {
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: FilterChip(
                                      label: Text(subject),
                                      selected: state.selectedSubject == subject,
                                      onSelected: (_) {
                                        context
                                            .read<TextbookCubit>()
                                            .filterBySubject(subject);
                                      },
                                    ),
                                  );
                                }).toList(),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),

                      // Textbooks list
                      Expanded(
                        child: state.displayedTextbooks.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.search_off_rounded,
                                      size: 64,
                                      color: Colors.grey[300],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No textbooks found',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Try adjusting your search or filters',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: Colors.grey[600],
                                          ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                itemCount: state.displayedTextbooks.length,
                                itemBuilder: (context, index) {
                                  final textbook =
                                      state.displayedTextbooks[index];
                                  final subjectColor =
                                      _colorForSubject(textbook.subject);
                                  final subjectIcon =
                                      _iconForSubject(textbook.subject);

                                  return EnhancedTextbookCard(
                                    textbook: textbook,
                                    subjectColor: subjectColor,
                                    subjectIcon: subjectIcon,
                                    onTap: () =>
                                        _openTextbook(context, textbook),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}
