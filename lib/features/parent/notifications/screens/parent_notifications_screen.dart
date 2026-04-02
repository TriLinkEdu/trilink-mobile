import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/api_service.dart';

class ParentNotificationsScreen extends StatefulWidget {
  const ParentNotificationsScreen({super.key});

  @override
  State<ParentNotificationsScreen> createState() =>
      _ParentNotificationsScreenState();
}

class _ParentNotificationsScreenState extends State<ParentNotificationsScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() { _loading = true; _error = null; });
      final data = await ApiService().getNotifications();
      if (!mounted) return;
      setState(() {
        _notifications = data.cast<Map<String, dynamic>>();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _markAsRead(String id) async {
    try {
      await ApiService().markNotificationRead(id);
      if (!mounted) return;
      setState(() {
        final idx = _notifications.indexWhere((n) => n['id'] == id);
        if (idx >= 0) _notifications[idx]['read'] = true;
      });
    } catch (_) {}
  }

  Future<void> _markAllRead() async {
    try {
      await ApiService().markAllNotificationsRead();
      if (!mounted) return;
      setState(() {
        for (final n in _notifications) {
          n['read'] = true;
        }
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (_notifications.any((n) => n['read'] != true))
            TextButton(
              onPressed: _markAllRead,
              child: const Text('Mark all read',
                  style: TextStyle(color: AppColors.primary)),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!,
                          style: const TextStyle(color: AppColors.error)),
                      const SizedBox(height: 12),
                      ElevatedButton(
                          onPressed: _loadData,
                          child: const Text('Retry')),
                    ],
                  ),
                )
              : _notifications.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.notifications_none,
                              size: 56, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(
                            'No notifications yet',
                            style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "You'll be notified about your child's updates here.",
                            style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadData,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _notifications.length,
                        separatorBuilder: (_, __) =>
                            Divider(color: Colors.grey.shade200),
                        itemBuilder: (context, index) {
                          final n = _notifications[index];
                          final isRead = n['read'] as bool? ?? false;
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isRead
                                  ? Colors.grey.shade200
                                  : AppColors.primary.withValues(alpha: 0.1),
                              child: Icon(
                                _getNotificationIcon(
                                    n['type'] as String? ?? ''),
                                color: isRead
                                    ? Colors.grey.shade500
                                    : AppColors.primary,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              n['title'] as String? ?? '',
                              style: TextStyle(
                                fontWeight: isRead
                                    ? FontWeight.w400
                                    : FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  n['body'] as String? ??
                                      n['message'] as String? ??
                                      '',
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade600),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  n['createdAt'] as String? ??
                                      n['time'] as String? ??
                                      '',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade500),
                                ),
                              ],
                            ),
                            onTap: () {
                              if (!isRead) {
                                _markAsRead(n['id'] as String? ?? '');
                              }
                            },
                          );
                        },
                      ),
                    ),
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'attendance':
        return Icons.event_available;
      case 'grade':
      case 'exam':
        return Icons.grade;
      case 'announcement':
        return Icons.campaign;
      case 'message':
        return Icons.chat;
      default:
        return Icons.notifications;
    }
  }
}
