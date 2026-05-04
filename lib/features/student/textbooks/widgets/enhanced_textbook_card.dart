import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../models/textbook_model.dart';

class EnhancedTextbookCard extends StatelessWidget {
  final TextbookModel textbook;
  final Color subjectColor;
  final IconData subjectIcon;
  final VoidCallback onTap;
  final bool isLoading;

  const EnhancedTextbookCard({
    super.key,
    required this.textbook,
    required this.subjectColor,
    required this.subjectIcon,
    required this.onTap,
    this.isLoading = false,
  });

  /// Format bytes to human-readable format
  static String _formatBytes(int? bytes) {
    if (bytes == null || bytes <= 0) return 'Unknown';
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    final index = (bytes.toString().length - 1) ~/ 3;
    final value = bytes / (1000 * (1 << (index * 10)));
    return '${value.toStringAsFixed(1)} ${suffixes[index]}';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      elevation: 2,
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: AppRadius.borderMd,
        child: Column(
          children: [
            // Header with cover and title
            _buildHeader(context),
            // Metadata and info
            _buildMetadata(context),
            // Footer with action
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: subjectColor.withAlpha(10),
        border: Border(
          bottom: BorderSide(
            color: subjectColor.withAlpha(50),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Cover image or placeholder
          Container(
            width: 70,
            height: 90,
            decoration: BoxDecoration(
              color: subjectColor.withAlpha(30),
              borderRadius: AppRadius.borderMd,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(10),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: textbook.coverUrl != null
                ? ClipRRect(
                    borderRadius: AppRadius.borderMd,
                    child: Image.network(
                      textbook.coverUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          subjectIcon,
                          color: subjectColor,
                          size: 36,
                        );
                      },
                    ),
                  )
                : Icon(
                    subjectIcon,
                    color: subjectColor,
                    size: 36,
                  ),
          ),
          const SizedBox(width: AppSpacing.lg),
          // Title and subject
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  textbook.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: subjectColor.withAlpha(40),
                    borderRadius: BorderRadius.circular(AppRadius.xs),
                  ),
                  child: Text(
                    textbook.subject,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: subjectColor,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetadata(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Description if available
          if (textbook.description != null) ...[
            Text(
              textbook.description!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[700],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          // Metadata chips row
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              // Grade chip
              _buildMetadataChip(
                context,
                icon: Icons.school_rounded,
                label: 'Grade ${textbook.grade}',
              ),

              // File size chip
              _buildMetadataChip(
                context,
                icon: Icons.file_present_rounded,
                label: _formatBytes(textbook.sizeBytes),
              ),

              // Page count chip (if available)
              if ((textbook.pageCount ?? 0) > 0)
                _buildMetadataChip(
                  context,
                  icon: Icons.description_rounded,
                  label: '${textbook.pageCount ?? 0} pages',
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataChip(
    BuildContext context, {
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(
          color: Colors.grey[300]!,
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.grey[700],
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Open to read',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          Icon(
            Icons.arrow_forward_rounded,
            size: 18,
            color: AppColors.primary,
          ),
        ],
      ),
    );
  }
}
