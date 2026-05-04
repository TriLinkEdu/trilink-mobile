import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../cubit/download_progress_cubit.dart';
import '../models/download_progress_model.dart';

/// Enhanced download progress dialog with detailed feedback
class DownloadProgressDialog extends StatelessWidget {
  final String downloadId;
  final VoidCallback? onCancel;

  const DownloadProgressDialog({
    super.key,
    required this.downloadId,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DownloadProgressCubit, DownloadProgressState>(
      builder: (context, state) {
        final progress = state.getDownload(downloadId);
        if (progress == null) {
          return const SizedBox.shrink();
        }

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: _buildContent(context, progress),
          ),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, DownloadProgress progress) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Title and status icon
        Row(
          children: [
            _buildStatusIcon(progress),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    progress.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    _getStatusText(progress),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),

        // Progress bar with percentage
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: LinearProgressIndicator(
                value: progress.progressPercentage / 100,
                minHeight: 8,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  _getProgressColor(progress),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${progress.progressPercentage.toStringAsFixed(1)}%',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                Text(
                  progress.formattedProgress,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),

        // Download details grid
        if (progress.isDownloading) ...[
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: _buildDetailItem(
                    context,
                    icon: Icons.speed,
                    label: 'Speed',
                    value: progress.downloadSpeed,
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.grey[300],
                ),
                Expanded(
                  child: _buildDetailItem(
                    context,
                    icon: Icons.schedule,
                    label: 'Time Left',
                    value: progress.formattedEstimatedTime,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],

        // Actions
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (progress.isDownloading) ...[
              TextButton(
                onPressed: () {
                  context
                      .read<DownloadProgressCubit>()
                      .cancelDownload(downloadId);
                  onCancel?.call();
                  Navigator.pop(context);
                },
                child: const Text('Cancel'),
              ),
              const SizedBox(width: AppSpacing.sm),
            ] else if (progress.isFailed) ...[
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Dismiss'),
              ),
              const SizedBox(width: AppSpacing.sm),
            ] else ...[
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Done'),
              ),
              const SizedBox(width: AppSpacing.sm),
            ],
          ],
        ),

        // Error message if failed
        if (progress.isFailed) ...[
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Colors.red[50],
              border: Border.all(color: Colors.red[200]!),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Text(
              progress.errorMessage ?? 'Download failed. Please try again.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.red[700],
                  ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatusIcon(DownloadProgress progress) {
    late IconData icon;
    late Color color;

    switch (progress.status) {
      case DownloadStatus.downloading:
        icon = Icons.downloading;
        color = AppColors.primary;
        break;
      case DownloadStatus.completed:
        icon = Icons.check_circle;
        color = AppColors.success;
        break;
      case DownloadStatus.failed:
        icon = Icons.error;
        color = Colors.red;
        break;
      case DownloadStatus.cancelled:
        icon = Icons.cancel;
        color = Colors.grey;
        break;
      default:
        icon = Icons.file_download;
        color = AppColors.primary;
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }

  Widget _buildDetailItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Colors.grey[600],
              ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  String _getStatusText(DownloadProgress progress) {
    switch (progress.status) {
      case DownloadStatus.downloading:
        return 'Downloading...';
      case DownloadStatus.completed:
        return 'Download complete';
      case DownloadStatus.failed:
        return 'Download failed';
      case DownloadStatus.cancelled:
        return 'Download cancelled';
      default:
        return 'Starting...';
    }
  }

  Color _getProgressColor(DownloadProgress progress) {
    switch (progress.status) {
      case DownloadStatus.downloading:
        return AppColors.primary;
      case DownloadStatus.completed:
        return AppColors.success;
      case DownloadStatus.failed:
        return Colors.red;
      case DownloadStatus.cancelled:
        return Colors.grey;
      default:
        return AppColors.primary;
    }
  }
}

/// Show download progress dialog. Usage:
/// ```
/// showDownloadProgressDialog(
///   context,
///   downloadId: 'textbook_123',
///   onCancel: () { /* handle cancel */ },
/// );
/// ```
Future<T?> showDownloadProgressDialog<T>(
  BuildContext context, {
  required String downloadId,
  VoidCallback? onCancel,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: false,
    builder: (context) => DownloadProgressDialog(
      downloadId: downloadId,
      onCancel: onCancel,
    ),
  );
}
