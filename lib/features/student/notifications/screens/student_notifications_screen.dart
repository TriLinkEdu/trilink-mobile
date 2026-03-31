import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../cubit/notifications_cubit.dart';
import '../models/notification_model.dart';
import '../repositories/student_notifications_repository.dart';
import '../widgets/notification_tile.dart';

class StudentNotificationsScreen extends StatelessWidget {
  const StudentNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => NotificationsCubit(sl<StudentNotificationsRepository>())
        ..loadNotifications(),
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
    await context.read<NotificationsCubit>().markNotificationRead(notification.id);

    if (!mounted) return;
    if (notification.routeName != null) {
      Navigator.of(context).pushNamed(
        notification.routeName!,
        arguments: notification.routeArgs,
      );
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
    final theme = Theme.of(context);

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
      body: BlocBuilder<NotificationsCubit, NotificationsState>(
        builder: (context, state) {
          final loading = state.status == NotificationsStatus.initial ||
              state.status == NotificationsStatus.loading;
          if (loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == NotificationsStatus.error) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    state.errorMessage ?? 'Unable to load notifications.',
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () =>
                        context.read<NotificationsCubit>().loadNotifications(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final visibleItems = _visibleItems(state.items);

          return Column(
            children: [
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    ChoiceChip(
                      label: const Text('All'),
                      selected: _filterIndex == 0,
                      onSelected: (_) =>
                          setState(() => _filterIndex = 0),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Unread'),
                      selected: _filterIndex == 1,
                      onSelected: (_) =>
                          setState(() => _filterIndex = 1),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: visibleItems.isEmpty
                    ? Center(
                        child: Text(
                          'No notifications in this view.',
                          style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      )
                    : ListView.separated(
                        itemCount: visibleItems.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final item = visibleItems[index];
                          return NotificationTile(
                            isRead: item.isRead,
                            title: item.title,
                            body: item.body,
                            time: _timeLabel(item.createdAt),
                            onTap: () => _onTapNotification(item),
                            onToggleRead: () => _onToggleRead(item),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
