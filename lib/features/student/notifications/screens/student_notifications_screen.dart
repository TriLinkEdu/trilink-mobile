import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trilink_mobile/core/widgets/branded_refresh.dart';
import 'package:trilink_mobile/core/widgets/empty_state_widget.dart';
import 'package:trilink_mobile/core/widgets/illustrations.dart';
import 'package:trilink_mobile/core/widgets/error_widget.dart';
import 'package:trilink_mobile/core/widgets/staggered_animation.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../../shared/widgets/student_page_background.dart';
import '../cubit/notifications_cubit.dart';
import '../models/notification_model.dart';
import '../repositories/student_notifications_repository.dart';
import '../widgets/notification_tile.dart';

class StudentNotificationsScreen extends StatelessWidget {
  const StudentNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          NotificationsCubit(sl<StudentNotificationsRepository>())
            ..loadIfNeeded(),
      child: const _NotificationsView(),
    );
  }
}

class _NotificationsView extends StatefulWidget {
  const _NotificationsView();

  @override
  State<_NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<_NotificationsView> {
  int _filterIndex = 0;

  List<NotificationModel> _visibleItems(List<NotificationModel> items) {
    if (_filterIndex == 1) {
      return items.where((item) => !item.isRead).toList();
    }
    return items;
  }

  Future<void> _markAllRead() async {
    await context.read<NotificationsCubit>().markAllAsRead();
  }

  Future<void> _onTapNotification(NotificationModel notification) async {
    await context.read<NotificationsCubit>().markNotificationRead(
      notification.id,
    );

    if (!mounted) return;
    if (notification.routeName != null) {
      Navigator.of(
        context,
      ).pushNamed(notification.routeName!, arguments: notification.routeArgs);
    } else {
      showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(notification.title),
          content: Text(notification.body),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _onToggleRead(NotificationModel notification) async {
    await context.read<NotificationsCubit>().toggleRead(notification);
  }

  String _timeLabel(DateTime createdAt) {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: _markAllRead,
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: StudentPageBackground(
        child: BlocBuilder<NotificationsCubit, NotificationsState>(
          builder: (context, state) {
            final loading =
                state.status == NotificationsStatus.initial ||
                state.status == NotificationsStatus.loading;
            if (loading) {
              return const Padding(
                padding: AppSpacing.paddingLg,
                child: ShimmerList(),
              );
            }
            if (state.status == NotificationsStatus.error) {
              return AppErrorWidget(
                message: state.errorMessage ?? 'Unable to load notifications.',
                onRetry: () =>
                    context.read<NotificationsCubit>().loadNotifications(),
              );
            }

            final visibleItems = _visibleItems(state.items);

            return Column(
              children: [
                AppSpacing.gapMd,
                Padding(
                  padding: AppSpacing.horizontalLg,
                  child: Row(
                    children: [
                      ChoiceChip(
                        label: const Text('All'),
                        selected: _filterIndex == 0,
                        showCheckmark: false,
                        selectedColor: Theme.of(
                          context,
                        ).colorScheme.primaryContainer.withAlpha(160),
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerLow,
                        onSelected: (_) => setState(() => _filterIndex = 0),
                      ),
                      AppSpacing.hGapSm,
                      ChoiceChip(
                        label: const Text('Unread'),
                        selected: _filterIndex == 1,
                        showCheckmark: false,
                        selectedColor: Theme.of(
                          context,
                        ).colorScheme.primaryContainer.withAlpha(160),
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerLow,
                        onSelected: (_) => setState(() => _filterIndex = 1),
                      ),
                    ],
                  ),
                ),
                AppSpacing.gapSm,
                Expanded(
                  child: BrandedRefreshIndicator(
                    onRefresh: () =>
                        context.read<NotificationsCubit>().loadNotifications(),
                    child: visibleItems.isEmpty
                        ? LayoutBuilder(
                            builder: (context, constraints) {
                              return SingleChildScrollView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    minHeight: constraints.maxHeight,
                                  ),
                                  child: EmptyStateWidget(
                                    illustration: const EmptyBoxIllustration(),
                                    icon: Icons.notifications_none_rounded,
                                    title: _filterIndex == 1
                                        ? 'No unread notifications'
                                        : 'No notifications',
                                    subtitle: _filterIndex == 1
                                        ? 'All caught up   nothing new!'
                                        : 'You are all caught up!',
                                    actionLabel: _filterIndex == 1 ? 'Show All' : null,
                                    onAction: _filterIndex == 1 ? () {
                                      setState(() {
                                        _filterIndex = 0;
                                      });
                                    } : null,
                                  ),
                                ),
                              );
                            },
                          )
                        : ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: visibleItems.length,
                            separatorBuilder: (_, _) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final item = visibleItems[index];
                              return StaggeredFadeSlide(
                                index: index,
                                child: NotificationTile(
                                  isRead: item.isRead,
                                  title: item.title,
                                  body: item.body,
                                  time: _timeLabel(item.createdAt),
                                  onTap: () => _onTapNotification(item),
                                  onToggleRead: () => _onToggleRead(item),
                                ),
                              );
                            },
                          ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
