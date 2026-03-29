import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../repositories/student_notifications_repository.dart';
import '../repositories/mock_student_notifications_repository.dart';
import '../widgets/notification_tile.dart';

class StudentNotificationsScreen extends StatefulWidget {
  final StudentNotificationsRepository? repository;

  const StudentNotificationsScreen({super.key, this.repository});

  @override
  State<StudentNotificationsScreen> createState() =>
      _StudentNotificationsScreenState();
}

class _StudentNotificationsScreenState
    extends State<StudentNotificationsScreen> {
  late final StudentNotificationsRepository _repository;
  int _filterIndex = 0;
  bool _isLoading = true;
  String? _error;
  List<NotificationModel> _items = [];

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? MockStudentNotificationsRepository();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final items = await _repository.fetchNotifications();
      if (!mounted) return;
      setState(() {
        _items = items;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Unable to load notifications.';
        _isLoading = false;
      });
    }
  }

  List<NotificationModel> get _visibleItems {
    if (_filterIndex == 1) {
      return _items.where((item) => !item.isRead).toList();
    }
    return _items;
  }

  Future<void> _markAllRead() async {
    await _repository.markAllAsRead();
    if (!mounted) return;
    setState(() {
      _items = _items.map((n) => n.copyWith(isRead: true)).toList();
    });
  }

  Future<void> _onTapNotification(NotificationModel notification) async {
    await _repository.markAsRead(notification.id);
    if (!mounted) return;
    setState(() {
      _items = _items.map((n) {
        if (n.id == notification.id) return n.copyWith(isRead: true);
        return n;
      }).toList();
    });

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
    if (!notification.isRead) {
      await _repository.markAsRead(notification.id);
    }
    if (!mounted) return;
    setState(() {
      _items = _items.map((n) {
        if (n.id == notification.id) {
          return n.copyWith(isRead: !notification.isRead);
        }
        return n;
      }).toList();
    });
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
    final visibleItems = _visibleItems;

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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!,
                          style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: _loadNotifications,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Column(
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
                          ? const Center(
                              child: Text(
                                'No notifications in this view.',
                                style: TextStyle(color: Colors.grey),
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
                ),
    );
  }
}
