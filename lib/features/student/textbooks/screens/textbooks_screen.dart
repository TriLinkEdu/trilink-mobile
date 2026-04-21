import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/illustrations.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../../shared/widgets/student_page_background.dart';
import '../cubit/textbook_cubit.dart';
import '../models/textbook_model.dart';
import '../repositories/textbook_file_cache_service.dart';
import '../repositories/textbook_repository.dart';
import 'textbook_viewer_screen.dart';

class TextbooksScreen extends StatelessWidget {
  const TextbooksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TextbookCubit(sl<TextbookRepository>())..loadTextbooks(),
      child: const _TextbooksView(),
    );
  }
}

class _TextbooksView extends StatelessWidget {
  const _TextbooksView();

  Color _colorForSubject(String subject) {
    switch (subject.toLowerCase()) {
      case 'mathematics':
        return AppColors.computerScience;
      case 'physics':
        return AppColors.levelPurple;
      case 'chemistry':
        return AppColors.success;
      case 'biology':
        return AppColors.biology;
      case 'history':
        return AppColors.warning;
      default:
        return AppColors.info;
    }
  }

  IconData _iconForSubject(String subject) {
    switch (subject.toLowerCase()) {
      case 'mathematics':
        return Icons.calculate_rounded;
      case 'physics':
        return Icons.science_rounded;
      case 'chemistry':
        return Icons.biotech_rounded;
      case 'biology':
        return Icons.eco_rounded;
      case 'history':
        return Icons.menu_book_rounded;
      default:
        return Icons.book_rounded;
    }
  }

  Future<void> _openTextbook(
    BuildContext context,
    TextbookModel textbook,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      const SnackBar(content: Text('Opening textbook...')),
    );

    try {
      final result = await sl<TextbookFileCacheService>().prepareLocalPdf(
        textbook,
      );
      if (!context.mounted) return;
      messenger.hideCurrentSnackBar();
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => TextbookViewerScreen(
            localPath: result.localPath,
            title: textbook.title,
            fromCache: result.fromCache,
          ),
        ),
      );
    } catch (_) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Unable to open textbook. Please try again.'),
        ),
      );
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
                ? const EmptyStateWidget(
                    illustration: BooksIllustration(),
                    icon: Icons.menu_book_rounded,
                    title: 'No textbooks available',
                    subtitle: 'Textbooks will appear here when added.',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.textbooks.length,
                    itemBuilder: (context, index) {
                      final textbook = state.textbooks[index];
                      final subjectColor = _colorForSubject(textbook.subject);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          onTap: () => _openTextbook(context, textbook),
                          borderRadius: AppRadius.borderMd,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                // Cover image or placeholder
                                Container(
                                  width: 60,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: subjectColor.withAlpha(20),
                                    borderRadius: AppRadius.borderSm,
                                  ),
                                  child: textbook.coverUrl != null
                                      ? ClipRRect(
                                          borderRadius: AppRadius.borderSm,
                                          child: Image.network(
                                            textbook.coverUrl!,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                                  return Icon(
                                                    _iconForSubject(
                                                      textbook.subject,
                                                    ),
                                                    color: subjectColor,
                                                    size: 32,
                                                  );
                                                },
                                          ),
                                        )
                                      : Icon(
                                          _iconForSubject(textbook.subject),
                                          color: subjectColor,
                                          size: 32,
                                        ),
                                ),
                                const SizedBox(width: 16),
                                // Textbook info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        textbook.title,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.category_rounded,
                                            size: 14,
                                            color: Colors.grey[600],
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            textbook.subject,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Icon(
                                            Icons.school_rounded,
                                            size: 14,
                                            color: Colors.grey[600],
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Grade ${textbook.grade}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (textbook.description != null) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          textbook.description!,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[500],
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.description_rounded,
                                            size: 12,
                                            color: Colors.grey[500],
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            textbook.fileSizeDisplay,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey[500],
                                            ),
                                          ),
                                          if (textbook.pageCount != null) ...[
                                            const SizedBox(width: 12),
                                            Icon(
                                              Icons.auto_stories_rounded,
                                              size: 12,
                                              color: Colors.grey[500],
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${textbook.pageCount} pages',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey[500],
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                // Open icon
                                Icon(
                                  Icons.open_in_new_rounded,
                                  color: subjectColor,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        );
      },
    );
  }
}
