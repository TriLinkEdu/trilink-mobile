import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trilink_mobile/core/widgets/empty_state_widget.dart';
import 'package:trilink_mobile/core/widgets/illustrations.dart';
import 'package:trilink_mobile/core/widgets/error_widget.dart';
import 'package:trilink_mobile/core/widgets/staggered_animation.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../../shared/widgets/student_page_background.dart';
import '../cubit/sync_cubit.dart';
import '../models/sync_status_model.dart';
import '../repositories/student_sync_repository.dart';

class StudentSyncStatusScreen extends StatelessWidget {
  const StudentSyncStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SyncCubit(sl<StudentSyncRepository>())..loadIfNeeded(),
      child: const _StudentSyncStatusView(),
    );
  }
}

class _StudentSyncStatusView extends StatefulWidget {
  const _StudentSyncStatusView();

  @override
  State<_StudentSyncStatusView> createState() => _StudentSyncStatusViewState();
}

class _StudentSyncStatusViewState extends State<_StudentSyncStatusView> {
  bool _isSyncing = false;

  Future<void> _triggerSync() async {
    setState(() => _isSyncing = true);
    final messenger = ScaffoldMessenger.of(context);
    final cubit = context.read<SyncCubit>();
    try {
      await cubit.triggerSync();
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Sync completed successfully.')),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Sync failed. Please try again.')),
      );
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  IconData _statusIcon(SyncItemStatus status) {
    return switch (status) {
      SyncItemStatus.synced => Icons.check_circle,
      SyncItemStatus.pending => Icons.sync_problem,
      SyncItemStatus.error => Icons.error_outline,
    };
  }

  Color _statusColor(SyncItemStatus status) {
    return switch (status) {
      SyncItemStatus.synced => AppColors.success,
      SyncItemStatus.pending => AppColors.warning,
      SyncItemStatus.error => AppColors.danger,
    };
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SyncCubit, SyncState>(
      builder: (context, state) {
        final isLoading =
            state.status == SyncStatus.loading ||
            state.status == SyncStatus.initial;
        final items = state.items;
        return Scaffold(
          appBar: AppBar(title: const Text('Sync Status')),
          body: StudentPageBackground(
            child: isLoading
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: ShimmerList(),
                  )
                : state.status == SyncStatus.error
                ? AppErrorWidget(
                    message:
                        state.errorMessage ?? 'Unable to load sync status.',
                    onRetry: () => context.read<SyncCubit>().loadSyncStatus(),
                  )
                : Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Offline Access & Sync',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        AppSpacing.gapLg,
                        Expanded(
                          child: items.isEmpty
                              ? const EmptyStateWidget(
                                  illustration: ClipboardIllustration(),
                                  icon: Icons.sync_rounded,
                                  title: 'No sync items',
                                  subtitle:
                                      'Your sync status will appear here.',
                                )
                              : ListView.separated(
                                  itemCount: items.length,
                                  separatorBuilder: (_, _) => AppSpacing.gapSm,
                                  itemBuilder: (context, index) {
                                    final item = items[index];
                                    return StaggeredFadeSlide(
                                      index: index,
                                      child: Card(
                                        child: ListTile(
                                          title: Text(item.category),
                                          subtitle: Text(
                                            '${item.description}\nLast synced: ${_formatTime(item.lastSyncedAt)}'
                                            '${item.pendingCount > 0 ? ' • ${item.pendingCount} pending' : ''}',
                                          ),
                                          isThreeLine: true,
                                          trailing: Icon(
                                            _statusIcon(item.status),
                                            color: _statusColor(item.status),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                        AppSpacing.gapLg,
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isSyncing ? null : _triggerSync,
                            icon: _isSyncing
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.sync),
                            label: Text(_isSyncing ? 'Syncing...' : 'Sync Now'),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        );
      },
    );
  }
}
